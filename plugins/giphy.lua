local giphy = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function giphy:init(configuration)
	giphy.arguments = 'gif <query>'
	giphy.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('gif'):command('giphy').table
	giphy.inlineCommands = giphy.commands
	giphy.help = configuration.commandPrefix .. 'gif <query> - Searches Giphy for the given query and returns a random result. Alias: ' .. configuration.commandPrefix .. 'giphy.'
end

function giphy:onInlineQuery(inline_query, configuration, language)
	local input = mattata.input(inline_query.query)
	local jstr = https.request('https://api.giphy.com/v1/gifs/search?q=' .. url.escape(input) .. '&api_key=dc6zaTOxFJmzC')
	local jdat = json.decode(jstr)
	local results = '['
	local id = 1
	for n in pairs(jdat.data) do
		results = results .. '{"type":"mpeg4_gif","id":"' .. id .. '","mpeg4_url":"' .. jdat.data[n].images.original.mp4 .. '","thumb_url":"' .. jdat.data[n].images.fixed_height.url .. '","mpeg4_width":' .. jdat.data[n].images.original.width .. ',"mp4_height":' .. jdat.data[n].images.original.height .. '}'
		id = id + 1
		if n < #jdat.data then results = results .. ',' end
	end
	local results = results .. ']'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function giphy:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, giphy.help, nil, true, false, message.message_id) return end
	local jstr, res = https.request('https://api.giphy.com/v1/gifs/search?q=' .. url.escape(input) .. '&api_key=dc6zaTOxFJmzC')
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(jstr)
	if not jdat.data[1] then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id) return end
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendDocument(message.chat.id, jdat.data[math.random(#jdat.data)].images.original.mp4)
end

return giphy