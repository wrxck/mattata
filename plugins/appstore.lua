local appstore = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function appstore:init(configuration)
	appstore.arguments = 'appstore <query>'
	appstore.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('appstore'):command('app').table
	appstore.help = configuration.commandPrefix .. 'appstore <query> - Returns the first app which iTunes returns for the given search query. Alias: ' .. configuration.commandPrefix .. 'app.'
end

function appstore.getAppInfo(jdat)
	local categories = {}
	for n in pairs(jdat.results[1].genres) do table.insert(categories, jdat.results[1].genres[n]) end
	local rating = jdat.results[1].userRatingCount
	if rating == 1 then rating = '⭐️ 1 rating'
	elseif rating > 0 and rating ~= nil then rating = '⭐️ ' .. mattata.commaValue(tostring(rating)) .. ' ratings (' .. jdat.results[1].averageUserRating .. ')'
	else rating = '⭐️ ' .. mattata.commaValue(tostring(rating)) .. ' ratings' end
	return '<b>' .. mattata.htmlEscape(jdat.results[1].trackName) .. '</b> - v' .. jdat.results[1].version .. ' <code>[</code>' .. jdat.results[1].currentVersionReleaseDate:sub(9, 10) .. '/' .. jdat.results[1].currentVersionReleaseDate:sub(6, 7) .. '/' .. jdat.results[1].currentVersionReleaseDate:sub(1, 4) .. '<code>]</code>\n\n<i>' .. mattata.htmlEscape(jdat.results[1].description):sub(1, 250) .. '...</i>\n\n' .. table.concat(categories, ' <b>|</b> ') .. '\n' .. rating .. ' <b>|</b> iOS ' .. jdat.results[1].minimumOsVersion .. '+'
end

function appstore:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, appstore.help, nil, true, false, message.message_id) return end
	local jstr, res = https.request('https://itunes.apple.com/search?term=' .. url.escape(input) .. '&lang=' .. configuration.language .. '&entity=software')
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(jstr)
	if jdat.resultCount == 0 then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id) return end
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'View on iTunes', url = jdat.results[1].trackViewUrl }}}
	mattata.sendMessage(message.chat.id, appstore.getAppInfo(jdat), 'HTML', true, false, message.message_id, json.encode(keyboard))
end

return appstore