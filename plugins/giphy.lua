local giphy = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function giphy:init(configuration)
	giphy.arguments = 'gif <query>'
	giphy.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('gif').table
	giphy.inlineCommands = giphy.commands
	giphy.help = configuration.commandPrefix .. 'gif <query> - Searches Giphy for the given query and returns a random result.'
end

function giphy:onInlineCallback(inline_query, configuration)
	local input = inline_query.query:gsub('/gif ', '')
	local jstr = HTTPS.request(configuration.apis.giphy .. URL.escape(input) .. '&api_key=dc6zaTOxFJmzC')
	local jdat = JSON.decode(jstr)
	local results = '['
	local id = 1
	for n in pairs(jdat.data) do
		results = results .. '{"type":"mpeg4_gif","id":"' .. id .. '","mpeg4_url":"' .. jdat.data[n].images.original.mp4 .. '","thumb_url":"' .. jdat.data[n].images.fixed_height.url .. '","mpeg4_width":' .. jdat.data[n].images.original.width .. ',"mp4_height":' .. jdat.data[n].images.original.height .. '}'
		id = id + 1
		if n < #jdat.data then
			results = results .. ','
		end
	end
	local results = results .. ']'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function giphy:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, giphy.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTPS.request(configuration.apis.giphy .. URL.escape(input) .. '&api_key=dc6zaTOxFJmzC')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if not jdat.data[1] then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	end
	local random = math.random(1, #jdat.data)
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	mattata.sendDocument(message.chat.id, jdat.data[1].images.original.mp4)
end

return giphy