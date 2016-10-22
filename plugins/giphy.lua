local giphy = {}
local HTTPS = require('dependencies.ssl.https')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function giphy:init(configuration)
	giphy.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('gif', true).table
	giphy.inlineCommands = giphy.commands
end

function giphy:onInlineCallback(inline_query, configuration)
	local jstr = HTTPS.request(configuration.apis.giphy .. inline_query.query:gsub('/gif ', '') .. '&api_key=dc6zaTOxFJmzC')
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

function giphy:onMessageReceive()
end

return giphy