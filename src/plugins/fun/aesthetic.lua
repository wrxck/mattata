--[[
    mattata v2.0 - Aesthetic Plugin
    Converts ASCII text to fullwidth Unicode characters (vaporwave style).
]]

local plugin = {}
plugin.name = 'aesthetic'
plugin.category = 'fun'
plugin.description = 'Convert text to fullwidth aesthetic characters'
plugin.commands = { 'aesthetic', 'fullwidth', 'fw' }
plugin.help = '/aesthetic <text> - Convert text to fullwidth vaporwave text. Use in reply to convert the replied message.'

-- Fullwidth characters start at U+FF01 for '!' (0x21) through U+FF5E for '~' (0x7E).
-- Space (0x20) maps to ideographic space U+3000.
-- Multi-byte UTF-8 characters are passed through unchanged.
local function to_fullwidth(text)
    local result = {}
    for char in text:gmatch('[\1-\127\194-\244][\128-\191]*') do
        local byte = char:byte(1)
        if #char > 1 then
            -- Multi-byte UTF-8 character, pass through unchanged
            table.insert(result, char)
        elseif byte == 0x20 then
            -- ASCII space -> ideographic space U+3000
            table.insert(result, '\xE3\x80\x80')
        elseif byte >= 0x21 and byte <= 0x7E then
            -- ASCII printable -> fullwidth equivalent
            -- U+FF01 + (byte - 0x21)
            local codepoint = 0xFF01 + (byte - 0x21)
            -- Encode as UTF-8 (3-byte sequence for U+FF01..U+FF5E)
            local b1 = 0xE0 + math.floor(codepoint / 4096)
            local b2 = 0x80 + math.floor((codepoint % 4096) / 64)
            local b3 = 0x80 + (codepoint % 64)
            table.insert(result, string.char(b1, b2, b3))
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
        return api.send_message(message.chat.id, 'Please provide some text, or use this command in reply to a message.')
    end
    local output = to_fullwidth(input)
    return api.send_message(message.chat.id, output)
end

return plugin
