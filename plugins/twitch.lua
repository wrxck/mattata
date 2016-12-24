local twitch = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local configuration = require('configuration')

function twitch:init(configuration)
	twitch.arguments = 'twitch <query>'
	twitch.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('twitch').table
	twitch.help = configuration.commandPrefix .. 'twitch <query> - Searches Twitch for streams matching the given query.'
end

function twitch.getResultCount(input)
	local jstr, res = https.request('https://api.twitch.tv/kraken/search/streams?q=' .. url.escape(input) .. '&client_id=' .. configuration.keys.twitch)
	if res ~= 200 then return 0 end
	local jdat = json.decode(jstr)
	if jdat._total == 0 then return 0 end
	return #jdat.streams
end

function twitch.getResult(input, n)
	local jstr, res = https.request('https://api.twitch.tv/kraken/search/streams?q=' .. url.escape(input) .. '&client_id=' .. configuration.keys.twitch)
	if res ~= 200 then return false end
	local jdat = json.decode(jstr)
	if jdat._total == 0 then return false end
	local output = ''
	if jdat.streams[n].channel.url and jdat.streams[n].channel.display_name then
		output = output .. '<a href="' .. jdat.streams[n].channel.url .. '">' .. mattata.htmlEscape(jdat.streams[n].channel.display_name) .. '</a>\n'
	end
	if jdat.streams[n].channel.game then
		output = output .. '🎮 ' .. mattata.htmlEscape(jdat.streams[n].channel.game) .. '\n'
	end
	if jdat.streams[n].viewers then
		output = output .. '👁 ' .. mattata.commaValue(tostring(jdat.streams[n].viewers)) .. '\n'
	end
	if jdat.streams[n].video_height then
		output = output .. '🖥 ' .. jdat.streams[n].video_height .. 'p'
		if jdat.streams[n].average_fps then output = output .. ', ' .. mattata.round(jdat.streams[n].average_fps) .. ' FPS' end
	end
	return output
end

function twitch:onCallbackQuery(callback_query, message, configuration)
	if callback_query.data:match('^results:(%d*)$') then
		local result = callback_query.data:match('^results:(%d*)$')
		local input = mattata.input(message.reply_to_message.text)
		local totalResults = twitch.getResultCount(input)
		if tonumber(result) > tonumber(totalResults) then result = 1 elseif tonumber(result) < 1 then result = tonumber(totalResults) end
		local output = twitch.getResult(input, tonumber(result))
		if not output then
			mattata.answerCallbackQuery(callback_query.id, 'The requested stream isn\'t available anymore!')
			return
		end
		local previousResult = 'twitch:results:' .. math.floor(tonumber(result) - 1)
		local nextResult = 'twitch:results:' .. math.floor(tonumber(result) + 1)
		local keyboard = {}
		keyboard.inline_keyboard = {{
				{ text = '◀️', callback_data = previousResult },
				{ text = result .. '/' .. totalResults, callback_data = 'twitch:pages:' .. result },
				{ text = '▶️', callback_data = nextResult }
		}}
		mattata.editMessageText(message.chat.id, message.message_id, output, 'HTML', true, json.encode(keyboard))
		return
	elseif callback_query.data:match('^pages:(.-):(.-)$') then
		local current, total = callback_query.data:match('^pages:(.-):(.-)$')
		mattata.answerCallbackQuery(callback_query.id, string.format('You are on page %s of %s!', current, total))
		return
	end
end

function twitch:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, twitch.help, nil, true, false, message.message_id)
		return
	end
	local output = twitch.getResult(input, 1)
	if not output then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {{
		{ text = '◀️', callback_data = 'twitch:results:0' },
		{ text = '1/' .. twitch.getResultCount(input), callback_data = 'twitch:pages:1:' .. twitch.getResultCount(input) },
		{ text = '▶️', callback_data = 'twitch:results:2' }
	}}
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id, json.encode(keyboard))
end

return twitch