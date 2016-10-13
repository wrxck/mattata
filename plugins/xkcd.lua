local xkcd = {}
local HTTP = require('dependencies.socket.http')
local JSON = require('dependencies.dkjson')
local functions = require('functions')
xkcd.base_url = 'https://xkcd.com/info.0.json'
xkcd.strip_url = 'http://xkcd.com/%s/info.0.json'
function xkcd:init(configuration)
	xkcd.command = 'xkcd (i)'
	xkcd.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('xkcd', true).table
	xkcd.documentation = configuration.command_prefix .. 'xkcd (i) - Returns the latest xkcd strip and its alt text. If a number is given, returns that number strip. If \'r\' is passed in place of a number, returns a random strip.'
	local jstr = HTTP.request(xkcd.base_url)
	if jstr then
		local data = JSON.decode(jstr)
		if data then
			xkcd.latest = data.num
		end
	end
	xkcd.latest = xkcd.latest
end
function xkcd:action(msg, configuration)
	local input = functions.get_word(msg.text, 2)
	if input == 'r' then
		input = math.random(xkcd.latest)
	elseif tonumber(input) then
		input = tonumber(input)
	else
		input = xkcd.latest
	end
	local url = xkcd.strip_url:format(input)
	local jstr, code = HTTP.request(url)
	if code == 404 then
		functions.send_reply(msg, configuration.errors.results)
	elseif code ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
	else
		local data = JSON.decode(jstr)
		functions.send_photo(msg.chat.id, functions.download_to_file(data.img), data.num .. ' | ' .. functions.fix_utf8(data.safe_title) .. ' | ' .. data.day .. '/' .. data.month .. '/' .. data.year, msg.message_id, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. 'https://xkcd.com/' .. data.num .. '"}]]}')
	end
end
return xkcd