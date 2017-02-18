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

function exec:init()
    exec.commands = mattata.commands(
        self.info.username
    ):command('exec').table
    exec.help = [[/exec <language> <code> - Executes the specified code in the given language and returns the output.]]
end

function exec.get_arguments(language)
    if language == 'c_gcc' or language == 'gcc' or language == 'c' or language == 'c_clang' or language == 'clang' then
        return '-Wall -std=gnu99 -O2 -o a.out source_file.c'
    elseif language == 'cpp' or language == 'cplusplus_clang' or language == 'cpp_clang' or language == 'clangplusplus' or language == 'clang++' then
        return '-Wall -std=c++14 -O2 -o a.out source_file.cpp'
    elseif language == 'visual_cplusplus' or language == 'visual_cpp' or language == 'vc++' or language == 'msvc' then
        return 'source_file.cpp -o a.exe /EHsc /MD /I C:\\\\boost_1_60_0 /link /LIBPATH:C:\\\\boost_1_60_0\\\\stage\\\\lib'
    elseif language == 'visual_c' then
        return 'source_file.c -o a.exe'
    elseif language == 'd' then
        return 'source_file.d -ofa.out'
    elseif language == 'golang' or language == 'go' then
        return '-o a.out source_file.go'
    elseif language == 'haskell' then
        return '-o a.out source_file.hs'
    elseif language == 'objective_c' or language == 'objc' then
        return '-MMD -MP -DGNUSTEP -DGNUSTEP_BASE_LIBRARY=1 -DGNU_GUI_LIBRARY=1 -DGNU_RUNTIME=1 -DGNUSTEP_BASE_LIBRARY=1 -fno-strict-aliasing -fexceptions -fobjc-exceptions -D_NATIVE_OBJC_EXCEPTIONS -pthread -fPIC -Wall -DGSWARN -DGSDIAGNOSE -Wno-import -g -O2 -fgnu-runtime -fconstant-string-class=NSConstantString -I. -I /usr/include/GNUstep -I/usr/include/GNUstep -o a.out source_file.m -lobjc -lgnustep-base'
    end
    return ''
end

function exec.make_request(language, code)
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
            '<b>Result</b>\n' .. mattata.escape_html(jdat.Result)
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
    local language = input:match('^([%a%+]+) .-$') or input:match('^([%a%+]+)\n.-$')
    if not language then
        return mattata.edit_message_text(
            edited_message.chat.id,
            edited_message.original_message_id,
            'Please specify a language to execute your snippet of code in, using the syntax /exec <language> <code>.'
        )
    end
    language = language:lower()
    local code = input:match('^[%a%+]+ (.-)$') or input:match('^[%a%+]+\n(.-)$')
    if not code then
        return mattata.edit_message_text(
            edited_message.chat.id,
            edited_message.original_message_id,
            'Please specify a snippet of code to execute, using the syntax /exec <language> <code>.'
        )
    end
    local output = exec.make_request(language, code)
    if not output then
        return mattata.edit_message_text(
            edited_message.chat.id,
            edited_message.original_message_id,
            'Timed out.'
        )
    end
    return mattata.edit_message_text(
        edited_message.chat.id,
        edited_message.original_message_id,
        output,
        'html'
    )
end

function exec:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message,
            exec.help
        )
    end
    mattata.send_chat_action(message.chat.id)
    local language = input:match('^([%a%+]+) .-$') or input:match('^([%a%+]+)\n.-$')
    if not language then
        return mattata.send_reply(
            message,
            'Please specify a language to execute your snippet of code in, using the syntax /exec <language> <code>.'
        )
    end
    language = language:lower()
    local code = input:match('^[%a%+]+ (.-)$') or input:match('^[%a%+]+\n(.-)$')
    if not code then
        return mattata.send_reply(
            message,
            'Please specify a snippet of code to execute, using the syntax /exec <language> <code>.'
        )
    end
    local output = exec.make_request(language, code)
    if not output then
        return mattata.send_reply(
            message,
            'Timed out.'
        )
    end
    return mattata.send_reply(
        message,
        output,
        'html'
    )
end

return exec