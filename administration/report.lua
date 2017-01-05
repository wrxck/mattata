--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local report = {}

local mattata = require('mattata')

function report:init(configuration)
    report.arguments = 'report <text>'
    report.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('report'):command('ops').table
    report.help = configuration.command_prefix .. 'report <text> - Notifies all administrators of an issue. Alias: ' .. configuration.command_prefix .. 'ops.'
end

function report:on_message(message, configuration)
    local admin_list = {}
    local admins = mattata.get_chat_administrators(message.chat.id)
    for n in pairs(admins.result) do
        if admins.result[n].user.username then
            if admins.result[n].user.username ~= self.info.username then
                table.insert(
                    admin_list,
                    '@' .. mattata.escape_html(admins.result[n].user.username)
                )
            end
        else
            table.insert(
                admin_list,
                mattata.escape_html(admins.result[n].user.first_name)
            )
        end
    end
    table.sort(admin_list)
    local output = '<b>' .. mattata.escape_html(message.from.first_name) .. ' needs help!</b>\n' .. table.concat(
        admin_list,
        ', '
    )
    return mattata.send_message(
        message.chat.id,
        output,
        'html'
    )
end

return report