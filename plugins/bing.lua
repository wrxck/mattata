local bing = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local mime = require('mime')
local json = require('dkjson')

function bing:init(configuration)
	assert(configuration.keys.bing, 'bing.lua requires an API key, and you haven\'t got one configured!')
	bing.arguments = 'bing <query>'
	bing.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('bing').table
	bing.help = configuration.commandPrefix .. 'bing <query> - Returns Bing\'s top search results for the given query.'
end

function bing:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, bing.help, nil, true, false, message.message_id) return end
	local body = {}
	local _, res = https.request({
		url = 'https://api.datamarket.azure.com/Data.ashx/Bing/Search/Web?Query=\'' .. url.escape(input) .. '\'&$format=json',
		headers = { ['Authorization'] = 'Basic ' .. mime.b64(':' .. configuration.keys.bing) },
		sink = ltn12.sink.table(body),
	})
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(table.concat(body))
	local limit = message.chat.type == 'private' and 8 or 4
	if limit > #jdat.d.results and #jdat.d.results or limit == 0 then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id) return end
	local results = {}
	for i = 1, limit do table.insert(results, '• <a href="' .. jdat.d.results[i].Url .. '">' .. mattata.htmlEscape(jdat.d.results[i].Title) .. '</a>') end
	mattata.sendMessage(message.chat.id, table.concat(results, '\n'), 'HTML', true, false, message.message_id)
end

return bing