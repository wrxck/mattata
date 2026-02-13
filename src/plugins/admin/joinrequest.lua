--[[
    mattata v2.1 - Join Request Plugin
    Manage join request policies for groups with approval-required invites.
    Depends on the on_chat_join_request router hook (Phase 3).
]]

local plugin = {}
plugin.name = 'joinrequest'
plugin.category = 'admin'
plugin.description = 'Manage join request policy'
plugin.commands = { 'joinrequest' }
plugin.help = '/joinrequest <auto-approve|auto-reject|manual> - Set the join request policy for this chat.'
plugin.group_only = true
plugin.admin_only = true

local json = require('dkjson')

local function normalize_policy(input)
    input = input:lower()
    if input == 'auto-approve' or input == 'approve' or input == 'auto' then
        return 'auto-approve'
    elseif input == 'auto-reject' or input == 'reject' or input == 'deny' then
        return 'auto-reject'
    elseif input == 'manual' or input == 'notify' then
        return 'manual'
    end
    return nil
end

function plugin.on_message(api, message, ctx)
    if not message.args or message.args == '' then
        local current = ctx.db.call('sp_get_chat_setting', { message.chat.id, 'join_request_policy' })
        local policy = (current and #current > 0) and current[1].value or 'manual'
        return api.send_message(message.chat.id, string.format(
            'Current join request policy: <b>%s</b>\n\nUsage: /joinrequest <auto-approve|auto-reject|manual>',
            policy
        ), 'html')
    end

    local policy = normalize_policy(message.args)
    if not policy then
        return api.send_message(message.chat.id, 'Invalid policy. Use: auto-approve, auto-reject, or manual')
    end

    ctx.db.call('sp_upsert_chat_setting', { message.chat.id, 'join_request_policy', policy })
    require('src.core.session').invalidate_setting(message.chat.id, 'join_request_policy')

    return api.send_message(message.chat.id, string.format(
        'Join request policy set to <b>%s</b>.', policy
    ), 'html')
end

-- Handle incoming join requests based on configured policy
function plugin.on_chat_join_request(api, request, ctx)
    local session = require('src.core.session')
    local tools = require('telegram-bot-lua.tools')

    local policy = session.get_cached_setting(request.chat.id, 'join_request_policy', function()
        local result = ctx.db.call('sp_get_chat_setting', { request.chat.id, 'join_request_policy' })
        if result and #result > 0 then return result[1].value end
        return nil
    end, 300)

    if not policy or policy == 'manual' then
        -- Post notification with approve/reject buttons
        local keyboard = {
            inline_keyboard = { {
                { text = 'Approve', callback_data = 'joinrequest:approve:' .. request.from.id },
                { text = 'Reject', callback_data = 'joinrequest:reject:' .. request.from.id }
            } }
        }
        local text = string.format(
            '<a href="tg://user?id=%d">%s</a> wants to join this chat.',
            request.from.id,
            tools.escape_html(request.from.first_name)
        )
        return api.send_message(request.chat.id, text, 'html', false, false, nil, json.encode(keyboard))

    elseif policy == 'auto-approve' then
        return api.approve_chat_join_request(request.chat.id, request.from.id)

    elseif policy == 'auto-reject' then
        return api.decline_chat_join_request(request.chat.id, request.from.id)
    end
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local data = callback_query.data
    if not data then return end

    local action, user_id = data:match('^(approve):(%d+)$')
    if not action then
        action, user_id = data:match('^(reject):(%d+)$')
    end
    if not action or not user_id then return end

    user_id = tonumber(user_id)

    -- Only admins can handle join requests
    local permissions = require('src.core.permissions')
    if not permissions.is_group_admin(api, message.chat.id, callback_query.from.id) then
        return api.answer_callback_query(callback_query.id, 'Only admins can handle join requests.')
    end

    local tools = require('telegram-bot-lua.tools')
    if action == 'approve' then
        local result = api.approve_chat_join_request(message.chat.id, user_id)
        if result then
            api.edit_message_text(message.chat.id, message.message_id, string.format(
                'Join request from <a href="tg://user?id=%d">user</a> approved by %s.',
                user_id, tools.escape_html(callback_query.from.first_name)
            ), 'html')
            return api.answer_callback_query(callback_query.id, 'Approved.')
        end
        return api.answer_callback_query(callback_query.id, 'Failed to approve. The request may have expired.')
    else
        local result = api.decline_chat_join_request(message.chat.id, user_id)
        if result then
            api.edit_message_text(message.chat.id, message.message_id, string.format(
                'Join request from <a href="tg://user?id=%d">user</a> rejected by %s.',
                user_id, tools.escape_html(callback_query.from.first_name)
            ), 'html')
            return api.answer_callback_query(callback_query.id, 'Rejected.')
        end
        return api.answer_callback_query(callback_query.id, 'Failed to reject. The request may have expired.')
    end
end

return plugin
