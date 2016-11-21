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

function yify:onChannelPostReceive(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, yify.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://yts.ag/api/v2/list_movies.json?limit=1&query_term=' .. URL.escape(input))
    if res ~= 200 then
    	mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
    	return
    end
    local jdat = JSON.decode(jstr)
	if not jdat.data.movies then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
    end
	local buttons = ''
	for n = 1, #jdat.data.movies[1].torrents do
		local quality = jdat.data.movies[1].torrents[n].quality
		local button = {
			text = quality,
			url = jdat.data.movies[1].torrents[n].url
		}
		buttons = buttons .. button
		if n < #jdat.data.movies[1].torrents then
			buttons = buttons .. ','
		end
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			buttons
		}
	}
	mattata.sendMessage(channel_post.chat.id, '[' .. mattata.markdownEscape(jdat.data.movies[1].title_long) .. '](' .. jdat.data.movies[1].large_cover_image .. ')' .. '\n*' .. jdat.data.movies[1].year .. ' | ' .. jdat.data.movies[1].rating .. '/10 | ' .. jdat.data.movies[1].runtime .. ' min*\n\n_' .. mattata.markdownEscape(jdat.data.movies[1].synopsis) .. '_', 'Markdown', true, false, channel_post.message_id, JSON.encode(keyboard))
end

function yify:onMessageReceive(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, yify.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://yts.ag/api/v2/list_movies.json?limit=1&query_term=' .. URL.escape(input))
    if res ~= 200 then
    	mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
    	return
    end
    local jdat = JSON.decode(jstr)
	if not jdat.data.movies then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
    end
	local buttons = ''
	for n = 1, #jdat.data.movies[1].torrents do
		local quality = jdat.data.movies[1].torrents[n].quality
		local button = {
			text = quality,
			url = jdat.data.movies[1].torrents[n].url
		}
		buttons = buttons .. button
		if n < #jdat.data.movies[1].torrents then
			buttons = buttons .. ','
		end
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			buttons
		}
	}
	mattata.sendMessage(message.chat.id, '[' .. mattata.markdownEscape(jdat.data.movies[1].title_long) .. '](' .. jdat.data.movies[1].large_cover_image .. ')' .. '\n*' .. jdat.data.movies[1].year .. ' | ' .. jdat.data.movies[1].rating .. '/10 | ' .. jdat.data.movies[1].runtime .. ' min*\n\n_' .. mattata.markdownEscape(jdat.data.movies[1].synopsis) .. '_', 'Markdown', true, false, message.message_id, JSON.encode(keyboard))
end

return yify