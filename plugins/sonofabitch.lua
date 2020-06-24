--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local sonofabitch = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function sonofabitch:init()
    sonofabitch.commands = mattata.commands(self.info.username, { '^[Ss][Oo][Nn] [Oo][Ff] [Aa] [Bb][Ii][Tt][Cc][Hh]$'}):command('sonofabitch').table
    sonofabitch.help = '/sonofabitch - Gracefully creates a clickbait ad using the replied-to person\'s photo.'
end

function sonofabitch:on_inline_query(inline_query, configuration, language)
    local input = mattata.input(inline_query.query) or inline_query.from.id
    local success = true
    if tonumber(input) == nil then
        input = mattata.get_user(input)
        if not input then
            success = false
            input = inline_query.from.id
        else
            input = input.result.id
        end
    end
    local output = redis:get('sonofabitch:' .. input)
    if not output then
        if success then
            success = mattata.get_user_profile_photos(input)
        end
        if not success or success.result.total_count == 0 then
            return mattata.send_inline_article(inline_query.id, language.errors.generic, 'That user doesn\'t have a profile picture, or I just don\'t have permission to see it!')
        end
        local file_id = success.result.photos[1][#success.result.photos[1]].file_id
        local file = mattata.get_file(file_id)
        if not file then
            return false
        end
        local file_name = file.result.file_path
        local file_path = string.format('https://api.telegram.org/file/bot%s/%s', configuration.bot_token, file_name)
        file = mattata.download_file(file_path, file_name:match('/(.-)$'), configuration.bot_directory)
        if not file then
            return false
        end
        local command = string.format('convert soab.png %s -gravity northwest -geometry +100+250 -composite output.png', file)
        os.execute(command)
        local validate = mattata.send_photo(configuration.log_chat, configuration.bot_directory .. '/output.png')
        if not validate then
            return false
        end
        mattata.delete_message(configuration.log_chat, validate.result.message_id)
        output = validate.result.photo[#validate.result.photo].file_id
        redis:set('sonofabitch:' .. input, output)
        redis:expire('sonofabitch:' .. input, 86400)
        os.execute('rm ' .. file .. ' && rm output.png')
    end
    return mattata.send_inline_cached_photo(inline_query.id, output)
end

function sonofabitch.on_message(_, message, configuration)
    if not message.reply then
        return false
    end
    local exists = redis:get('sonofabitch:' .. message.reply.from.id)
    if exists then
        return mattata.send_photo(message.chat.id, exists)
    end
    local success = mattata.get_user_profile_photos(message.reply.from.id)
    if not success or success.result.total_count == 0 then
        return mattata.send_reply(message, 'That user doesn\'t have a profile picture, or I just don\'t have permission to see it!')
    end
    local file_id = success.result.photos[1][#success.result.photos[1]].file_id
    local file = mattata.get_file(file_id)
    if not file then
        return false
    end
    local file_name = file.result.file_path
    local file_path = string.format('https://api.telegram.org/file/bot%s/%s', configuration.bot_token, file_name)
    file = mattata.download_file(file_path, file_name:match('/(.-)$'), '/home/matt/matticatebot')
    if not file then
        return false
    end
    local command = string.format('convert soab.png %s -gravity northwest -geometry +100+250 -composite output.png', file)
    os.execute(command)
    local success = mattata.send_photo(message.chat.id, configuration.bot_directory .. '/output.png')
    if not success then
        return false
    end
    redis:set('sonofabitch:' .. message.reply.from.id, success.result.photo[#success.result.photo].file_id)
    redis:expire('sonofabitch:' .. message.reply.from.id, 86400)
    os.execute('rm ' .. file .. ' && rm output.png')
    return success
end

return sonofabitch