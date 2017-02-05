--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local faces = {}

local mattata = require('mattata')

function faces:init(configuration)
    faces.command = 'faces'
    faces.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('faces').table
    faces.help = '<b>Faces:</b>\n'
    for k, v in pairs(configuration.faces) do
        faces.help = faces.help .. '• ' .. configuration.command_prefix .. k .. ': ' .. v .. '\n'
        table.insert(
            faces.commands,
            '^' .. configuration.command_prefix .. k
        )
        table.insert(
            faces.commands,
            '^' .. configuration.command_prefix .. k .. '@' .. self.info.username
        )
        table.insert(
            faces.commands,
            configuration.command_prefix .. k .. '$'
        )
        table.insert(
            faces.commands,
            configuration.command_prefix .. k .. '@' .. self.info.username .. '$'
        )
        table.insert(
            faces.commands,
            '\n' .. configuration.command_prefix .. k
        )
        table.insert(
            faces.commands,
            '\n' .. configuration.command_prefix .. k .. '@' .. self.info.username
        )
        table.insert(
            faces.commands,
            configuration.command_prefix .. k .. '\n'
        )
        table.insert(
            faces.commands,
            configuration.command_prefix .. k .. '@' .. self.info.username .. '\n'
        )
    end
end

function faces:on_message(message, configuration)
    if message.text_lower:match('^' .. configuration.command_prefix .. 'faces') then
        return mattata.send_reply(
            message,
            faces.help,
            'html'
        )
    end
    for k, v in pairs(configuration.faces) do
        if message.text_lower == configuration.command_prefix .. k or message.text_lower:match(' ' .. configuration.command_prefix .. k) or message.text_lower:match(configuration.command_prefix .. k .. ' ') then
            return mattata.send_message(
                message.chat.id,
                v,
                'html'
            )
        end
    end
end

return faces