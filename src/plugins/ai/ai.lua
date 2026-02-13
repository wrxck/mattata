--[[
    mattata v2.0 - AI Plugin
    AI-powered chat using OpenAI or Anthropic API.
    Must be enabled via AI_ENABLED=true in configuration.
]]

local plugin = {}
plugin.name = 'ai'
plugin.category = 'ai'
plugin.description = 'Chat with an AI assistant'
plugin.commands = { 'ai', 'ask' }
plugin.help = '/ai <prompt> - Send a prompt to the AI assistant and receive a response.'

local MAX_HISTORY = 10
local SYSTEM_PROMPT = 'You are a helpful assistant embedded in a Telegram bot called mattata. '
    .. 'Be concise and direct in your responses. '
    .. 'Use Telegram-compatible formatting (bold, italic, code) when helpful.'

-- Build a Redis key for conversation history
local function history_key(chat_id, user_id)
    return string.format('ai:history:%s:%s', tostring(chat_id), tostring(user_id))
end

-- Retrieve recent conversation history from Redis
local function get_history(redis, chat_id, user_id)
    local json = require('dkjson')
    local key = history_key(chat_id, user_id)
    local raw = redis.lrange(key, 0, MAX_HISTORY * 2 - 1)
    local messages = {}
    if raw and #raw > 0 then
        for _, entry in ipairs(raw) do
            local msg = json.decode(entry)
            if msg then
                table.insert(messages, msg)
            end
        end
    end
    return messages
end

-- Append a message to conversation history
local function push_history(redis, chat_id, user_id, role, content)
    local json = require('dkjson')
    local key = history_key(chat_id, user_id)
    redis.rpush(key, json.encode({ role = role, content = content }))
    -- Trim to keep only recent messages
    redis.ltrim(key, -(MAX_HISTORY * 2), -1)
    -- Auto-expire after 1 hour of inactivity
    redis.expire(key, 3600)
end

-- Call OpenAI Chat Completions API
local function call_openai(api_key, model, messages)
    local http = require('src.core.http')
    local json = require('dkjson')

    local request_body = json.encode({
        model = model,
        messages = messages,
        max_tokens = 1024
    })

    local body, code = http.post('https://api.openai.com/v1/chat/completions', request_body, 'application/json', {
        ['Authorization'] = 'Bearer ' .. api_key
    })

    if code ~= 200 then
        return nil, 'OpenAI API request failed (HTTP ' .. tostring(code) .. ').'
    end

    local data = json.decode(body)
    if not data or not data.choices or #data.choices == 0 then
        return nil, 'No response from OpenAI.'
    end

    return data.choices[1].message and data.choices[1].message.content or nil
end

-- Call Anthropic Messages API
local function call_anthropic(api_key, model, messages)
    local http = require('src.core.http')
    local json = require('dkjson')

    -- Convert from OpenAI message format; extract system prompt
    local system_text = nil
    local api_messages = {}
    for _, msg in ipairs(messages) do
        if msg.role == 'system' then
            system_text = msg.content
        else
            table.insert(api_messages, { role = msg.role, content = msg.content })
        end
    end

    local request_body = json.encode({
        model = model,
        max_tokens = 1024,
        system = system_text or SYSTEM_PROMPT,
        messages = api_messages
    })

    local body, code = http.post('https://api.anthropic.com/v1/messages', request_body, 'application/json', {
        ['x-api-key'] = api_key,
        ['anthropic-version'] = '2023-06-01'
    })

    if code ~= 200 then
        return nil, 'Anthropic API request failed (HTTP ' .. tostring(code) .. ').'
    end

    local data = json.decode(body)
    if not data or not data.content or #data.content == 0 then
        return nil, 'No response from Anthropic.'
    end

    return data.content[1].text
end

-- Main dispatch: pick provider and call
local function get_ai_response(ai_config, messages)
    if ai_config.anthropic_key then
        return call_anthropic(ai_config.anthropic_key, ai_config.anthropic_model, messages)
    elseif ai_config.openai_key then
        return call_openai(ai_config.openai_key, ai_config.openai_model, messages)
    end
    return nil, 'No AI API key has been configured.'
end

function plugin.on_message(api, message, ctx)
    local ai_config = ctx.config.ai()
    if not ai_config.enabled then
        return api.send_message(message.chat.id, 'The AI feature is currently disabled.')
    end

    local input = message.args
    -- If replying to a message, prepend the quoted text for context
    if (not input or input == '') and message.reply and message.reply.text and message.reply.text ~= '' then
        input = message.reply.text
    end

    if not input or input == '' then
        return api.send_message(message.chat.id, 'Please provide a prompt, e.g. <code>/ai What is the capital of France?</code>', { parse_mode = 'html' })
    end

    -- Send typing action while processing
    api.send_chat_action(message.chat.id, 'typing')

    -- Build message history
    local history = get_history(ctx.redis, message.chat.id, message.from.id)
    local messages = {
        { role = 'system', content = SYSTEM_PROMPT }
    }
    for _, msg in ipairs(history) do
        table.insert(messages, msg)
    end
    table.insert(messages, { role = 'user', content = input })

    local response, err = get_ai_response(ai_config, messages)
    if not response then
        return api.send_message(message.chat.id, err or 'Failed to get a response from the AI.')
    end

    -- Store conversation turn
    push_history(ctx.redis, message.chat.id, message.from.id, 'user', input)
    push_history(ctx.redis, message.chat.id, message.from.id, 'assistant', response)

    -- Truncate if response exceeds Telegram's 4096 character limit
    if #response > 4096 then
        response = response:sub(1, 4090) .. '\n...'
    end

    return api.send_message(message.chat.id, response, { link_preview_options = { is_disabled = true }, reply_parameters = { message_id = message.message_id } })
end

-- Respond to @mentions and DMs passively if AI is enabled
function plugin.on_new_message(api, message, ctx)
    local ai_config = ctx.config.ai()
    if not ai_config.enabled then
        return
    end

    -- Skip if this was already handled as a command
    if message.text and message.text:match('^[/!#]') then
        return
    end

    local text = message.text or ''
    local is_mention = false
    local is_dm = message.chat and message.chat.type == 'private'

    -- Check for @bot_username mentions in entities
    if message.entities then
        for _, entity in ipairs(message.entities) do
            if entity.type == 'mention' then
                local mention = text:sub(entity.offset + 1, entity.offset + entity.length)
                if mention:lower() == '@' .. api.info.username:lower() then
                    is_mention = true
                    -- Strip the mention from the input
                    text = text:sub(1, entity.offset) .. text:sub(entity.offset + entity.length + 1)
                    text = text:match('^%s*(.-)%s*$') -- trim
                    break
                end
            end
        end
    end

    if not is_mention and not is_dm then
        return
    end

    if text == '' then
        return
    end

    -- Send typing action
    api.send_chat_action(message.chat.id, 'typing')

    local history = get_history(ctx.redis, message.chat.id, message.from.id)
    local messages = {
        { role = 'system', content = SYSTEM_PROMPT }
    }
    for _, msg in ipairs(history) do
        table.insert(messages, msg)
    end
    table.insert(messages, { role = 'user', content = text })

    local response, _ = get_ai_response(ai_config, messages)
    if not response then
        return
    end

    push_history(ctx.redis, message.chat.id, message.from.id, 'user', text)
    push_history(ctx.redis, message.chat.id, message.from.id, 'assistant', response)

    if #response > 4096 then
        response = response:sub(1, 4090) .. '\n...'
    end

    return api.send_message(message.chat.id, response, { link_preview_options = { is_disabled = true }, reply_parameters = { message_id = message.message_id } })
end

return plugin
