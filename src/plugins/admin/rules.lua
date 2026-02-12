--[[
    mattata v2.0 - Rules Plugin
]]

local plugin = {}
plugin.name = 'rules'
plugin.category = 'admin'
plugin.description = 'Display group rules'
plugin.commands = { 'rules' }
plugin.help = '/rules - Displays the group rules. Admins can set rules with /setrules <text>.'
plugin.group_only = true
plugin.admin_only = false

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')

    -- If /rules is used with args and user is admin, set rules
    if message.args and (ctx.is_admin or ctx.is_global_admin) then
        ctx.db.upsert('rules', {
            chat_id = message.chat.id,
            rules_text = message.args
        }, { 'chat_id' }, { 'rules_text' })
        return api.send_message(message.chat.id, 'The rules have been updated.')
    end

    -- Retrieve rules
    local result = ctx.db.execute(
        'SELECT rules_text FROM rules WHERE chat_id = $1',
        { message.chat.id }
    )
    if not result or #result == 0 or not result[1].rules_text then
        return api.send_message(message.chat.id, 'No rules have been set for this group. An admin can set them with /rules <text>.')
    end

    local output = string.format(
        '<b>Rules for %s:</b>\n\n%s',
        tools.escape_html(message.chat.title or 'this chat'),
        result[1].rules_text
    )
    api.send_message(message.chat.id, output, 'html')
end

return plugin
