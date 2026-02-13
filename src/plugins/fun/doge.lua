--[[
    mattata v2.0 - Doge Plugin
    Generates random doge-speak from input words.
]]

local plugin = {}
plugin.name = 'doge'
plugin.category = 'fun'
plugin.description = 'Generate doge-speak from text'
plugin.commands = { 'doge' }
plugin.help = '/doge <text> - Generate doge-speak from the given words.'

local PREFIXES = {
    'such', 'very', 'much', 'so', 'many', 'how', 'amaze', 'wow',
    'excite', 'plz', 'concern', 'what', 'nice', 'great', 'most'
}

function plugin.on_message(api, message, ctx)
    local input
    if message.reply and message.reply.text and message.reply.text ~= '' then
        input = message.reply.text
    elseif message.args and message.args ~= '' then
        input = message.args
    else
        return api.send_message(message.chat.id, 'Please provide some words for the doge to speak.')
    end

    -- Split input into words
    local words = {}
    for word in input:gmatch('%S+') do
        table.insert(words, word:lower())
    end

    if #words == 0 then
        return api.send_message(message.chat.id, 'wow. such empty. much nothing.')
    end

    math.randomseed(os.time() + os.clock() * 1000)
    local lines = {}

    -- Generate doge lines for each word (or up to 8)
    local count = math.min(#words, 8)
    local used_prefixes = {}
    for i = 1, count do
        local prefix
        repeat
            prefix = PREFIXES[math.random(#PREFIXES)]
        until not used_prefixes[prefix] or i > #PREFIXES
        used_prefixes[prefix] = true
        -- Random indentation for the classic doge look
        local padding = string.rep(' ', math.random(0, 12))
        table.insert(lines, padding .. prefix .. ' ' .. words[i])
    end

    -- Always end with wow
    local padding = string.rep(' ', math.random(0, 16))
    table.insert(lines, padding .. 'wow')

    local output = '<pre>' .. table.concat(lines, '\n') .. '</pre>'
    return api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
