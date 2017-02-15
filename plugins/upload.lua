--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local upload = {}

local mattata = require('mattata')

function upload:init()
    upload.commands = mattata.commands(
        self.info.username
    ):command('upload').table
end

function upload:on_message(message, configuration)
    if not mattata.is_global_admin(message.from.id) then
        return
    elseif not message.reply_to_message or not message.reply_to_message.document then
        return mattata.send_reply(
            message,
            'Please reply to the file you\'d like to download to the server. It must be <= 20 MB.'
        )
    elseif tonumber(message.reply_to_message.document.file_size) > 20971520 then
        return mattata.send_reply(
            message,
            'That file is too large. It must be <= 20 MB.'
        )
    end
    local file = mattata.get_file(message.reply_to_message.document.file_id)
    if not file then
        return mattata.send_reply(
            message,
            'I couldn\'t get this file, it\'s probably too old.'
        )
    end
    local success = mattata.download_file(
        'https://api.telegram.org/file/bot' .. configuration.bot_token .. '/' .. file.result.file_path:gsub('//', '/'):gsub('/$', ''),
        message.reply_to_message.document.file_name
    )
    if not success then
        return mattata.send_reply(
            message,
            'There was an error whilst retrieving this file.'
        )
    end
    return mattata.send_reply(
        message,
        'Successfully downloaded the file to the server - it can be found at <code>' .. mattata.escape_html(configuration.download_location .. message.reply_to_message.document.file_name) .. '</code>!',
        'html'
    )
end

return upload