--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local addsticker = {}
local mattata = require('mattata')
local http = require('socket.http')
local ltn12 = require('ltn12')
local mime = require('mime')
local json = require('dkjson')
local redis = require('libs.redis')

function addsticker:init()
    addsticker.commands = mattata.commands(self.info.username):command('addsticker'):command('getsticker').table
    addsticker.help = '/addsticker [pack name] - Converts the replied-to photo into a sticker and adds it to your pack. Specify a name for the pack via command input on first use, this cannot be changed after, until you\'ve hit 120 stickers and it makes a new set, or you\'ve deleted your pack in @stickers. Use /getsticker to get the uncompressed file to send to @stickers.'
end

function addsticker.delete_file(file)
    os.execute('rm ' .. file .. ' && rm output.png')
    return true
end

function addsticker:on_message(message, configuration, language)
    local is_sticker, is_text
    local input = mattata.input(message.text)
    if not message.reply then
        return mattata.send_reply(message, 'You must use this command in reply to a photo!')
    elseif not message.reply.is_media and message.reply.text then
        local sizes
        local reply = {}
        local success = mattata.get_user_profile_photos(message.reply.from.id)
        if success and success.result.total_count > 0 then
            sizes = {
                ['small_file_id'] = success.result.photos[1][1].file_id,
                ['small_file_unique_id'] = success.result.photos[1][1].file_unique_id,
                ['big_file_id'] = success.result.photos[1][#success.result.photos[1]].file_id,
                ['big_file_unique_id'] = success.result.photos[1][#success.result.photos[1]].file_unique_id
            }
        end
        if message.reply.reply then -- Check the context object for a reply to a reply.
            local reply_original_name = message.reply.reply.from.has_nickname and message.reply.reply.from.original_name or message.reply.reply.from.name
            reply =  {
                ['chatId'] = message.chat.id,
                ['from'] = {
                    ['id'] = message.reply.reply.from.id,
                    ['name'] = reply_original_name
                },
                ['text'] = message.reply.reply.text
            }
        end
        local original_name = message.reply.from.has_nickname and message.reply.from.original_name or message.reply.from.name
        if (message.reply.text:match('^[\216-\219][\128-\191]') or message.reply.text:match('^' .. utf8.char(0x202e)) or message.reply.text:match('^' .. utf8.char(0x200f))) then
            message.reply.text = mattata.split_string(message.reply.text, true)
            message.reply.text = table.concat(message.reply.text, ' ')
        end
        local payload = {
            ['type'] = 'quote',
            ['backgroundColor'] = '#243447',
            ['width'] = 512,
            ['height'] = 512,
            ['scale'] = 2,
            ['messages'] = {
                {
                    ['message'] = {
                        ['chatId'] = message.chat.id,
                        ['avatar'] = true,
                        ['from'] = {
                            ['id'] = message.reply.from.id,
                            ['name'] = original_name
                        },
                        ['text'] = message.reply.text
                    },
                    ['replyMessage'] = reply,
                    ['entities'] = {}
                }
            }
        }
        if type(sizes) == 'table' then
            payload.messages[1].message.from.photo = sizes
        end
        if message.reply.from.username then
            payload.messages[1].message.from.username = message.reply.from.username
        end
        if message.reply.entities then
            payload.messages[1].entities = message.reply.entities
        end
        payload = json.encode(payload) -- Serialise the payload.
        local response = {}
        local old_timeout = http.TIMEOUT
        http.TIMEOUT = 3
        local _, res = http.request({
            ['url'] = 'http://localhost:3000/generate',
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'application/json',
                ['Content-Length'] = payload:len()
            },
            ['source'] = ltn12.source.string(payload),
            ['sink'] = ltn12.sink.table(response)
        })
        http.TIMEOUT = old_timeout
        if res ~= 200 then
            return false
        end
        response = table.concat(response)
        local jdat = json.decode(response)
        local output = configuration.bot_directory .. '/output.webp'
        ltn12.pump.all(
            ltn12.source.string(jdat.result.image),
            ltn12.sink.chain(
                mime.decode('base64'),
                ltn12.sink.file(io.open(output, 'w'))
            )
        )
        is_text = true
    elseif message.reply.sticker then
        if message.reply.sticker.is_animated then
            return mattata.send_reply(message, 'I\'m afraid animated stickers aren\'t supported at the moment.')
        end
        is_sticker = true
    elseif not message.reply.photo and not message.reply.document then
        local success = mattata.get_user_profile_photos(message.reply.from.id)
        if not success or success.result.total_count == 0 then
            return mattata.send_reply(message, 'This user doesn\'t allow me to see their profile picture. You must use this command in reply to a photo!')
        end
        message.reply.file_id = success.result.photos[1][#success.result.photos[1]].file_id
    elseif message.reply.document then
        if (message.reply.document.mime_type ~= 'image/jpeg' and message.reply.document.mime_type ~= 'image/png') or not message.reply.document.file_name:match('%.[JjPp][PpNn][Ee]?[Gg]$') then
            return mattata.send_reply(message, 'The file must be JPEG or a PNG image.')
        elseif message.reply.document.file_size > 1048576 then
            return mattata.send_reply(message, 'Please send a photo that is 1MB or smaller in file size!')
        end
    end
    local file, file_name
    if not is_text and message.reply.is_media then
        file = mattata.get_file(message.reply.file_id)
        if not file then
            return mattata.send_reply(message, language.errors.generic)
        end
        file_name = file.result.file_path
        local file_path = string.format('https://api.telegram.org/file/bot%s/%s', configuration.bot_token, file_name)
        file = mattata.download_file(file_path, file_name:match('/(.-)$'), configuration.bot_directory)
        if not file then
            return false
        end
        file_name = file_name:match('/(.-)$')
    else
        file_name = 'output.webp'
        file = configuration.bot_directory .. '/output.webp'
    end
    local command = is_sticker and string.format('dwebp %s -o output.png', file_name) or string.format('convert ' .. file_name .. ' -resize 512x512 output.png', file)
    os.execute(command)
    local output_file = configuration.bot_directory .. '/output.png'
    if message.text:match('^[/!#]getsticker') then
        mattata.send_document(message.chat.id, output_file)
        return addsticker.delete_file(file)
    end
    local set_name = string.format('U%s_by_%s', message.from.id, self.info.username:lower())
    local set_title = message.from.original_name or message.from.first_name
    local exists = mattata.get_sticker_set(set_name)
    if exists then
        if #exists.result.stickers == 120 then -- Maximum amount of stickers allowed per-pack.
            local amount = exists.result.name:match('^U%d+_(%d*)')
            local new = (amount and tonumber(amount) or 1) + 1
            set_name = string.format('U%s_%s_by_%s', message.from.id, new, self.info.username:lower())
            amount = redis:hget('user:' .. message.from.id .. ':info', 'sticker_packs') or 1
            amount = math.floor(tonumber(amount)) + 1
            redis:hset('user:' .. message.from.id .. ':info', 'sticker_packs', amount)
        else
            local success = mattata.add_sticker_to_set(message.from.id, set_name, output_file, utf8.char(128045))
            addsticker.delete_file(file)
            if not success then
                return mattata.send_reply(message, language.errors.generic)
            end
            return mattata.send_reply(message, 'I\'ve added that to [your pack](https://t.me/addstickers/' .. set_name .. ')!', true, true)
        end
    end
    if input then
        if input:len() > 64 then
            addsticker.delete_file(file)
            return mattata.send_reply(message, 'The sticker pack title cannot be longer than 64 characters in length!')
        end
        set_title = input
    end
    local success = mattata.create_new_sticker_set(message.from.id, set_name, set_title, output_file, utf8.char(128045))
    addsticker.delete_file(file)
    if not success then
        return mattata.send_reply(message, language.errors.generic)
    end
    return mattata.send_reply(message, 'I\'ve created you a pack called _' .. mattata.escape_markdown(set_title) .. '_ and added that sticker to [your new pack](https://t.me/addstickers/' .. set_name .. ')!', true, true)
end

return addsticker