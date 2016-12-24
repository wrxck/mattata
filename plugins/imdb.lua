local imdb = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function imdb:init(configuration)
	imdb.arguments = 'imdb <query>'
	imdb.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('imdb').table
	imdb.help = configuration.commandPrefix .. 'imdb <query> - Returns an IMDb entry.'
end

function imdb.getResultCount(input)
	local jstr, res = http.request('http://www.omdbapi.com/?s=' .. url.escape(input) .. '&page=1')
	if res ~= 200 then return false end
	local jdat = json.decode(jstr)
	if jdat.Response ~= 'True' then return false end
	return #jdat.Search
end

function imdb.getResult(input, result)
	local jstrSearch, resSearch = http.request('http://www.omdbapi.com/?s=' .. url.escape(input) .. '&page=1')
	if resSearch ~= 200 then return false end
	local jdatSearch = json.decode(jstrSearch)
	if jdatSearch.Response ~= 'True' then return false end
	local jstr, res = http.request('http://www.omdbapi.com/?i=' .. jdatSearch.Search[result].imdbID .. '&r=json&tomatoes=true')
	if res ~= 200 then return false end
	local jdat = json.decode(jstr)
	if jdat.Response ~= 'True' then return false end
	return '<a href="http://imdb.com/title/' .. jdatSearch.Search[result].imdbID .. '">' .. mattata.htmlEscape(jdat.Title) .. '</a> (' .. jdat.Year .. ')\n' .. jdat.imdbRating .. '/10 | ' .. jdat.Runtime .. ' | ' .. jdat.Genre .. '\n' .. '<i>' .. mattata.htmlEscape(jdat.Plot) .. '</i>'
end

function imdb:onCallbackQuery(callback_query, message, configuration)
	if callback_query.data:match('^results:(.-)$') then
		local result = callback_query.data:match('^results:(.-)$')
		local input = mattata.input(message.reply_to_message.text)
		local totalResults = imdb.getResultCount(input)
		if tonumber(result) > tonumber(totalResults) then result = 1 elseif tonumber(result) < 1 then result = tonumber(totalResults) end
		local output = imdb.getResult(input, tonumber(result))
		if not output then mattata.answerCallbackQuery(callback_query.id, 'An error occured!') return end
		local previousResult = 'imdb:results:' .. math.floor(tonumber(result) - 1)
		local nextResult = 'imdb:results:' .. math.floor(tonumber(result) + 1)
		local keyboard = {}
		keyboard.inline_keyboard = {{
			{ text = '◀️', callback_data = previousResult },
			{ text = result .. '/' .. totalResults, callback_data = 'imdb:results:' .. result .. ':' .. totalResults },
			{ text = '▶️', callback_data = nextResult }
		}}
		mattata.editMessageText(message.chat.id, message.message_id, output, 'HTML', true, json.encode(keyboard))
		return
	elseif callback_query.data:match('^pages:(.-):(.-)$') then
		local currentPage, totalPages = callback_query.data:match('^pages:(.-):(.-)$')
		mattata.answerCallbackQuery(callback_query.id, 'You are on page ' .. currentPage .. ' of ' .. totalPages .. '!')
		return
	end
end

function imdb:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, imdb.help, nil, true, false, message.message_id); return end
	local output = imdb.getResult(input, 1)
	if not output then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id); return end
	local keyboard = {}
	keyboard.inline_keyboard = {{
		{ text = '◀️', callback_data = 'imdb:results:0' },
		{ text =  '1/' .. imdb.getResultCount(input), callback_data = 'imdb:pages:1:' .. imdb.getResultCount(input) },
		{ text = '▶️', callback_data = 'imdb:results:2' }
	}}
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id, json.encode(keyboard))
end

return imdb