--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local exec = {}

local mattata = require('mattata')
local http = require('socket.http')
local ltn12 = require('ltn12')
local multipart = require('multipart-post')
local json = require('dkjson')

function exec:init(configuration)
    exec.arguments = 'exec <language> <code>'
    exec.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('exec').table
    exec.help = configuration.command_prefix .. 'exec <language> <code> - Executes the specified code in the given language and returns the output.'
end

function exec.get_language_arguments(language)
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
    return false
end

function exec:on_message(message, configuration, language)
    local input = mattata.input(message.text_lower)
    if not input then
        return mattata.send_reply(
            message,
            exec.help
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'typing'
    )
    local language = mattata.get_word(input)
    local code = message.text:gsub('^' .. configuration.command_prefix .. 'exec ' .. language .. ' ', ''):gsub('^' .. configuration.command_prefix .. 'exec ' .. language, '')
    local args = exec.get_language_arguments(language)
    if not args then
        args = ''
    end
    local parameters = {
        ['LanguageChoice'] = language,
        ['Program'] = code,
        ['Input'] = 'stdin',
        ['CompilerArgs'] = args
    }
    local response = {}
    local body, boundary = multipart.encode(parameters)
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
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(table.concat(response))
    local warnings = ''
    local errors = ''
    local result = ''
    local stats = ''
    if jdat.Warnings and jdat.Warnings ~= '' then
        warnings = '<b>Warnings</b>:\n' .. mattata.escape_html(jdat.Warnings) .. '\n'
    end
    if jdat.Errors and jdat.Errors ~= '' then
        errors = '<b>Errors</b>:\n' .. mattata.escape_html(jdat.Errors) .. '\n'
    end
    if jdat.Result and jdat.Result ~= '' then
        result = '<b>Result</b>\n' .. mattata.escape_html(jdat.Result) .. '\n'
    end
    if jdat.Stats and jdat.Stats ~= '' then
        stats = '<b>Statistics\n•</b> ' .. jdat.Stats:gsub(', ', '\n<b>•</b> '):gsub('cpu', 'CPU'):gsub('memory', 'Memory'):gsub('absolute', 'Absolute'):gsub(',', '.')
    end
    local output = warnings .. errors .. result .. stats
    return mattata.send_message(
        message.chat.id,
        output,
        'html'
    )
end

return exec