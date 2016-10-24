local exec = {}
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')
local HTTP = require('dependencies.socket.http')
local multipart = require('dependencies.multipart-post')
local ltn12 = require('dependencies.ltn12')

function exec:init(configuration)
	exec.arguments = 'exec <language> \\n <code>'
	exec.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('exec', true).table
	exec.help = configuration.commandPrefix .. 'exec <language> \\n <code> - Executes the specified code in the given language and returns the output. The code must be on a new line. Example: \n`' .. configuration.commandPrefix .. 'exec python3`\n`print(\'Hello, World!\')`'
end

function exec:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text_lower)
	if not input then
		mattata.sendMessage(msg.chat.id, exec.help, 'Markdown', true, false, msg.message_id, nil)
		return
	end
	local language = mattata.getWord(input, 1)
	local code = input:match('\n(.+)')
	local parameters = { LanguageChoice = language, Program = code, Input = 'stdin', CompilerArgs = '' }
	local response = {}
	local body, boundary = multipart.encode(parameters)
	local jstr, res = HTTP.request{
		url = 'http://rextester.com/rundotnet/api/',
		method = 'POST',
		headers = {
			['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
			['Content-Length'] = #body,
		},
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	}
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(response[1])
	local warnings, errors, result, stats
	if jdat.Warnings then
		warnings = '*Warnings:\n' .. jdat.Warnings .. '\n'
	else
		warnings = ''
	end
	if jdat.Errors then
		errors = '*Errors*:\n' .. jdat.Errors .. '\n'
	else
		errors = ''
	end
	if jdat.Result then
		result = '*Result*\n`' .. mattata.markdownEscape(jdat.Result) .. '`\n'
	else
		result = ''
	end
	if jdat.Stats then
		stats = '*Statistics\n»* ' .. jdat.Stats:gsub(':', ':`'):gsub(', ', '`\n*»* '):gsub('cpu', 'CPU'):gsub('memory', 'Memory'):gsub('absolute', 'Absolute'):gsub(',', '.') .. '`'
	else
		stats = ''
	end
	local output = warnings .. errors .. result .. stats
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
end

return exec