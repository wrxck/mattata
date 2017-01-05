--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local admins = {}

local mattata = require('mattata')

function admins:init(configuration)
    admins.arguments = 'admins'
    admins.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('admins').table
    admins.help = configuration.command_prefix .. 'admins - Sends a list of the chat\'s administrators.'
end

function admins.format_admin_list(list)
    local administrators = ''
    local administrator = ''
    local creator = ''
    for k, v in pairs(list.result) do
        if v.status == 'administrator' and v.user.first_name ~= '' then
            administrator = mattata.escape_html(v.user.first_name)
            if v.user.username then
                administrator = '<a href="https://telegram.me/' .. v.user.username .. '">' .. mattata.escape_html(v.user.first_name) .. '</a>'
            end
            administrators = administrators .. '• ' .. administrator .. ' <code>[' .. v.user.id .. ']</code>\n'
        elseif v.status == 'creator' and v.user.first_name ~= '' then
            creator = mattata.escape_html(v.user.first_name)
            if v.user.username then
                creator = '<a href="https://telegram.me/' .. v.user.username .. '">' .. mattata.escape_html(v.user.first_name) .. '</a>'
            end
            creator = creator .. ' <code>[' .. v.user.id .. ']</code>'
        end
    end
    if creator == '' then
        creator = '-'
    end
    if administrators == '' then
        administrators = '-'
    end
    return creator, administrators
end

function admins:on_message(message)
    local success = mattata.get_chat_administrators(message.chat.id)
    if not success then
        return mattata.send_reply(
            message,
            'I couldn\'t get a list of administrators in this chat.'
        )
    end
    local creator, administrators = admins.format_admin_list(success)
    return mattata.send_message(
        message.chat.id,
        '<b>Creator:</b> ' .. creator .. '\n<b>Administrators:</b>\n' .. administrators,
        'html'
    )
end

return admins