--[[
    mattata v2.0 - Promote Plugin
]]

local plugin = {}
plugin.name = 'promote'
plugin.category = 'admin'
plugin.description = 'Promote a user to moderator'
plugin.commands = { 'promote' }
plugin.help = '/promote [user] - Promotes a user to moderator in the current chat.'
plugin.group_only = true
plugin.admin_only = true

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    local user_id
    if message.reply and message.reply.from then
        user_id = message.reply.from.id
    elseif message.args then
        user_id = message.args:match('^@?(%S+)')
        if tonumber(user_id) == nil then
            user_id = ctx.redis.get('username:' .. user_id:lower())
        end
    end
    user_id = tonumber(user_id)
    if not user_id then
        return api.send_message(message.chat.id, 'Please specify the user to promote, either by replying to their message or providing a username/ID.')
    end
    if user_id == api.info.id then return end
    if permissions.is_group_mod(ctx.db, message.chat.id, user_id) then
        return api.send_message(message.chat.id, 'That user is already a moderator.')
    end

    ctx.db.upsert('chat_members', {
        chat_id = message.chat.id,
        user_id = user_id,
        role = 'moderator'
    }, { 'chat_id', 'user_id' }, { 'role' })

    pcall(function()
        ctx.db.insert('admin_actions', {
            chat_id = message.chat.id,
            admin_id = message.from.id,
            target_id = user_id,
            action = 'promote'
        })
    end)

    local admin_name = tools.escape_html(message.from.first_name)
    local target_info = api.get_chat(user_id)
    local target_name = target_info and target_info.result and tools.escape_html(target_info.result.first_name) or tostring(user_id)

    api.send_message(message.chat.id, string.format(
        '<a href="tg://user?id=%d">%s</a> has promoted <a href="tg://user?id=%d">%s</a> to moderator.',
        message.from.id, admin_name, user_id, target_name
    ), 'html')
end

return plugin
