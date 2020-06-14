--[[
    Based on a plugin by topkecleon.
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local calc = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')

function calc:init()
    calc.commands = mattata.commands(self.info.username):command('calc'):command('calculate'):command('calculator').table
    calc.help = '/calc <expression> - Solves the given mathematical expression using mathjs.org.'
    calc.aliases = {
        ['?'] = '/',
        ['divided by'] = '/',
        ['times by'] = '*',
        ['times'] = '*',
        ['multiplied by'] = '*',
        [' x '] = '*',
        ['minus'] = '-',
        ['subtract'] = '-',
        ['take away'] = '-',
        ['to the power of'] = '^',
        ['raised to'] = '^',
        [' pi '] = math.pi,
        ['plus'] = '+',
        ['added to'] = '+',
        ['add'] = '+',
        ['point'] = '.',
        ['dot'] = '.'
    }
    calc.numbers = {
        ['zero'] = 0,
        ['one'] = 1,
        ['two'] = 2,
        ['three'] = 3,
        ['four'] = 4,
        ['five'] = 5,
        ['six'] = 6,
        ['seven'] = 7,
        ['eight'] = 8,
        ['nine'] = 9,
        ['ten'] = 10,
        ['eleven'] = 11,
        ['twelve'] = 12,
        ['thirteen'] = 13,
        ['fourteen'] = 14,
        ['fifteen'] = 15,
        ['sixteen'] = 16,
        ['seventeen'] = 17,
        ['eighteen'] = 18,
        ['nineteen'] = 19,
        ['twenty'] = 20,
        ['thirty'] = 30,
        ['forty'] = 40,
        ['fifty'] = 50,
        ['sixty'] = 60,
        ['seventy'] = 70,
        ['eighty'] = 80,
        ['ninety'] = 90
    }
    calc.units = {
        ['hundred'] = '100',
        ['thousand'] = '1000',
        ['million'] = '1000000',
        ['billion'] = '1000000000',
        ['trillion'] = '1000000000000',
        ['quadrillion'] = '1000000000000000',
        ['quintillion'] = '1000000000000000000',
        ['sextillion'] = '1000000000000000000000',
        ['septillion'] = '1000000000000000000000000',
        ['octillion'] = '1000000000000000000000000000',
        ['nonillion'] = '1000000000000000000000000000000',
        ['decillion'] = '1000000000000000000000000000000000',
        ['undecillion'] = '1000000000000000000000000000000000000',
        ['duodecillion'] = '1000000000000000000000000000000000000000',
        ['tredecillion'] = '1000000000000000000000000000000000000000000',
        ['quattuordecillion'] = '1000000000000000000000000000000000000000000000',
        ['quindecillion'] = '1000000000000000000000000000000000000000000000000',
        ['sexdecillion'] = '1000000000000000000000000000000000000000000000000000',
        ['septendecillion'] = '1000000000000000000000000000000000000000000000000000000',
        ['octodecillion'] = '1000000000000000000000000000000000000000000000000000000000',
        ['novemdecillion'] = '1000000000000000000000000000000000000000000000000000000000000',
        ['vigintillion'] = '1000000000000000000000000000000000000000000000000000000000000000'
    }
    calc.url = 'https://api.mathjs.org/v4/?expr='
end

function calc.convert(str, language)
    str = str:lower()
    local results = {}
    local prev = nil
    for word in str:gmatch('%w+') do
        if word ~= 'and' then -- don't process "and"
            local top = #results
            local number = tonumber(word)
            if not number then
                number = calc.numbers[word]
            end
            if number then
                if prev == 'number' then
                    local prev_num = table.remove(results, top)
                    number = number + prev_num
                end
                table.insert(results, number)
                prev = 'number'
            else
                local unit = tonumber(calc.units[word])
                if not unit then
                    return false, string.format(language['calc']['2'], word)
                end
                prev = 'unit'
                if top == 0 then
                    return false, language['calc']['3']
                end
                local interim = 0
                while top > 0 and results[top] < unit do
                    interim = interim + table.remove(results, top)
                    top = #results
                end
                table.insert(results, interim * unit)
            end
        end
    end
    if #results == 0 then
        return false, 'No number found!'
    end
    local final = 0
    for _, res in ipairs(results) do
        final = final + res
    end
    return final
end


function calc.process_input(input, language)
    for k, v in pairs(calc.aliases) do
        input = input:gsub(k, v)
    end
    for phrase in input:gmatch('[%w%s]+') do
        local new, err = calc.convert(phrase, language)
        if new then
            input = input:gsub(phrase, new)
        else
            return false, err
        end
    end
    return input
end

function calc.on_inline_query(_, inline_query, _, language)
    local input = mattata.input(inline_query.query)
    if not input then
        return false
    end
    input = calc.process_input(input, language)
    local str, res = http.request(calc.url .. url.escape(input))
    if res ~= 200 or not str then
        return false
    end
    local description = language['calc']['1']
    local message_content = mattata.input_text_message_content(str)
    local result = mattata.inline_result()
    :type('article')
    :id(1)
    :title(str)
    :description(description)
    :input_message_content(message_content)
    return mattata.answer_inline_query(inline_query.id, result)
end

function calc.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    local err
    if not input then
        return mattata.send_reply(message, calc.help)
    end
    input, err = calc.process_input(input, language)
    if not input then
        return mattata.send_reply(message, err)
    end
    local str, res = http.request(calc.url .. url.escape(input))
    if res ~= 200 then
        local response = language['errors']['results']
        return mattata.send_reply(message, response)
    end
    return mattata.send_message(message.chat.id, str)
end

return calc