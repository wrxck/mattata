--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local exec = {}

local mattata = require('mattata')
local http = require('socket.http')
local ltn12 = require('ltn12')
local multipart = require('multipart-post')
local json = require('dkjson')
local redis = require('mattata-redis')

function exec:init()
    exec.commands = mattata.commands(
        self.info.username
    ):command('exec').table
    exec.help = [[/exec <language> <code> - Executes the specified code in the given language and returns the output.]]
end

exec.languages = {
    ['C#'] = '1',
    ['VB.NET'] = '2',
    ['Java'] = '4',
    ['Python'] = '5',
    ['PHP'] = '8',
    ['Pascal'] = '9',
    ['Objective-C'] = '10',
    ['Haskell'] = '11',
    ['Ruby'] = '12',
    ['Perl'] = '13',
    ['Lua'] = '14',
    ['JavaScript'] = '17',
    ['GoLang'] = '20',
    ['Node.js'] = '23',
    ['Python 3'] = '24',
    ['C'] = '26',
    ['C++'] = '27',
    ['MySQL'] = '33',
    ['Swift'] = '37',
    ['Bash'] = '38'
}

function exec.get_keyboard(user_id)
    local keyboard = {
        ['inline_keyboard'] = {
            {}
        }
    }
    local total = 0
    for _, v in pairs(exec.languages) do
        total = total + 1
    end
    local count = 0
    local rows = math.floor(total / 8)
    if rows ~= total then
        rows = rows + 1
    end
    local row = 1
    for k, v in pairs(exec.languages) do
        count = count + 1
        if count == rows * row then
            row = row + 1
            table.insert(
                keyboard.inline_keyboard,
                {}
            )
        end
        local last_used = redis:get('exec:' .. user_id .. ':last_used')
        if last_used and last_used == v then
            k = utf8.char(9889) .. ' ' .. k
        end
        table.insert(
            keyboard.inline_keyboard[row],
            {
                ['text'] = k,
                ['callback_data'] = 'exec:' .. user_id .. ':' .. v .. ':n'
            }
        )
    end
    return keyboard
end

function exec.get_arguments(language)
    if language == '6' or language == '26' then
        return '-Wall -std=gnu99 -O2 -o a.out source_file.c'
    elseif language == '7' or language == '27' then
        return '-Wall -std=c++14 -O2 -o a.out source_file.cpp'
    elseif language == '28' then
        return 'source_file.cpp -o a.exe /EHsc /MD /I C:\\\\boost_1_60_0 /link /LIBPATH:C:\\\\boost_1_60_0\\\\stage\\\\lib'
    elseif language == '29' then
        return 'source_file.c -o a.exe'
    elseif language == '30' then
        return 'source_file.d -ofa.out'
    elseif language == '20' then
        return '-o a.out source_file.go'
    elseif language == '11' then
        return '-o a.out source_file.hs'
    elseif language == '10' then
        return '-MMD -MP -DGNUSTEP -DGNUSTEP_BASE_LIBRARY=1 -DGNU_GUI_LIBRARY=1 -DGNU_RUNTIME=1 -DGNUSTEP_BASE_LIBRARY=1 -fno-strict-aliasing -fexceptions -fobjc-exceptions -D_NATIVE_OBJC_EXCEPTIONS -pthread -fPIC -Wall -DGSWARN -DGSDIAGNOSE -Wno-import -g -O2 -fgnu-runtime -fconstant-string-class=NSConstantString -I. -I /usr/include/GNUstep -I/usr/include/GNUstep -o a.out source_file.m -lobjc -lgnustep-base'
    end
    return ''
end

function exec.make_request(language, code)
    language = language:lower()
    local args = exec.get_arguments(language)
    local parameters = {
        ['LanguageChoice'] = language,
        ['Program'] = code,
        ['Input'] = 'stdin',
        ['CompilerArgs'] = args
    }
    local response = {}
    local body, boundary = multipart.encode(parameters)
    local old_timeout = http.TIMEOUT
    http.TIMEOUT = 2 -- Set the timeout to 2 seconds to prevent people from making the bot lag.
    local jstr, res = http.request(
        {
            ['url'] = 'http://rextester.com/rundotnet/api/',
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
                ['Content-Length'] = #body
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    http.TIMEOUT = old_timeout
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(table.concat(response))
    local output = {}
    if jdat.Warnings and jdat.Warnings ~= '' then
        table.insert(
            output,
            '<b>Warnings</b>\n' .. mattata.escape_html(jdat.Warnings)
        )
    end
    if jdat.Errors and jdat.Errors ~= '' then
        table.insert(
            output,
            '<b>Errors</b>\n' .. mattata.escape_html(jdat.Errors)
        )
    end
    if jdat.Result and jdat.Result ~= '' then
        table.insert(
            output,
            '<b>Result</b>\n<pre>' .. mattata.escape_html(jdat.Result) .. '</pre>'
        )
    end
    if jdat.Stats and jdat.Stats ~= '' then
        table.insert(
            output,
            '<b>Statistics</b>\n• ' .. mattata.escape_html(
                jdat.Stats:gsub('%, ', '\n• '):gsub('cpu', 'CPU'):gsub('memory', 'Memory'):gsub('absolute', 'Absolute'):gsub('%,', '.')
            )
        )
    end
    table.insert(
        output,
        '\n<i>Made a mistake? Edit your message and I\'ll amend mine accordingly!</i>'
    )
    return table.concat(
        output,
        '\n'
    )
end

function exec:on_callback_query(callback_query, message)
    local user_id, language, confirmed = callback_query.data:match('^(.-)%:(.-)%:(.-)$')
    if not user_id or not language or not message.reply then
        return
    elseif tostring(callback_query.from.id) ~= user_id then
        return
    elseif language == 'back' then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'Please select the language you would like to execute your code in:',
            nil,
            true,
            exec.get_keyboard(user_id)
        )
    end
    local code = mattata.input(message.reply.text)
    if not code then
        return
    end
    local language_name
    for k, v in pairs(exec.languages) do
        if v == language then
            language_name = k
        end
    end
    if not language_name then
        return
    elseif confirmed == 'y' then
        redis:set(
            'exec:' .. user_id .. ':last_used',
            language
        )
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            exec.make_request(
                language,
                code
            ),
            'html'
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        'You have selected "' .. language_name .. '" - are you sure?',
        nil,
        true,
        mattata.inline_keyboard():row(
            mattata.row():callback_data_button(
                'Back',
                'exec:' .. user_id .. ':back:n'
            ):callback_data_button(
                'I\'m sure',
                'exec:' .. user_id .. ':' .. language .. ':y'
            )
        )
    )
end

function exec:on_edited_message(edited_message, configuration)
    local input = mattata.input(edited_message.text)
    if not input then
        return mattata.edit_message_text(
            edited_message.chat.id,
            edited_message.original_message_id,
            exec.help
        )
    end
    mattata.send_chat_action(edited_message.chat.id)
    return mattata.edit_message_text(
        edited_message.chat.id,
        edited_message.original_message_id,
        'Please select the language you would like to execute your code in:',
        'html',
        true,
        exec.get_keyboard(edited_message.from.id)
    )
end

function exec:on_message(message)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            exec.help
        )
    end
    mattata.send_chat_action(message.chat.id)
    return mattata.send_message(
        message,
        'Please select the language you would like to execute your code in:',
        'html',
        true,
        false,
        message.message_id,
        exec.get_keyboard(message.from.id)
    )
end

return exec