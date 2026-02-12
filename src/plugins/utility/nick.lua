--[[
    mattata v2.0 - Nickname Plugin
    Set, view, and delete your nickname.
]]

local plugin = {}
plugin.name = 'nick'
plugin.category = 'utility'
plugin.description = 'Set a custom nickname'
plugin.commands = { 'nick', 'nickname', 'setnick', 'nn' }
plugin.help = '/nick <name> - Set your nickname.\n/nick - View your current nickname.\n/nick --delete - Remove your nickname.'

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local input = message.args

    -- View current nickname
    if not input or input == '' then
        local result = ctx.db.call('sp_get_nickname', { message.from.id })
        if result and result[1] and result[1].nickname then
            return api.send_message(
                message.chat.id,
                string.format('Your nickname is: <b>%s</b>', tools.escape_html(result[1].nickname)),
                'html'
            )
        end
        return api.send_message(message.chat.id, 'You don\'t have a nickname set. Use /nick <name> to set one.')
    end

    -- Delete nickname
    if input == '--delete' or input == '-d' then
        ctx.db.call('sp_clear_nickname', { message.from.id })
        return api.send_message(message.chat.id, 'Your nickname has been removed.')
    end

    -- Validate length
    if #input > 128 then
        return api.send_message(message.chat.id, 'Nicknames must be 128 characters or fewer.')
    end

    -- Set nickname
    ctx.db.call('sp_set_nickname', { message.from.id, input })
    return api.send_message(
        message.chat.id,
        string.format('Your nickname has been set to: <b>%s</b>', tools.escape_html(input)),
        'html'
    )
end

return plugin
