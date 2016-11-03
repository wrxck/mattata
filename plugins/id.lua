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

function id:onMessageReceive(message)
	local name, id, username, title, members, output
	local input = mattata.input(message.text)
	if not input then
		if message.reply_to_message then
			name = message.reply_to_message.from.first_name
			id = message.reply_to_message.from.id
			if message.reply_to_message.from.last_name then
				name = name .. ' ' .. message.reply_to_message.from.last_name
			end
			if message.reply_to_message.from.username then
				username = message.reply_to_message.from.username
				output = 'Name: ' .. name .. '\nID: ' .. id .. '\nUsername: @' .. username
			else
				output = 'Name: ' .. name .. '\nID: ' .. id
			end
			if message.chat.type ~= 'private' then
				output = output .. '\n\nTitle: ' .. message.chat.title .. '\nChat type: ' .. message.chat.type:gsub('^%l', string.upper) .. '\nID: ' .. message.chat.id
				if message.chat.username then
					output = output .. '\nUsername: @' .. message.chat.username
				end
			end
		else
			name = message.from.first_name
			if message.from.last_name then
				name = name .. ' ' .. message.from.last_name
			end
			if message.from.username then
				output = 'Name: ' .. name .. '\nID: ' .. message.from.id .. '\nUsername: @' .. message.from.username
			else
				output = 'Name: ' .. name .. '\nID: ' .. message.from.id
			end
			if message.chat.type ~= 'private' then
				output = output .. '\n\nTitle: ' .. message.chat.title .. '\nChat type: ' .. message.chat.type:gsub('^%l', string.upper) .. '\nID: ' .. message.chat.id
				if message.chat.username then
					output = output .. '\nUsername: @' .. message.chat.username
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
				mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, nil)
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
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id, nil)
end

return id