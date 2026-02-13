--[[
    mattata v2.0 - Quote Plugin
    Save and retrieve random quotes per chat. Stores in Redis set quotes:{chat_id}.
]]

local plugin = {}
plugin.name = 'quote'
plugin.category = 'fun'
plugin.description = 'Save and retrieve random quotes'
plugin.commands = { 'quote', 'q', 'addquote' }
plugin.help = '/addquote - Save the replied message as a quote.\n/quote - Retrieve a random saved quote from this chat.'

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local json = require('dkjson')
    local redis = ctx.redis
    local chat_id = message.chat.id
    local key = 'quotes:' .. chat_id

    if message.command == 'addquote' then
        -- Save a quote from a reply
        if not message.reply then
            return api.send_message(chat_id, 'Please use /addquote in reply to a message you want to save as a quote.')
        end
        local quote_text = message.reply.text
        if not quote_text or quote_text == '' then
            return api.send_message(chat_id, 'The replied message has no text to save.')
        end
        local author = message.reply.from and message.reply.from.first_name or 'Unknown'
        local quote_data = json.encode({
            text = quote_text,
            author = author,
            author_id = message.reply.from and message.reply.from.id,
            saved_by = message.from.first_name,
            saved_at = os.time()
        })
        redis.sadd(key, quote_data)
        return api.send_message(chat_id, 'Quote saved successfully.')
    end

    -- Retrieve a random quote
    local quotes = redis.smembers(key)
    if not quotes or #quotes == 0 then
        return api.send_message(chat_id, 'No quotes saved in this chat yet. Use /addquote in reply to a message to save one.')
    end

    math.randomseed(os.time() + os.clock() * 1000)
    local raw = quotes[math.random(#quotes)]
    local quote, _ = json.decode(raw)
    if not quote then
        return api.send_message(chat_id, 'Failed to read quote data.')
    end

    local output = string.format(
        '\xE2\x80\x9C%s\xE2\x80\x9D\n\n\xE2\x80\x94 %s',
        tools.escape_html(quote.text),
        tools.escape_html(quote.author)
    )
    return api.send_message(chat_id, output, { parse_mode = 'html' })
end

return plugin
