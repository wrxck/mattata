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
    ipsw.help = [[/ipsw <device> [version] - Sends the download link for the given device's IPSW for the given version. The device should be the identifier or the boardconfig (e.g. iPhone4,1 or n94ap), and the version should be the build ID of the IPSW (e.g. 13G36). If no version is given, the latest version is used instead.]]
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

function ipsw:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            ipsw.help
        )
    end
    local jdat = ipsw.get_info(input)
    if not jdat then
        return mattata.send_reply(
            message,
            configuration.errors.results
        )
    end
    return mattata.send_message(
        message.chat.id,
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
        false,
        nil,
        mattata.inline_keyboard():row(
            mattata.row():url_button(
                jdat[1].filename,
                jdat[1].url
            )
        )
    )
end

return ipsw