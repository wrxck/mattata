--[[
    mattata v2.0 - Custom Captcha Plugin
    Allows admins to set a custom question and answer for the join captcha.
    When configured, new members must type the correct answer instead of solving
    a math problem with buttons.

    Integration note:
    join_captcha.lua should check redis.get('ccaptcha:q:' .. chat_id) to determine
    if a custom captcha is active. If set, join_captcha should skip its own
    on_member_join handling and let this plugin handle the verification flow.
    This plugin sets 'ccaptcha:active:<chat_id>:<user_id>' when it handles a join
    so join_captcha can check that flag to avoid duplicate handling.
]]

local plugin = {}
plugin.name = 'customcaptcha'
plugin.category = 'admin'
plugin.description = 'Set a custom captcha question and answer for new members'
plugin.commands = { 'customcaptcha', 'ccaptcha' }
plugin.help = '/customcaptcha set <question> | <answer> - Set a custom captcha.\n'
    .. '/customcaptcha clear - Remove custom captcha, revert to default.\n'
    .. '/customcaptcha - Show current custom captcha status.'
plugin.group_only = true
plugin.admin_only = true

local tools = require('telegram-bot-lua.tools')
local session = require('src.core.session')
local permissions = require('src.core.permissions')

local MUTE_PERMS = {
    can_send_messages = false, can_send_audios = false, can_send_documents = false,
    can_send_photos = false, can_send_videos = false, can_send_video_notes = false,
    can_send_voice_notes = false, can_send_polls = false, can_send_other_messages = false,
    can_add_web_page_previews = false, can_invite_users = false, can_change_info = false,
    can_pin_messages = false, can_manage_topics = false
}

local UNMUTE_PERMS = {
    can_send_messages = true, can_send_audios = true, can_send_documents = true,
    can_send_photos = true, can_send_videos = true, can_send_video_notes = true,
    can_send_voice_notes = true, can_send_polls = true, can_send_other_messages = true,
    can_add_web_page_previews = true, can_invite_users = true, can_change_info = true,
    can_pin_messages = true, can_manage_topics = true
}

function plugin.on_message(api, message, ctx)
    local chat_id = message.chat.id
    if not message.args then
        -- Show current status
        local question = ctx.redis.get('ccaptcha:q:' .. chat_id)
        local answer = ctx.redis.get('ccaptcha:a:' .. chat_id)
        if question and answer then
            return api.send_message(chat_id, string.format(
                '<b>Custom captcha is active.</b>\n\nQuestion: <i>%s</i>\nExpected answer: <i>%s</i>',
                tools.escape_html(question), tools.escape_html(answer)
            ), { parse_mode = 'html' })
        end
        return api.send_message(chat_id, string.format(
            '<b>No custom captcha configured.</b> The default math captcha will be used.\n\n'
            .. 'Usage:\n'
            .. '<code>/customcaptcha set &lt;question&gt; | &lt;answer&gt;</code> - Set a custom captcha\n'
            .. '<code>/customcaptcha clear</code> - Remove custom captcha'
        ), { parse_mode = 'html' })
    end

    local args = message.args
    local sub_command = args:match('^(%S+)')
    if not sub_command then
        return api.send_message(chat_id, 'Usage: /customcaptcha set <question> | <answer>')
    end
    sub_command = sub_command:lower()

    if sub_command == 'set' then
        local rest = args:match('^%S+%s+(.+)$')
        if not rest then
            return api.send_message(chat_id, 'Usage: <code>/customcaptcha set &lt;question&gt; | &lt;answer&gt;</code>', { parse_mode = 'html' })
        end
        local question, answer = rest:match('^(.-)%s*|%s*(.+)$')
        if not question or question == '' or not answer or answer == '' then
            return api.send_message(chat_id, 'Please separate the question and answer with a pipe character (|).\nExample: <code>/customcaptcha set What colour is the sky? | blue</code>', { parse_mode = 'html' })
        end
        question = question:match('^%s*(.-)%s*$')
        answer = answer:match('^%s*(.-)%s*$')
        if #question > 300 then
            return api.send_message(chat_id, 'The question must be 300 characters or fewer.')
        end
        if #answer > 100 then
            return api.send_message(chat_id, 'The answer must be 100 characters or fewer.')
        end
        ctx.redis.set('ccaptcha:q:' .. chat_id, question)
        ctx.redis.set('ccaptcha:a:' .. chat_id, answer:lower())
        return api.send_message(chat_id, string.format(
            'Custom captcha set!\nQuestion: <i>%s</i>\nExpected answer: <i>%s</i>',
            tools.escape_html(question), tools.escape_html(answer)
        ), { parse_mode = 'html' })
    elseif sub_command == 'clear' then
        ctx.redis.del('ccaptcha:q:' .. chat_id)
        ctx.redis.del('ccaptcha:a:' .. chat_id)
        return api.send_message(chat_id, 'Custom captcha removed. Default math captcha will be used.')
    else
        return api.send_message(chat_id, 'Usage: <code>/customcaptcha set &lt;question&gt; | &lt;answer&gt;</code> or <code>/customcaptcha clear</code>', { parse_mode = 'html' })
    end
end

function plugin.on_member_join(api, message, ctx)
    if not ctx.is_group then return end
    local chat_id = message.chat.id

    -- Check if a custom captcha is configured for this chat
    local question = ctx.redis.get('ccaptcha:q:' .. chat_id)
    if not question then return end

    -- Check if captcha is enabled
    local enabled = session.get_cached_setting(chat_id, 'captcha_enabled', function()
        local ok, result = pcall(ctx.db.call, 'sp_get_chat_setting', { chat_id, 'captcha_enabled' })
        if ok and result and #result > 0 then return result[1].value end
        return nil
    end, 300)
    if enabled ~= 'true' then return end

    if not permissions.can_restrict(api, chat_id) then return end

    local ok_timeout, timeout_result = pcall(ctx.db.call, 'sp_get_chat_setting', { chat_id, 'captcha_timeout' })
    local timeout = (ok_timeout and timeout_result and #timeout_result > 0) and tonumber(timeout_result[1].value) or 300

    local expected_answer = ctx.redis.get('ccaptcha:a:' .. chat_id)
    if not expected_answer then return end

    for _, new_member in ipairs(message.new_chat_members) do
        if new_member.is_bot then goto continue end

        -- Set flag so join_captcha knows this user is handled by custom captcha
        ctx.redis.setex('ccaptcha:active:' .. chat_id .. ':' .. new_member.id, timeout, '1')

        -- Restrict the new member
        api.restrict_chat_member(chat_id, new_member.id, MUTE_PERMS, {
            until_date = os.time() + timeout
        })

        -- Send the custom question
        local text = string.format(
            'Welcome, <a href="tg://user?id=%d">%s</a>! To verify you\'re human, please answer the following question:\n\n<b>%s</b>\n\nType your answer in the chat. You have %d seconds.',
            new_member.id,
            tools.escape_html(new_member.first_name),
            tools.escape_html(question),
            timeout
        )

        local sent = api.send_message(chat_id, text, { parse_mode = 'html' })

        -- Store captcha state using session
        if sent and sent.result then
            session.set_captcha(chat_id, new_member.id, expected_answer, sent.result.message_id, timeout)
        end

        ::continue::
    end
end

function plugin.on_new_message(api, message, ctx)
    if not ctx.is_group then return end
    if not message.text then return end
    if not message.from then return end

    local chat_id = message.chat.id
    local user_id = message.from.id

    -- Check if this user has a pending custom captcha
    local active = ctx.redis.get('ccaptcha:active:' .. chat_id .. ':' .. user_id)
    if not active then return end

    local captcha = session.get_captcha(chat_id, user_id)
    if not captcha then
        -- Captcha expired, clean up the active flag
        ctx.redis.del('ccaptcha:active:' .. chat_id .. ':' .. user_id)
        return
    end

    local user_answer = message.text:lower():match('^%s*(.-)%s*$')
    if user_answer == captcha.text then
        -- Correct answer - unrestrict user
        api.restrict_chat_member(chat_id, user_id, UNMUTE_PERMS)
        session.clear_captcha(chat_id, user_id)
        ctx.redis.del('ccaptcha:active:' .. chat_id .. ':' .. user_id)

        -- Delete the question message
        if captcha.message_id then
            api.delete_message(chat_id, captcha.message_id)
        end
        -- Delete the user's answer message
        api.delete_message(chat_id, message.message_id)

        api.send_message(chat_id, string.format(
            '<a href="tg://user?id=%d">%s</a> has been verified. Welcome!',
            user_id, tools.escape_html(message.from.first_name)
        ), { parse_mode = 'html' })
    else
        -- Wrong answer - delete their message and prompt to try again
        api.delete_message(chat_id, message.message_id)
    end
end

return plugin
