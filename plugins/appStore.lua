local appStore = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')

function appStore:init(configuration)
	appStore.arguments = 'appstore <query>'
	appStore.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('appstore'):c('app').table
	appStore.help = configuration.commandPrefix .. 'appstore <query> - Returns the first app which iTunes returns for the given search query. Alias: ' .. configuration.commandPrefix .. 'app.'
end

function appStore.getAppInfo(jdat)
	local categoryList = {}
	for n in pairs(jdat.results[1].genres) do
		table.insert(categoryList, jdat.results[1].genres[n])
	end
	local rating = jdat.results[1].userRatingCount
	if rating == 1 then
		rating = '⭐️ 1 rating'
	elseif rating > 0 and rating ~= nil then
		rating = '⭐️ ' .. mattata.commaValue(rating) .. ' ratings (' .. jdat.results[1].averageUserRating .. ')'
	else
		rating = '⭐️ ' .. mattata.commaValue(rating) .. ' ratings'
	end
	return '<b>' .. mattata.htmlEscape(jdat.results[1].trackName) .. '</b> - v' .. jdat.results[1].version .. ' <code>[</code>' .. jdat.results[1].currentVersionReleaseDate:sub(9, 10) .. '/' .. jdat.results[1].currentVersionReleaseDate:sub(6, 7) .. '/' .. jdat.results[1].currentVersionReleaseDate:sub(1, 4) .. '<code>]</code>\n\n<i>' .. mattata.htmlEscape(jdat.results[1].description):sub(1, 250) .. '...</i>\n\n' .. table.concat(categoryList, ' <b>|</b> ') .. '\n' .. rating .. ' <b>|</b> iOS ' .. jdat.results[1].minimumOsVersion .. '+'
end

function appStore:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, appStore.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://itunes.apple.com/search?term=' .. URL.escape(input) .. '&lang=' .. configuration.language .. '&entity=software')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.resultCount == 0 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local keyboard = {}
		keyboard.inline_keyboard = {
		{
			{
				text = 'View on iTunes',
				url = jdat.results[1].trackViewUrl
			}
		}
	}
	mattata.sendMessage(channel_post.chat.id, appStore.getAppInfo(jdat), 'HTML', true, false, channel_post.message_id, JSON.encode(keyboard))
end

function appStore:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, appStore.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTPS.request('https://itunes.apple.com/search?term=' .. URL.escape(input) .. '&lang=' .. configuration.language .. '&entity=software')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.resultCount == 0 then
		mattata.sendMessage(message.chat.id, configuration.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
		keyboard.inline_keyboard = {
		{
			{
				text = 'View on iTunes',
				url = jdat.results[1].trackViewUrl
			}
		}
	}
	mattata.sendMessage(message.chat.id, appStore.getAppInfo(jdat), 'HTML', true, false, message.message_id, JSON.encode(keyboard))
end

return appStore