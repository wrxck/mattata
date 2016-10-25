local xkcd = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')
xkcd.base_url = 'https://xkcd.com/info.0.json'
xkcd.strip_url = 'http://xkcd.com/%s/info.0.json'

function xkcd:init(configuration)
	xkcd.arguments = 'xkcd (i)'
	xkcd.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('xkcd', true).table
	xkcd.help = configuration.commandPrefix .. 'xkcd (i) - Returns the latest xkcd strip and its alt text. If a number is given, returns that number strip. If \'r\' is passed in place of a number, returns a random strip.'
	local jstr = HTTP.request(xkcd.base_url)
	if jstr then
		local data = JSON.decode(jstr)
		if data then
			xkcd.latest = data.num
		end
		
	end
	xkcd.latest = xkcd.latest
end

function xkcd:onMessageReceive(msg, configuration)
	local input = mattata.getWord(msg.text, 2)
	if input == 'r' then
		input = math.random(xkcd.latest)
	elseif tonumber(input) then
		input = tonumber(input)
	else
		input = xkcd.latest
	end
	local url = xkcd.strip_url:format(input)
	local jstr, res = HTTP.request(url)
	if res == 404 then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
	elseif res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
	else
		local data = JSON.decode(jstr)
		mattata.sendPhoto(msg.chat.id, data.img, data.num .. ' | ' .. data.safe_title .. ' | ' .. data.day .. '/' .. data.month .. '/' .. data.year, false, msg.message_id, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. 'https://xkcd.com/' .. data.num .. '"}]]}')
	end
end

return xkcd