--[[
    mattata v2.0 - Staff Plugin
]]

local plugin = {}
plugin.name = 'staff'
plugin.category = 'admin'
plugin.description = 'List group staff (admins and moderators)'
plugin.commands = { 'staff', 'admins', 'mods' }
plugin.help = '/staff - Lists all admins and moderators in the current chat. Aliases: /admins, /mods'
plugin.group_only = true
plugin.admin_only = false

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    -- get telegram admins
    local admins = api.get_chat_administrators(message.chat.id)
    if not admins or not admins.result then
        return api.send_message(message.chat.id, 'I couldn\'t retrieve the admin list.')
    end

    local output = '<b>Staff for ' .. tools.escape_html(message.chat.title or 'this chat') .. '</b>\n\n'

    -- creator
    local creator_text = ''
    for _, admin in ipairs(admins.result) do
        if admin.status == 'creator' then
            local name = tools.escape_html(admin.user.first_name)
            creator_text = string.format(
                '<a href="tg://user?id=%d">%s</a>',
                admin.user.id, name
            )
            break
        end
    end
    if creator_text ~= '' then
        output = output .. '<b>Owner:</b>\n' .. creator_text .. '\n\n'
    end

    -- admins
    local admin_list = {}
    for _, admin in ipairs(admins.result) do
        if admin.status == 'administrator' and not admin.user.is_bot then
            local name = tools.escape_html(admin.user.first_name)
            table.insert(admin_list, string.format(
                '- <a href="tg://user?id=%d">%s</a>',
                admin.user.id, name
            ))
        end
    end
    if #admin_list > 0 then
        output = output .. '<b>Admins (' .. #admin_list .. '):</b>\n' .. table.concat(admin_list, '\n') .. '\n\n'
    end

    -- moderators (from database)
    local mods = ctx.db.call('sp_get_moderators', { message.chat.id })
    if mods and #mods > 0 then
        local mod_list = {}
        for _, mod in ipairs(mods) do
            local info = api.get_chat(mod.user_id)
            local name = info and info.result and tools.escape_html(info.result.first_name) or tostring(mod.user_id)
            table.insert(mod_list, string.format(
                '- <a href="tg://user?id=%s">%s</a>',
                mod.user_id, name
            ))
        end
        output = output .. '<b>Moderators (' .. #mod_list .. '):</b>\n' .. table.concat(mod_list, '\n') .. '\n'
    end

    api.send_message(message.chat.id, output, 'html')
end

return plugin
