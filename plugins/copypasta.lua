--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local copypasta = {}
local mattata = require('mattata')

function copypasta:init(configuration)
    copypasta.commands = mattata.commands(self.info.username):command('copypasta'):command(utf8.char(128514)).table
    copypasta.help = '/copypasta - Riddles the replied-to message with cancerous emoji. Alias: /' .. utf8.char(128514) .. '.'
    copypasta.limit = configuration.limits.copypasta
end

function copypasta.aestheticise(input)
    if not input then
        return false
    end
    local output = {}
    for char in input:gmatch('.') do
        local success, point = pcall(function()
            return utf8.codepoint(char)
        end)
        if success and (point >= 33 and point <= 126) then
            table.insert(output, utf8.char(point + 65248))
        else
            table.insert(output, char)
        end
    end
    output = table.concat(output)
    return output
end

function copypasta.format_message(input)
    local emoji = {
        128514, -- crying with laughter
        128514,
        128514,
        128076, -- ok hand
        128076,
        128166, -- water drops
        128166,
        128064, -- eyes
        128064,
        9996, -- peace sign hand
        128158, -- rotating hearts
        128077, -- thumbs up
        128175, -- 100//
        127926, -- music symbol
        128083, -- glasses
        128079, -- clapping hands
        128080, -- open hands
        127829, -- pizza slice
        128165, -- explosion
        127860, -- knife and fork
        127825, -- peach
        127814, -- aubergine
        128553, -- moaning face
        128527, -- smirking face
        128073, -- finger pointing to right
        128069, -- tongue
        128553 -- moaning face
    }
    local output = {}
    for i = 1, input:len() do
        local char = input:sub(i, i)
        math.random(os.time())
        if char == ' ' then
            local rnd_total = math.random(#emoji)
            local rnd_emoji = utf8.char(emoji[rnd_total])
            if math.random(2) == 2
            then
                rnd_total = math.random(#emoji)
                rnd_emoji = rnd_emoji .. ' ' .. utf8.char(emoji[rnd_total])
            end
            char = char .. rnd_emoji .. char
        elseif math.random(5) == 5 then
            char = char:lower()
        end
        table.insert(output, char)
    end
    output = table.concat(output)
    output = copypasta.aestheticise(output)
    return output
end

function copypasta.on_message(_, message, _, language)
    if not message.reply then
        return mattata.send_reply(message, copypasta.help)
    end
    local output
    mattata.send_chat_action(message.chat.id)
    if message.reply.text:len() > copypasta.limit then
        output = string.format(language['copypasta']['1'], copypasta.limit)
        return mattata.send_reply(message, output)
    end
    output = copypasta.format_message(message.reply.text:upper())
    message.message_id = message.reply.message_id
    return mattata.send_reply(message, output)
end

return copypasta