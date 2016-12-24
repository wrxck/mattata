local youtube = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local configuration = require('configuration')

function youtube:init(configuration)
	youtube.arguments = 'youtube <query>'
	youtube.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('youtube'):command('yt').table
	youtube.help = configuration.commandPrefix .. 'youtube <query> - Sends the top results from YouTube for the given search query. Alias: ' .. configuration.commandPrefix .. 'yt.'
end

function youtube.getResultCount(input)
	local jstr, res = https.request('https://www.googleapis.com/youtube/v3/search?key=' .. configuration.keys.google .. '&type=video&part=snippet&q=' .. url.escape(input))
	if res ~= 200 then
		return 0
	end
	local jdat = json.decode(jstr)
	if jdat.pageInfo.totalResults == 0 then
		return 0
	end
	return #jdat.items
end

function youtube.getResult(input, n)
	local jstr, res = https.request('https://www.googleapis.com/youtube/v3/search?key=' .. configuration.keys.google .. '&type=video&part=snippet&q=' .. url.escape(input))
	if res ~= 200 then
		return false
	end
	local jdat = json.decode(jstr)
	if jdat.pageInfo.totalResults == 0 then
		return false
	end
	local jstrInfo, resInfo = https.request('https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics,contentDetails&key=' .. configuration.keys.google .. '&id=' .. jdat.items[n].id.videoId .. '&fields=items(id,snippet(publishedAt,channelTitle,localized(title,description)),statistics(viewCount,likeCount,dislikeCount,commentCount),contentDetails(duration,regionRestriction(blocked)))')
	if resInfo ~= 200 then
		return false
	end
	local jdatInfo = json.decode(jstrInfo)
	local output = ''
	output = output .. '<a href="https://www.youtube.com/watch?v=' .. jdat.items[n].id.videoId .. '">' .. mattata.htmlEscape(jdat.items[n].snippet.title) .. '</a>\n'
	if jdatInfo.items[1].snippet.channelTitle then
		output = output .. '👤 ' .. mattata.htmlEscape(jdatInfo.items[1].snippet.channelTitle) .. '\n'
	end
	if jdatInfo.items[1].statistics.viewCount then
		output = output .. '👁 ' .. mattata.commaValue(jdatInfo.items[1].statistics.viewCount) .. '\n'
	end
	if jdatInfo.items[1].statistics.commentCount then
		output = output .. '💬 ' .. mattata.commaValue(jdatInfo.items[1].statistics.commentCount) .. '\n'
	end
	if jdatInfo.items[1].statistics.likeCount then
		output = output .. '👍 ' .. mattata.commaValue(jdatInfo.items[1].statistics.likeCount) .. '\n'
	end
	if jdatInfo.items[1].statistics.dislikeCount then
		output = output .. '👎 ' .. mattata.commaValue(jdatInfo.items[1].statistics.dislikeCount) .. '\n'
	end
	return output
end

function youtube:onCallbackQuery(callback_query, message, configuration)
	if callback_query.data:match('^results:(%d*)$') then
		local result = callback_query.data:match('^results:(%d*)$')
		local input = message.reply_to_message.text:gsub('^' .. configuration.commandPrefix .. 'youtube ', ''):gsub('^' .. configuration.commandPrefix .. 'yt ', '')
		local totalResults = youtube.getResultCount(input)
		if tonumber(result) > tonumber(totalResults) then
			result = 1
		elseif tonumber(result) < 1 then
			result = tonumber(totalResults)
		end
		local output = youtube.getResult(input, tonumber(result))
		if not output then
			mattata.answerCallbackQuery(callback_query.id, 'An error occured!')
			return
		end
		local previousResult = 'youtube:results:' .. math.floor(tonumber(result) - 1)
		local nextResult = 'youtube:results:' .. math.floor(tonumber(result) + 1)
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{ text = '◀️', callback_data = previousResult },
				{ text = result .. '/' .. totalResults, callback_data = 'youtube:pages:' .. result .. ':' .. totalResults },
				{ text = '▶️', callback_data = nextResult }
			}
		}
		mattata.editMessageText(message.chat.id, message.message_id, output, 'HTML', true, json.encode(keyboard))
		return
	elseif callback_query.data:match('^pages:(.-):(.-)$') then
		local currentPage, totalPages = callback_query.data:match('^pages:(.-):(.-)$')
		mattata.answerCallbackQuery(callback_query.id, 'You are on page ' .. currentPage .. ' of ' .. totalPages .. '!')
		return
	end
end

function youtube:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, youtube.help, nil, true, false, message.message_id)
		return
	end
	local output = youtube.getResult(input, 1)
	if not output then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = '◀️',
				callback_data = 'youtube:results:0'
			},
			{
				text = '1/' .. youtube.getResultCount(input),
				callback_data = 'youtube:pages:1:' .. youtube.getResultCount(input)
			},
			{
				text = '▶️',
				callback_data = 'youtube:results:2'
			}
		}
	}
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id, json.encode(keyboard))
end

return youtube