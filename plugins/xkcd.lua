local xkcd = {}
local mattata = require('mattata')
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

xkcd.baseUrl = 'https://xkcd.com/info.0.json'
xkcd.stripUrl = 'http://xkcd.com/%s/info.0.json'

function xkcd:init(configuration)
	xkcd.arguments = 'xkcd <i>'
	xkcd.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('xkcd').table
	xkcd.help = configuration.commandPrefix .. 'xkcd <i> - Returns the latest xkcd strip and its alt text. If a number is given, returns that number strip. If \'r\' is passed in place of a number, returns a random strip.'
	local jstr = http.request(xkcd.baseUrl)
	if jstr then
		local jdat = json.decode(jstr)
		if jdat then xkcd.latest = jdat.num end
	end
	xkcd.latest = xkcd.latest
end

function xkcd:onMessage(message, configuration, language)
	local input = mattata.getWord(message.text, 2)
	if not input then input = xkcd.latest end
	if input == 'r' then
		input = math.random(xkcd.latest)
	elseif tonumber(input) ~= nil then
		input = tonumber(input)
	else
		local link = 'https://www.google.co.uk/search?num=20&q=' .. url.escape('inurl:xkcd.com ' .. input)
		local search, code = https.request(link)
		local result = search:match('https?://xkcd[^/]+/(%d+)')
		if not result then input = xkcd.latest else input = result end
	end
	local url = xkcd.stripUrl:format(input)
	local jstr, res = http.request(url)
	if res == 404 then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	elseif res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = json.decode(jstr)
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'Read More', url = 'https://xkcd.com/' .. jdat.num }}}
	mattata.sendPhoto(message.chat.id, jdat.img, jdat.num .. ' | ' .. jdat.safe_title .. ' | ' .. jdat.day .. '/' .. jdat.month .. '/' .. jdat.year, false, message.message_id, json.encode(keyboard))
end

return xkcd