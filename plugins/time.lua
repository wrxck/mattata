local time = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function time:init(configuration)
	time.arguments = 'time'
	time.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('time').table
	time.help = configuration.commandPrefix .. 'time - Without any arguments, this will send the current date and time in UTC. Supports natural language queries as an argument, i.e. \'' .. configuration.commandPrefix .. 'time 5 hours before noon next friday\'. You can also say \'in PDT\', for example; and, if it\'s a supported time zone, it\'ll send the said information - adjusted to that time zone. The time zones which are currently supported are: GMT, MST, EST, AST, CST, MSK, EET and CET..'
end

function time:onChannelPostReceive(channel_post, configuration)
	local input = mattata.input(channel_post.text_lower)
	if not input then
		local str, res = HTTP.request('http://www.timeapi.org/utc/')
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	elseif input:match(' in mst$') then
		local input = input:gsub(' in mst', '')
		local str, res = HTTP.request('http://www.timeapi.org/mst/' .. input)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	elseif input:match(' in est$') then
		local input = input:gsub(' in est', '')
		local str, res = HTTP.request('http://www.timeapi.org/est/' .. input)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	elseif input:match(' in ast$') then
		local input = input:gsub(' in ast', '')
		local str, res = HTTP.request('http://www.timeapi.org/ast/' .. input)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	elseif input:match(' in cst$') then
		local input = input:gsub(' in cst', '')
		local str, res = HTTP.request('http://www.timeapi.org/cst/' .. input)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	elseif input:match(' in msk$') then
		local input = input:gsub(' in msk', '')
		local str, res = HTTP.request('http://www.timeapi.org/msk/' .. input)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	elseif input:match(' in eet$') then
		local input = input:gsub(' in eet', '')
		local str, res = HTTP.request('http://www.timeapi.org/eet/' .. input)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	elseif input:match(' in cet$') then
		local input = input:gsub(' in cet', '')
		local str, res = HTTP.request('http://www.timeapi.org/cet/' .. input)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	elseif input:match(' in gmt$') then
		local input = input:gsub(' in gmt', '')
		local str, res = HTTP.request('http://www.timeapi.org/gmt/' .. input)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	else
		local str, res = HTTP.request('http://www.timeapi.org/utc/' .. input)
		if res ~= 200 then
			mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
			return
		end
		mattata.sendMessage(channel_post.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, channel_post.message_id)
		return
	end
end

function time:onMessageReceive(message, configuration)
	local input = mattata.input(message.text_lower)
	if not input then
		local str, res = HTTP.request('http://www.timeapi.org/utc/')
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	elseif input:match(' in mst$') then
		local input = input:gsub(' in mst', '')
		local str, res = HTTP.request('http://www.timeapi.org/mst/' .. input)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	elseif input:match(' in est$') then
		local input = input:gsub(' in est', '')
		local str, res = HTTP.request('http://www.timeapi.org/est/' .. input)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	elseif input:match(' in ast$') then
		local input = input:gsub(' in ast', '')
		local str, res = HTTP.request('http://www.timeapi.org/ast/' .. input)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	elseif input:match(' in cst$') then
		local input = input:gsub(' in cst', '')
		local str, res = HTTP.request('http://www.timeapi.org/cst/' .. input)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	elseif input:match(' in msk$') then
		local input = input:gsub(' in msk', '')
		local str, res = HTTP.request('http://www.timeapi.org/msk/' .. input)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	elseif input:match(' in eet$') then
		local input = input:gsub(' in eet', '')
		local str, res = HTTP.request('http://www.timeapi.org/eet/' .. input)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	elseif input:match(' in cet$') then
		local input = input:gsub(' in cet', '')
		local str, res = HTTP.request('http://www.timeapi.org/cet/' .. input)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	elseif input:match(' in gmt$') then
		local input = input:gsub(' in gmt', '')
		local str, res = HTTP.request('http://www.timeapi.org/gmt/' .. input)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	else
		local str, res = HTTP.request('http://www.timeapi.org/utc/' .. input)
		if res ~= 200 then
			mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, '*Date:* ' .. str:gsub('-', '/'):gsub('T', ' *Time:* '):gsub('+', ' *Timezone:* +'), 'Markdown', true, false, message.message_id)
		return
	end
end

return time