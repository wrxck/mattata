--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local staff = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function staff:init()
    staff.commands = mattata.commands(self.info.username):command('staff'):command('admins').table
    staff.help = '/staff - Displays the staff members in the current chat. Alias: /admins.'
end

function staff.format_admin_list(output, chat_id)
    local creator = ''
    local admin_count = 1
    local admins = ''
    for _, admin in pairs(output.result) do
        local user
        local branch = ' ├ '
        if admin.status == 'creator' then
            creator = mattata.escape_html(admin.user.first_name)
            if admin.user.username then
                creator = string.format(
                    '<a href="https://t.me/%s">%s</a>',
                    admin.user.username,
                    creator
                )
            end
        elseif admin.status == 'administrator' then
            user = mattata.escape_html(admin.user.first_name)
            if admin.user.username then
                user = string.format(
                    '<a href="https://t.me/%s">%s</a>',
                    admin.user.username,
                    user
                )
            end
            admin_count = admin_count + 1
            if admin_count == #output.result then
                branch = ' └ '
            end
            admins = admins .. branch .. user .. '\n'
        end
    end
    local mod_list = redis:smembers('administration:' .. chat_id .. ':mods')
    local mod_count = 0
    local mods = ''
    if next(mod_list) then
        local branch = ' ├ '
        local user
        for i = 1, #mod_list do
            user = mattata.get_linked_name(mod_list[i])
            if user then
                if i == #mod_list then
                    branch = ' └ '
                end
                mods = mods .. branch .. user .. '\n'
                mod_count = mod_count + 1
            end
        end
    end
    if creator == '' then
        creator = '-'
    end
    if admins == '' then
        admins = '-'
    end
    if mods == '' then
        mods = '-'
    end
    return string.format(
        '<b>👤 Creator</b>\n└ %s\n\n<b>👥 Admins</b> (%d)\n%s\n<b>👥 Moderators</b> (%d)\n%s',
        creator,
        admin_count - 1,
        admins,
        mod_count,
        mods
    )
end

function staff.on_message(_, message)
    local input = mattata.input(message.text)
    local chat_id = message.chat.id
    local success
    if input then
        local chat = mattata.get_chat(input)
        if not chat then
            return mattata.send_reply(message, 'That\'s not a valid chat.')
        end
        chat_id = chat.result.id
        success = mattata.get_chat_administrators(chat_id)
    else
        success = mattata.get_chat_administrators(message.chat.id)
    end
    if not success then
        local output = input and 'I wasn\'t able to get information about that chat\'s administrators.' or 'I couldn\'t get a list of administrators in this chat.'
        return mattata.send_reply(message, output)
    end
    return mattata.send_message(message.chat.id, staff.format_admin_list(success, chat_id), 'html')
end

return staff