--[[
    mattata v2.0 - Mock Plugin
    SpOnGeBoB mOcKiNg TeXt generator.
]]

local plugin = {}
plugin.name = 'mock'
plugin.category = 'fun'
plugin.description = 'Generate SpOnGeBoB mOcKiNg text'
plugin.commands = { 'mock' }
plugin.help = '/mock <text> - Convert text to mOcKiNg CaSe. Use in reply to mock the replied message.'

local function mockify(text)
    local result = {}
    local i = 0
    for char in text:gmatch('.') do
        if char:match('%a') then
            i = i + 1
            if i % 2 == 0 then
                table.insert(result, char:upper())
            else
                table.insert(result, char:lower())
            end
        else
            table.insert(result, char)
        end
    end
    return table.concat(result)
end

function plugin.on_message(api, message, ctx)
    local input
    if message.reply and message.reply.text and message.reply.text ~= '' then
        input = message.reply.text
    elseif message.args and message.args ~= '' then
        input = message.args
    else
        return api.send_message(message.chat.id, 'Please provide some text to mock, or use this command in reply to a message.')
    end
    local output = mockify(input)
    return api.send_message(message.chat.id, output)
end

return plugin
