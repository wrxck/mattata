--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local ipsw = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function ipsw:init()
    ipsw.commands = mattata.commands(
        self.info.username
    ):command('ipsw').table
    ipsw.help = [[/ipsw - Allows you to select the firmware information for your device and firmware version.]]
    ipsw.data = {}
    local jstr, res = https.request('https://api.ipsw.me/v2.1/firmwares.json')
    if res == 200 then
        ipsw.data = json.decode(jstr)
    end
    ipsw.devices = {}
    for k, v in pairs(ipsw.data.devices) do
        if k:lower():match('^appletv') then
            if not ipsw.devices['Apple TV'] then
                ipsw.devices['Apple TV'] = {}
            end
            table.insert(ipsw.devices['Apple TV'], k)
        elseif k:lower():match('^ipad') then
            if not ipsw.devices['iPad'] then
                ipsw.devices['iPad'] = {}
            end
            table.insert(ipsw.devices['iPad'], k)
        elseif k:lower():match('^ipod') then
            if not ipsw.devices['iPod'] then
                ipsw.devices['iPod'] = {}
            end
            table.insert(ipsw.devices['iPod'], k)
        elseif k:lower():match('^iphone') then
            if not ipsw.devices['iPhone'] then
                ipsw.devices['iPhone'] = {}
            end
            table.insert(ipsw.devices['iPhone'], k)
        end
    end
end

function ipsw.get_info(input)
    local device = input
    local version = 'latest'
    if input:match('^.- .-$') then
        device = input:match('^(.-) ')
        version = input:match(' (.-)$')
    end
    local jstr, res = https.request(
        string.format(
            'https://api.ipsw.me/v2.1/%s/%s/info.json',
            url.escape(device),
            url.escape(version)
        )
    )
    if res ~= 200 or jstr == '[]' then
        return false
    end
    return json.decode(jstr)
end

function ipsw:on_inline_query(inline_query)
    local input = mattata.input(inline_query.query)
    if not input then
        return
    end
    local jdat = ipsw.get_info(input)
    if not jdat then
        return
    end
    return mattata.answer_inline_query(
        inline_query.id,
        mattata.inline_result():type('article'):id(1):title(jdat[1].device):description('iOS ' .. jdat[1].version):input_message_content(
            mattata.input_text_message_content(
                string.format(
                    '<b>%s</b> iOS %s\n\n<code>MD5 sum: %s\nSHA1 sum: %s\nFile size: %s GB</code>\n\n<i>%s This firmware is %s being signed!</i>',
                    jdat[1].device,
                    jdat[1].version,
                    jdat[1].md5sum,
                    jdat[1].sha1sum,
                    mattata.round(
                        jdat[1].size / 1000000000,
                        2
                    ),
                    jdat[1].signed == false and utf8.char(10060) or utf8.char(9989),
                    jdat[1].signed == false and 'no longer' or 'still'
                ),
                'html'
            )
        ):reply_markup(
            mattata.inline_keyboard():row(
                mattata.row():url_button(
                    jdat[1].filename,
                    jdat[1].url
                )
            )
        )
    )
end

function ipsw.get_model_keyboard(device)
    local keyboard = {
        ['inline_keyboard'] = {
            {}
        }
    }
    local total = 0
    for _, v in pairs(ipsw.devices[device]) do
        total = total + 1
    end
    local count = 0
    local rows = math.floor(total / 10)
    if rows ~= total then
        rows = rows + 1
    end
    local row = 1
    for k, v in pairs(ipsw.data.devices) do
        if k:lower():match(
            device:lower():gsub(' ', '')
        ) then
            count = count + 1
            if count == rows * row then
                row = row + 1
                table.insert(
                    keyboard.inline_keyboard,
                    {}
                )
            end
            table.insert(
                keyboard.inline_keyboard[row],
                {
                    ['text'] = v.name,
                    ['callback_data'] = 'ipsw:model:' .. k
                }
            )
        end
    end
    return keyboard
end

function ipsw.get_firmware_keyboard(model)
    local keyboard = {
        ['inline_keyboard'] = {
            {}
        }
    }
    local total = 0
    for _, v in pairs(ipsw.data.devices[model].firmwares) do
        total = total + 1
    end
    local count = 0
    local rows = math.floor(total / 7)
    if rows ~= total then
        rows = rows + 1
    end
    local row = 1
    for k, v in pairs(ipsw.data.devices[model].firmwares) do
        count = count + 1
        if count == rows * row then
            row = row + 1
            table.insert(
                keyboard.inline_keyboard,
                {}
            )
        end
        table.insert(
            keyboard.inline_keyboard[row],
            {
                ['text'] = v.version,
                ['callback_data'] = 'ipsw:firmware:' .. model .. ' ' .. v.buildid
            }
        )
    end
    return keyboard
end

function ipsw:on_callback_query(callback_query, message, configuration)
    if callback_query.data:match('^device%:') then
        callback_query.data = callback_query.data:match('^device%:(.-)$')
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'Please select your model:',
            nil,
            true,
            ipsw.get_model_keyboard(callback_query.data)
        )
    elseif callback_query.data:match('^model%:') then
        callback_query.data = callback_query.data:match('^model%:(.-)$')
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'Please select your firmware version:',
            nil,
            true,
            ipsw.get_firmware_keyboard(callback_query.data)
        )
    elseif callback_query.data:match('^firmware%:') then
        local jdat = ipsw.get_info(
            callback_query.data:match('^firmware%:(.-)$')
        )
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            string.format(
                '<b>%s</b> iOS %s\n\n<code>MD5 sum: %s\nSHA1 sum: %s\nFile size: %s GB</code>\n\n<i>%s This firmware is %s being signed!</i>',
                jdat[1].device,
                jdat[1].version,
                jdat[1].md5sum,
                jdat[1].sha1sum,
                mattata.round(
                    jdat[1].size / 1000000000,
                    2
                ),
                jdat[1].signed == false and utf8.char(10060) or utf8.char(9989),
                jdat[1].signed == false and 'no longer' or 'still'
            ),
            'html',
            true,
            mattata.inline_keyboard():row(
                mattata.row():url_button(
                    jdat[1].filename,
                    jdat[1].url
                )
            )
        )
    end
end

function ipsw:on_message(message, configuration)
    ipsw.init(self)
    return mattata.send_message(
        message.chat.id,
        'Please select your device type:',
        nil,
        true,
        false,
        nil,
        mattata.inline_keyboard():row(
            mattata.row():callback_data_button(
                'iPod Touch',
                'ipsw:device:iPod'
            ):callback_data_button(
                'iPhone',
                'ipsw:device:iPhone'
            )
        ):row(
            mattata.row():callback_data_button(
                'iPad',
                'ipsw:device:iPad'
            ):callback_data_button(
                'Apple TV',
                'ipsw:device:Apple TV'
            )
        )
    )
end

return ipsw