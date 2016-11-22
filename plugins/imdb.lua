--[[

    Based on imdb.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local imdb = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function imdb:init(configuration)
	imdb.arguments = 'imdb <query>'
	imdb.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('imdb').table
	imdb.help = configuration.commandPrefix .. 'imdb <query> - Returns an IMDb entry.'
end

function imdb:onMessage(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, imdb.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://www.omdbapi.com/?t=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.Response ~= 'True' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Read more',
				url = 'http://imdb.com/title/' .. jdat.imdbID
			}
		}
	}
	mattata.sendMessage(message.chat.id, '*' .. jdat.Title .. ' (' .. jdat.Year .. ')*\n' .. jdat.imdbRating .. '/10 | ' .. jdat.Runtime .. ' | ' .. jdat.Genre .. '\n' .. '_' .. jdat.Plot .. '_\n', 'Markdown', true, false, message.message_id, nil, JSON.encode(keyboard))
end

return imdb