--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local author = {}

local mattata = require('mattata')

function author:init(configuration)
    author.arguments = 'author'
    author.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('author').table
    author.help = configuration.command_prefix .. 'author - Returns the numerical ID of the author of the replied-to sticker pack.'
end

function author:on_message(message, configuration)
    if not message.reply_to_message then
        return mattata.send_reply(
            message,
            author.help
        )
    elseif not message.reply_to_message.sticker then
        return mattata.send_reply(
            message,
            'The replied-to message must be a sticker!'
        )
    end
    local success = mattata.get_chat_by_file(message.reply_to_message.sticker.file_id)
    if not success then
        return mattata.send_reply(
            message,
            'That sticker doesn\'t appear to be part of a valid sticker pack! That is, one which was created using @stickers.'
        )
    elseif not success.result.user_id then
        return mattata.send_reply(
            message,
            'I couldn\'t get information about the author of that sticker pack'
        )
    end
    return mattata.send_reply(
        message.reply_to_message,
        'The author of this sticker pack has the ID ' .. success.result.user_id .. '! Use \'' .. configuration.command_prefix .. 'id ' .. success.result.user_id .. '\' to view more information about this user. <i>If information isn\'t correct then please contact @danogentili, as the IDs are resolved using the PWRTelegram API!</i>',
        'html'
    )
end

return author