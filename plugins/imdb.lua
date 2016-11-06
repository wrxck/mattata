--[[

    Based on imdb.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local imdb = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function imdb:init(configuration)
	imdb.arguments = 'imdb <query>'
	imdb.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('imdb').table
	imdb.help = configuration.commandPrefix .. 'imdb <query> - Returns an IMDb entry.'
end

function imdb:onMessageReceive(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, imdb.help, nil, true, false, message.message_id, nil)
		return
	end
	local url = configuration.apis.imdb .. URL.escape(input)
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.Response ~= 'True' then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id, nil)
		return
	end
	local output = '*' .. jdat.Title .. ' (' .. jdat.Year .. ')*\n'
	output = output .. jdat.imdbRating .. '/10 | ' .. jdat.Runtime .. ' | ' .. jdat.Genre .. '\n'
	output = output .. '_' .. jdat.Plot .. '_\n'
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, nil, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. 'http://imdb.com/title/' .. jdat.imdbID .. '"}]]}')
end

return imdb