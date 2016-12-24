local yify = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function yify:init(configuration)
	yify.arguments = 'yify <query>'
	yify.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('yify').table
	yify.help = configuration.commandPrefix .. 'yify <query> - Searches Yify torrents for the given query.'
end

function yify.getResultCount(input)
	local jstr, res = https.request('https://yts.ag/api/v2/list_movies.json?query_term=' .. url.escape(input) .. '&limit=50')
	if res ~= 200 then
		return false
	end
	local jdat = json.decode(jstr)
	if not jdat.data.movies then
		return false
	end
	return #jdat.data.movies
end

function yify.getResult(input, result)
	local jstr, res = https.request('https://yts.ag/api/v2/list_movies.json?query_term=' .. url.escape(input))
	if res ~= 200 then
		return false, nil
	end
	local jdat = json.decode(jstr)
	if not jdat.data.movies then
		return false, nil
	end
	local buttons = {}
	for n = 1, #jdat.data.movies[result].torrents do
		table.insert(buttons, {
			text = jdat.data.movies[result].torrents[n].quality,
			url = jdat.data.movies[result].torrents[n].url
		})
	end
	local keyboard = {}
	keyboard.inline_keyboard = { buttons }
	local title = mattata.htmlEscape(jdat.data.movies[result].title_long):gsub(' %(%d%d%d%d%)$', '')
	if jdat.data.movies[result].large_cover_image then
		title = '<a href="' .. jdat.data.movies[result].large_cover_image .. '">' .. title .. '</a>'
	end
	local description = mattata.htmlEscape(jdat.data.movies[result].synopsis)
	if description:len() > 500 then
		description = description:sub(1, 500) .. '...'
	end
	return title .. '\n' .. jdat.data.movies[result].year .. ' | ' .. jdat.data.movies[result].rating .. '/10 | ' .. jdat.data.movies[result].runtime .. ' min\n\n<i>' .. description .. '</i>', keyboard
end

function yify:onCallbackQuery(callback_query, message, configuration)
	if callback_query.data:match('^results:(%d*)$') then
		local result = callback_query.data:match('^results:(%d*)$')
		local input = mattata.input(message.reply_to_message.text)
		local totalResults = yify.getResultCount(input)
		if tonumber(result) > tonumber(totalResults) then
			result = 1
		elseif tonumber(result) < 1 then
			result = tonumber(totalResults)
		end
		local output, keyboard = yify.getResult(input, tonumber(result))
		if not output then
			mattata.answerCallbackQuery(callback_query.id, 'An error occured!')
			return
		end
		local previousResult = 'yify:results:' .. math.floor(tonumber(result) - 1)
		local nextResult = 'yify:results:' .. math.floor(tonumber(result) + 1)
		local pages = {
			{ text = '◀️', callback_data = previousResult },
			{ text = result .. '/' .. totalResults, callback_data = 'yify:pages:' .. result .. ':' .. totalResults },
			{ text = '▶️', callback_data = nextResult }
		}
		table.insert(keyboard.inline_keyboard, pages)
		mattata.editMessageText(message.chat.id, message.message_id, output, 'HTML', true, json.encode(keyboard))
		return
	elseif callback_query.data:match('^pages:(.-):(.-)$') then
		local currentPage, totalPages = callback_query.data:match('^pages:(.-):(.-)$')
		mattata.answerCallbackQuery(callback_query.id, 'You are on page ' .. currentPage .. ' of ' .. totalPages .. '!')
		return
	end
end

function yify:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, yify.help, nil, true, false, message.message_id)
		return
	end
	local output, keyboard = yify.getResult(input, 1)
	if not output then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local pages = {
		{
			text = '◀️',
			callback_data = 'yify:results:0'
		},
		{
			text =  '1/' .. yify.getResultCount(input),
			callback_data = 'yify:pages:1:' .. yify.getResultCount(input)
		},
		{
			text = '▶️',
			callback_data = 'yify:results:2'
		}
	}
	table.insert(keyboard.inline_keyboard, pages)
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id, json.encode(keyboard))
end

return yify