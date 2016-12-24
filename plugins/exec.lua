local exec = {}
local mattata = require('mattata')
local http = require('socket.http')
local ltn12 = require('ltn12')
local multipart = require('multipart-post')
local json = require('dkjson')

function exec:init(configuration)
	exec.arguments = 'exec <language> <code>'
	exec.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('exec').table
	exec.help = configuration.commandPrefix .. 'exec <language> <code> - Executes the specified code in the given language and returns the output.'
end

function exec.getLangArgs(language)
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
	else return false end
end

function exec:onMessage(message, configuration, language)
	local input = mattata.input(message.text_lower)
	if not input then mattata.sendMessage(message.chat.id, exec.help, 'Markdown', true, false, message.message_id) return end
	mattata.sendChatAction(message.chat.id, 'typing')
	local language = mattata.getWord(input, 1)
	local code = message.text:gsub(configuration.commandPrefix .. 'exec ' .. language .. ' ', ''):gsub(configuration.commandPrefix .. 'exec ' .. language, '')
	local args = exec.getLangArgs(language)
	if not args then args = '' end
	local parameters = { LanguageChoice = language, Program = code, Input = 'stdin', CompilerArgs = args }
	local response = {}
	local body, boundary = multipart.encode(parameters)
	local jstr, res = http.request{
		url = 'http://rextester.com/rundotnet/api/',
		method = 'POST',
		headers = { ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary, ['Content-Length'] = #body },
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	}
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(response[1])
	local warnings, errors, result, stats
	if jdat.Warnings then warnings = '*Warnings*:\n' .. mattata.markdownEscape(jdat.Warnings) .. '\n' else warnings = '' end
	if jdat.Errors then errors = '*Errors*:\n' .. mattata.markdownEscape(jdat.Errors) .. '\n' else errors = '' end
	if jdat.Result then result = '*Result*\n' .. mattata.markdownEscape(jdat.Result) .. '\n' else result = '' end
	if jdat.Stats then stats = '*Statistics*\n*»* ' .. jdat.Stats:gsub(', ', '\n*»* '):gsub('cpu', 'CPU'):gsub('memory', 'Memory'):gsub('absolute', 'Absolute'):gsub(',', '.') else stats = '' end
	local output = warnings .. errors .. result .. stats
	res = mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
end

return exec