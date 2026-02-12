--[[
    mattata v2.0 - Copypasta Plugin
    Adds random emoji throughout text for that classic copypasta feel.
]]

local plugin = {}
plugin.name = 'copypasta'
plugin.category = 'fun'
plugin.description = 'Add random emoji throughout text'
plugin.commands = { 'copypasta', 'pasta' }
plugin.help = '/copypasta <text> - Sprinkle random emoji into text. Use in reply to copypasta the replied message.'

local EMOJIS = {
    '\xF0\x9F\x98\x82', -- U+1F602 face with tears of joy
    '\xF0\x9F\x98\xA4', -- U+1F624 face with steam from nose
    '\xF0\x9F\x98\xA1', -- U+1F621 pouting face
    '\xF0\x9F\x98\x8E', -- U+1F60E sunglasses face
    '\xF0\x9F\x98\x8D', -- U+1F60D heart eyes
    '\xF0\x9F\x98\xAD', -- U+1F62D loudly crying face
    '\xF0\x9F\x98\xB1', -- U+1F631 face screaming in fear
    '\xF0\x9F\x98\xB3', -- U+1F633 flushed face
    '\xF0\x9F\x98\xA9', -- U+1F629 weary face
    '\xF0\x9F\x98\x8F', -- U+1F60F smirking face
    '\xF0\x9F\x98\x9C', -- U+1F61C winking face with tongue
    '\xF0\x9F\x94\xA5', -- U+1F525 fire
    '\xF0\x9F\x92\xAF', -- U+1F4AF hundred points
    '\xF0\x9F\x91\x8C', -- U+1F44C OK hand sign
    '\xF0\x9F\x91\x80', -- U+1F440 eyes
    '\xF0\x9F\x92\x80', -- U+1F480 skull
    '\xF0\x9F\x92\xAA', -- U+1F4AA flexed biceps
    '\xF0\x9F\x99\x8F', -- U+1F64F folded hands
    '\xE2\x9C\x8A',     -- U+270A raised fist
    '\xF0\x9F\x98\xA0', -- U+1F620 angry face
    '\xF0\x9F\x98\x88', -- U+1F608 smiling face with horns
    '\xE2\x9C\xA8',     -- U+2728 sparkles
    '\xF0\x9F\x92\x85', -- U+1F485 nail polish
    '\xF0\x9F\x91\x8F', -- U+1F44F clapping hands
    '\xF0\x9F\x98\xAB', -- U+1F62B tired face
}

local function random_emoji()
    return EMOJIS[math.random(#EMOJIS)]
end

local function copypasta(text)
    math.randomseed(os.time() + os.clock() * 1000)
    local words = {}
    for word in text:gmatch('%S+') do
        table.insert(words, word:upper())
    end
    local result = {}
    for i, word in ipairs(words) do
        table.insert(result, word)
        -- Add 1-3 random emoji after each word
        local emoji_count = math.random(1, 3)
        local emojis = {}
        for _ = 1, emoji_count do
            table.insert(emojis, random_emoji())
        end
        table.insert(result, table.concat(emojis, ''))
    end
    return table.concat(result, ' ')
end

function plugin.on_message(api, message, ctx)
    local input
    if message.reply and message.reply.text and message.reply.text ~= '' then
        input = message.reply.text
    elseif message.args and message.args ~= '' then
        input = message.args
    else
        return api.send_message(message.chat.id, 'Please provide some text, or use this command in reply to a message.')
    end
    local output = copypasta(input)
    return api.send_message(message.chat.id, output)
end

return plugin
