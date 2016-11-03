local time = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function time:init(configuration)
	time.arguments = 'time'
	time.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('time').table
	time.help = configuration.commandPrefix .. 'time - Without any arguments, this will send the current date and time in UTC. Supports natural language queries as an argument, i.e. \'' .. configuration.commandPrefix .. 'time 5 hours before noon next friday\'. You can also say \'in PDT\', for example; and, if it\'s a supported time zone, it\'ll send the said information - adjusted to that time zone. The time zones which are currently supported are: GMT, MST, EST, AST, CST, MSK, EET and CET..'
end

function time:onMessageReceive(message, configuration)
	local input = mattata.input(message.text_lower)
	if not input then
		local url = configuration.apis.time
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	elseif string.match(input, 'in mst') then
		local input = input:gsub(' in mst', '')
		local url = 'http://www.timeapi.org/mst/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	elseif string.match(input, 'in est') then
		local input = input:gsub(' in est', '')
		local url = 'http://www.timeapi.org/est/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	elseif string.match(input, 'in ast') then
		local input = input:gsub(' in ast', '')
		local url = 'http://www.timeapi.org/ast/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	elseif string.match(input, 'in cst') then
		local input = input:gsub(' in cst', '')
		local url = 'http://www.timeapi.org/cst/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	elseif string.match(input, 'in msk') then
		local input = input:gsub(' in msk', '')
		local url = 'http://www.timeapi.org/msk/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	elseif string.match(input, 'in eet') then
		local input = input:gsub(' in eet', '')
		local url = 'http://www.timeapi.org/eet/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	elseif string.match(input, 'in cet') then
		local input = input:gsub(' in cet', '')
		local url = 'http://www.timeapi.org/cet/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	elseif string.match(input, 'in gmt') then
		local input = input:gsub(' in gmt', '')
		local url = 'http://www.timeapi.org/gmt/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	elseif string.match(input, 'in utc') then
		local input = input:gsub(' in utc', '')
		local url = 'http://www.timeapi.org/utc/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	else
		local url = 'http://www.timeapi.org/utc/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
			return
		else
			mattata.sendMessage(message.chat.id, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id, nil)
			return
		end
	end
end

return time