local time = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function time:init(configuration)
	time.command = 'time'
	time.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('time', true).table
	time.documentation = configuration.command_prefix .. 'time - Without any arguments, this will send the current date and time in UTC. Supports natural language queries as an argument, i.e. \'' .. configuration.command_prefix .. 'time 5 hours before noon next friday\'. You can also say \'in PDT\', for example; and, if it\'s a supported time zone, it\'ll send the said information - adjusted to that time zone. The time zones which are currently supported are: GMT, MST, EST, AST, CST, MSK, EET and CET..'
end
function time:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		local url = configuration.time_api
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	elseif string.match(input, 'in MST') or string.match(input, 'in mst') then
		local input = input:gsub('in MST', ''):gsub(' in mst', '')
		local url = 'http://www.timeapi.org/mst/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	elseif string.match(input, 'in EST') or string.match(input, 'in est') then
		local input = input:gsub('in EST', ''):gsub(' in est', '')
		local url = 'http://www.timeapi.org/est/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	elseif string.match(input, 'in AST') or string.match(input, 'in ast') then
		local input = input:gsub('in AST', ''):gsub(' in ast', '')
		local url = 'http://www.timeapi.org/ast/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	elseif string.match(input, 'in CST') or string.match(input, 'in cst') then
		local input = input:gsub('in CST', ''):gsub(' in cst', '')
		local url = 'http://www.timeapi.org/cst/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	elseif string.match(input, 'in MSK') or string.match(input, 'in msk') then
		local input = input:gsub('in MSK', ''):gsub(' in msk', '')
		local url = 'http://www.timeapi.org/msk/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	elseif string.match(input, 'in EET') or string.match(input, 'in eet') then
		local input = input:gsub('in EET', ''):gsub(' in eet', '')
		local url = 'http://www.timeapi.org/eet/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	elseif string.match(input, 'in CET') or string.match(input, 'in cet') then
		local input = input:gsub('in CET', ''):gsub(' in cet', '')
		local url = 'http://www.timeapi.org/cet/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	elseif string.match(input, 'in GMT') or string.match(input, 'in gmt') then
		local input = input:gsub('in GMT', ''):gsub(' in gmt', '')
		local url = 'http://www.timeapi.org/gmt/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	elseif string.match(input, 'in UTC') or string.match(input, 'in utc') then
		local input = input:gsub('in UTC', ''):gsub(' in utc', '')
		local url = 'http://www.timeapi.org/utc/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	else
		local url = 'http://www.timeapi.org/utc/' .. input
		local time, res = HTTP.request(url)
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		else
			functions.send_reply(msg, '*Date:* ' .. time:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), true)
			return
		end
	end
end
return time