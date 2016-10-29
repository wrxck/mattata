local bing = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local mime = require('mime')
local ltn12 = require('ltn12')
local JSON = require('dkjson')
local mattata = require('mattata')

function bing:init(configuration)
	bing.arguments = 'bing <query>'
	bing.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('bing').table
	bing.help = configuration.commandPrefix .. 'bing <query> - Returns Bing\'s top 4 search results for the given query.'
end

function bing:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, bing.help, nil, true, false, msg.message_id, nil)
		return
	end
	local url = configuration.apis.bing .. URL.escape(input) .. '\'&$format=json'
	local body = {}
	local _, res = HTTPS.request({
		url = url,
		headers = {
			['Authorization'] = 'Basic ' .. mime.b64(':' .. configuration.keys.bing)
		},
		sink = ltn12.sink.table(body),
	})
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(table.concat(body))
	local limit = msg.chat.type == 'private' and configuration.bing.maximumResultsPrivate or configuration.bing.maximumResultsGroup
	if limit > #jdat.d.results and #jdat.d.results or limit == 0 then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	end
	local results = {}
	for i = 1, limit do
		table.insert(results, string.format(
			'<b>»</b> <a href="%s">%s</a>',
			mattata.htmlEscape(jdat.d.results[i].Url),
			mattata.htmlEscape(jdat.d.results[i].Title)
		))
	end
	mattata.sendMessage(msg.chat.id, string.format('%s', table.concat(results, '\n')), 'HTML', true, false, msg.message_id, nil)
end

return bing