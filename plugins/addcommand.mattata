--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local addcommand = {}
local mattata = require('mattata')

function addcommand:init()
    addcommand.commands = mattata.commands(self.info.username):command('addcommand').table
end

function addcommand.on_message(_, message, _, language)
    if not mattata.is_global_admin(message.from.id) then
        return false
    end
    local input = mattata.input(message.text)
    if not input or not input:match('^[/!#]?[%w_]+ %- .-$') then
        return mattata.send_reply(message, language['addcommand']['1'], 'html')
    end
    local commands = mattata.get_my_commands()
    if not commands then
        return mattata.send_reply(message, language['addcommand']['2'])
    end
    commands = type(commands.result) == 'table' and commands.result or {}
    local command, description = input:match('^/?([%w_]+) %- (.-)$')
    if description:len() > 256 then
        return mattata.send_reply(message, language['addcommand']['3'])
    end
    commands = table.insert(commands, { ['command'] = command, ['description'] = description })
    local success = mattata.set_my_commands(commands)
    if not success then
        return mattata.send_reply(message, language['addcommand']['4'])
    end
    return mattata.send_reply(message, language['addcommand']['5'])
end

return addcommand