--[[
    mattata v2.0 - Flip Plugin
    Reverse and flip text using upside-down Unicode characters.
]]

local plugin = {}
plugin.name = 'flip'
plugin.category = 'fun'
plugin.description = 'Flip text upside down'
plugin.commands = { 'flip', 'reverse' }
plugin.help = '/flip <text> - Flip text upside down. Use in reply to flip the replied message.'

local FLIP_MAP = {
    ['a'] = '\xC9\x90', ['b'] = 'q', ['c'] = '\xC9\x94', ['d'] = 'p',
    ['e'] = '\xC7\x9D', ['f'] = '\xC9\x9F', ['g'] = '\xC6\x83', ['h'] = '\xC9\xA5',
    ['i'] = '\xE1\xB4\x89', ['j'] = '\xC9\xBE', ['k'] = '\xCA\x9E', ['l'] = 'l',
    ['m'] = '\xC9\xAF', ['n'] = 'u', ['o'] = 'o', ['p'] = 'd',
    ['q'] = 'b', ['r'] = '\xC9\xB9', ['s'] = 's', ['t'] = '\xCA\x87',
    ['u'] = 'n', ['v'] = '\xCA\x8C', ['w'] = '\xCA\x8D', ['x'] = 'x',
    ['y'] = '\xCA\x8E', ['z'] = 'z',
    ['A'] = '\xE2\x88\x80', ['B'] = '\xF0\x9D\x99\xB1', ['C'] = '\xC6\x86', ['D'] = '\xE1\x97\xA1',
    ['E'] = '\xC6\x8E', ['F'] = '\xE2\x84\xB2', ['G'] = '\xE2\x85\x81', ['H'] = 'H',
    ['I'] = 'I', ['J'] = '\xC5\xBF', ['K'] = '\xE2\x8B\x8A', ['L'] = '\xCB\xA5',
    ['M'] = 'W', ['N'] = 'N', ['O'] = 'O', ['P'] = '\xC6\x8A',
    ['Q'] = '\xD2\x8C', ['R'] = '\xCA\x81', ['S'] = 'S', ['T'] = '\xE2\x8A\xA5',
    ['U'] = '\xE2\x88\xA9', ['V'] = '\xCE\x9B', ['W'] = 'M', ['X'] = 'X',
    ['Y'] = '\xE2\x85\x84', ['Z'] = 'Z',
    ['1'] = '\xC6\x96', ['2'] = '\xE1\x84\x85', ['3'] = '\xC6\x90', ['4'] = '\xE1\x84\x8D',
    ['5'] = '\xC7\x82', ['6'] = '9', ['7'] = '\xE1\x84\x82', ['8'] = '8',
    ['9'] = '6', ['0'] = '0',
    ['.'] = '\xCB\x99', [','] = '\xCA\xBB', ['?'] = '\xC2\xBF', ['!'] = '\xC2\xA1',
    ['\''] = ',', ['"'] = ',,', ['('] = ')', [')'] = '(',
    ['['] = ']', [']'] = '[', ['{'] = '}', ['}'] = '{',
    ['<'] = '>', ['>'] = '<', ['_'] = '\xE2\x80\xBE', [';'] = '\xD8\x9B',
    ['&'] = '\xE2\x85\x8B',
}

local function flip_text(text)
    local chars = {}
    -- Iterate through UTF-8 codepoints (not bytes)
    for char in text:gmatch('[\1-\127\194-\244][\128-\191]*') do
        table.insert(chars, FLIP_MAP[char] or char)
    end
    -- Reverse the order
    local reversed = {}
    for i = #chars, 1, -1 do
        table.insert(reversed, chars[i])
    end
    return table.concat(reversed)
end

function plugin.on_message(api, message, ctx)
    local input
    if message.reply and message.reply.text and message.reply.text ~= '' then
        input = message.reply.text
    elseif message.args and message.args ~= '' then
        input = message.args
    else
        return api.send_message(message.chat.id, 'Please provide some text to flip, or use this command in reply to a message.')
    end
    local output = flip_text(input)
    return api.send_message(message.chat.id, output)
end

return plugin
