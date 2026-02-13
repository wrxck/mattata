--[[
    mattata v2.0 - Join Captcha Plugin
    Handles captcha verification for new members joining the group.
]]

local plugin = {}
plugin.name = 'join_captcha'
plugin.category = 'admin'
plugin.description = 'Captcha challenge for new members'
plugin.commands = {}
plugin.help = ''
plugin.group_only = true
plugin.admin_only = false

local json = require('dkjson')

-- Generate a simple math captcha
local function generate_captcha()
    math.randomseed(os.time())
    local a = math.random(1, 20)
    local b = math.random(1, 20)
    local operators = { '+', '-' }
    local op = operators[math.random(1, 2)]
    local answer
    if op == '+' then
        answer = a + b
    else
        -- Ensure non-negative result
        if a < b then a, b = b, a end
        answer = a - b
    end
    return string.format('%d %s %d', a, op, b), tostring(answer)
end

-- Generate wrong answers for the keyboard
local function generate_options(correct_answer)
    local options = { correct_answer }
    local correct_num = tonumber(correct_answer)
    while #options < 4 do
        local wrong = correct_num + math.random(-5, 5)
        if wrong ~= correct_num and wrong >= 0 then
            local str = tostring(wrong)
            local duplicate = false
            for _, v in ipairs(options) do
                if v == str then duplicate = true; break end
            end
            if not duplicate then
                table.insert(options, str)
            end
        end
    end
    -- Shuffle
    for i = #options, 2, -1 do
        local j = math.random(1, i)
        options[i], options[j] = options[j], options[i]
    end
    return options
end

function plugin.on_member_join(api, message, ctx)
    if not ctx.is_group then return end

    -- Check if captcha is enabled
    local enabled = ctx.db.execute(
        "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = 'captcha_enabled'",
        { message.chat.id }
    )
    if not enabled or #enabled == 0 or enabled[1].value ~= 'true' then
        return
    end

    if not require('src.core.permissions').can_restrict(api, message.chat.id) then return end

    local timeout_result = ctx.db.execute(
        "SELECT value FROM chat_settings WHERE chat_id = $1 AND key = 'captcha_timeout'",
        { message.chat.id }
    )
    local timeout = (timeout_result and #timeout_result > 0) and tonumber(timeout_result[1].value) or 300

    for _, new_member in ipairs(message.new_chat_members) do
        if new_member.is_bot then goto continue end

        -- Restrict the new member
        api.restrict_chat_member(message.chat.id, new_member.id, os.time() + timeout, {
            can_send_messages = false,
            can_send_media_messages = false,
            can_send_other_messages = false,
            can_add_web_page_previews = false
        })

        -- Generate captcha
        local question, answer = generate_captcha()
        local options = generate_options(answer)

        -- Build keyboard
        local keyboard = { inline_keyboard = { {} } }
        for _, opt in ipairs(options) do
            table.insert(keyboard.inline_keyboard[1], {
                text = opt,
                callback_data = string.format('join_captcha:%s:%s:%s', message.chat.id, new_member.id, opt)
            })
        end

        local tools = require('telegram-bot-lua.tools')
        local text = string.format(
            'Welcome, <a href="tg://user?id=%d">%s</a>! Please solve this to verify you\'re human:\n\n<b>What is %s?</b>\n\nYou have %d seconds.',
            new_member.id,
            tools.escape_html(new_member.first_name),
            question,
            timeout
        )

        local sent = api.send_message(message.chat.id, text, {
            parse_mode = 'html',
            reply_markup = json.encode(keyboard)
        })

        -- Store captcha state
        if sent and sent.result then
            ctx.session.set_captcha(message.chat.id, new_member.id, answer, sent.result.message_id, timeout)
        end

        ::continue::
    end
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local data = callback_query.data
    if not data then return end

    local chat_id, user_id, selected = data:match('^(%-?%d+):(%d+):(.+)$')
    if not chat_id then return end

    chat_id = tonumber(chat_id)
    user_id = tonumber(user_id)

    -- Only the joining user can answer
    if callback_query.from.id ~= user_id then
        return api.answer_callback_query(callback_query.id, 'This captcha is not for you.')
    end

    local captcha = ctx.session.get_captcha(chat_id, user_id)
    if not captcha then
        return api.answer_callback_query(callback_query.id, 'This captcha has expired.')
    end

    if selected == captcha.text then
        -- Correct answer - unrestrict user
        api.restrict_chat_member(chat_id, user_id, 0, {
            can_send_messages = true,
            can_send_media_messages = true,
            can_send_other_messages = true,
            can_add_web_page_previews = true
        })
        ctx.session.clear_captcha(chat_id, user_id)

        local tools = require('telegram-bot-lua.tools')
        api.edit_message_text(message.chat.id, message.message_id, string.format(
            '<a href="tg://user?id=%d">%s</a> has been verified. Welcome!',
            user_id, tools.escape_html(callback_query.from.first_name)
        ), 'html')
        api.answer_callback_query(callback_query.id, 'Correct! Welcome to the group.')
    else
        -- Wrong answer
        api.answer_callback_query(callback_query.id, 'Wrong answer. Try again!')
    end
end

return plugin
