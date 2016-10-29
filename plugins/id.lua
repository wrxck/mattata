local id = {}
local mattata = require('mattata')

function id:init()
	local configuration = require('configuration')
	id.arguments = 'id <user>'
	id.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('id').table
	id.inlineCommands = id.commands
	id.help = configuration.commandPrefix .. 'id <user> - Sends the name, ID, and (if applicable) username for the given user. Input is also accepted via reply. If no input is given, info about you is sent.'
end

function id:onInlineCallback(inline_query)
	local configuration = require('configuration')
	local name, id, username, title, members, output
	local input = mattata.input(inline_query.query)
	if tonumber(input) == nil then
		if not string.match(input, '@') then
			input = '@' .. input
		end
	end
	local res = mattata.getChat(input)
	if res then
		if res.result.title then
			output = 'Title: ' .. res.result.title .. '\nChat type: ' .. res.result.type:gsub('^%l', string.upper) .. '\nID: ' .. res.result.id
			if res.result.participants_count then
				output = output .. '\nMembers: ' .. res.result.participants_count
			elseif res.result.username then
				output = output .. '\nUsername: @' .. res.result.username
			end
		else
			name = res.result.first_name
			id = res.result.id
			if res.result.last_name then
				name = name .. ' ' .. res.result.last_name
			end
			if res.result.username then
				username = res.result.username
				output = 'Name: ' .. name .. '\nID: ' .. id .. '\nUsername: @' .. username
			else
				output = 'Name: ' .. name .. '\nID: ' .. id
			end
			if res.result.when then
				output = output .. '\nLast Seen: ' .. res.result.when
			end
		end
	else
		output = 'I don\'t recognise that username/ID.'
	end
	local results = '[{"type":"article","id":"1","title":"/id","description":"' .. output .. '","input_message_content":{"message_text":"' .. output .. '"}}]'
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function id:onMessageReceive(msg)
	local name, id, username, title, members, output
	local input = mattata.input(msg.text)
	if not input then
		if msg.reply_to_message then
			name = msg.reply_to_message.from.first_name
			id = msg.reply_to_message.from.id
			if msg.reply_to_message.from.last_name then
				name = name .. ' ' .. msg.reply_to_message.from.last_name
			end
			if msg.reply_to_message.from.username then
				username = msg.reply_to_message.from.username
				output = 'Name: ' .. name .. '\nID: ' .. id .. '\nUsername: @' .. username
			else
				output = 'Name: ' .. name .. '\nID: ' .. id
			end
			if msg.chat.type ~= 'private' then
				output = output .. '\n\nTitle: ' .. msg.chat.title .. '\nChat type: ' .. msg.chat.type:gsub('^%l', string.upper) .. '\nID: ' .. msg.chat.id
				if msg.chat.username then
					output = output .. '\nUsername: @' .. msg.chat.username
				end
			end
		else
			name = msg.from.first_name
			if msg.from.last_name then
				name = name .. ' ' .. msg.from.last_name
			end
			if msg.from.username then
				output = 'Name: ' .. name .. '\nID: ' .. msg.from.id .. '\nUsername: @' .. msg.from.username
			else
				output = 'Name: ' .. name .. '\nID: ' .. msg.from.id
			end
			if msg.chat.type ~= 'private' then
				output = output .. '\n\nTitle: ' .. msg.chat.title .. '\nChat type: ' .. msg.chat.type:gsub('^%l', string.upper) .. '\nID: ' .. msg.chat.id
				if msg.chat.username then
					output = output .. '\nUsername: @' .. msg.chat.username
				end
			end
		end
	else
		if tonumber(input) == nil then
			if not string.match(input, '@') then
				input = '@' .. input
			end
		end
		local res = mattata.getChat(input)
		if res then
			if res.result.title then
				output = 'Title: ' .. res.result.title .. '\nChat type: ' .. res.result.type:gsub('^%l', string.upper) .. '\nID: ' .. res.result.id
				if res.result.participants_count then
					output = output .. '\nMembers: ' .. res.result.participants_count
				end
				if res.result.username then
					output = output .. '\nUsername: @' .. res.result.username
				end
				mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
				return
			end
			name = res.result.first_name
			id = res.result.id
			if res.result.last_name then
				name = name .. ' ' .. res.result.last_name
			end
			if res.result.username then
				username = res.result.username
				output = 'Name: ' .. name .. '\nID: ' .. id .. '\nUsername: @' .. username
			else
				output = 'Name: ' .. name .. '\nID: ' .. id
			end
			if res.result.when then
				output = output .. '\nLast Seen: ' .. res.result.when
			end
		else
			output = 'I don\'t recognise that username/ID.'
		end
	end
	mattata.sendMessage(msg.chat.id, output, nil, true, false, msg.message_id, nil)
end

return id