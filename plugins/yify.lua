local yify = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local ltn12 = require('ltn12')
local JSON = require('dkjson')

function yify:init(configuration)
	yify.arguments = 'yify <query>'
	yify.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('yify').table
	yify.help = configuration.commandPrefix .. 'yify <query> - Searches Yify torrents for the given query.'
end

function yify:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, yify.help, nil, true, false, msg.message_id, nil)
		return
	end
	local jstr, res = HTTPS.request('https://yts.ag/api/v2/list_movies.json?limit=1&query_term=' .. URL.escape(input))
    local jdat = JSON.decode(jstr)
	if not jdat.data.movies then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
    end
	local movie = jdat.data.movies[1]
	local torrent = movie.torrents
	local keyboard_buttons = ''
	for n = 1, #torrent do
		local quality = torrent[n].quality
		keyboard_buttons = keyboard_buttons .. '{"text":"' .. quality .. '", "url":"' .. torrent[n].url .. '"}'
		if n < #torrent then
			keyboard_buttons = keyboard_buttons .. ','
		end
	end
	keyboard = '{"inline_keyboard":[[' .. keyboard_buttons .. ']]}'
	local title = '[' .. mattata.markdownEscape(movie.title_long) .. '](' .. movie.large_cover_image .. ')'
	local output = title .. '\n*' .. movie.year .. ' | ' .. movie.rating .. '/10 | ' .. movie.runtime .. ' min*\n\n_' .. mattata.markdownEscape(movie.synopsis) .. '_'
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, keyboard)
end

return yify