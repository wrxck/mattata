local dictionary = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local json = require('dkjson')

function dictionary:init(configuration)
	dictionary.arguments = 'dictionary <word>'
	dictionary.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('dictionary'):command('define').table
	dictionary.help = configuration.commandPrefix .. 'dictionary <word> - Searches the Oxford Dictionary for the given word and returns the definition. Alias: ' .. configuration.commandPrefix .. 'define.'
end

function dictionary:onMessage(message, configuration, language)
	local input = mattata.input(message.text_lower)
	if not input then mattata.sendMessage(message.chat.id, dictionary.help, nil, true, false, message.message_id) return end
	local body = {}
	local _, res = https.request({
		url = 'https://od-api.oxforddictionaries.com/api/v1/entries/en/' .. url.escape(input),
		headers = { ['app_id'] = configuration.keys.dictionary.id, ['app_key'] = configuration.keys.dictionary.key },
		sink = ltn12.sink.table(body),
	})
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(table.concat(body))
	local word = jdat.results[1].word
	local results = #jdat.results[1].lexicalEntries
	if tonumber(results) > 5 then results = 5 end
	local definitions = {}
	for i = 1, results do table.insert(definitions, '• ' .. mattata.htmlEscape(jdat.results[1].lexicalEntries[i].entries[1].senses[1].definitions[1]:gsub(':$', ''):gsub('%.$', ''))) end
	local output = '<b>' .. mattata.htmlEscape(word) .. '</b>\n\n' .. table.concat(definitions, '\n')
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id)
end

return dictionary