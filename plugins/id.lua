local id = {}
local mattata = require('mattata')
local JSON = require('dkjson')

function id:init(configuration)
	id.arguments = 'id <user ID>'
	id.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('id').table
	id.inlineCommands = id.commands
	id.help = configuration.commandPrefix .. 'id <user ID> - Sends the name, ID, and (if applicable) username for the given user ID. Input is also accepted via reply. If no input is given, info about you is sent. This command can also be used inline!'
end

function id:onInlineQuery(inline_query, configuration)
	local name, id, username, title, members, output, input
	if not mattata.input(inline_query.query) then
		input = inline_query.from.id
	else
		input = mattata.input(inline_query.query)
	end
	if tonumber(input) == nil then
		output = 'Invalid user ID.'
	else
		local res = mattata.getChat(input)
		if res then
			name = res.result.first_name
			id = res.result.id
			if res.result.last_name then
				name = name .. ' ' .. res.result.last_name
			elseif res.result.username then
				username = res.result.username
				output = 'Name: ' .. name .. '\nID: ' .. id .. '\nUsername: @' .. username
			else
				output = 'Name: ' .. name .. '\nID: ' .. id
			end
		else
			output = 'I don\'t recognise that user ID.'
		end
	end
	local results = JSON.encode({
		{
			type = 'article',
			id = '1',
			title = input,
			description = output,
			input_message_content = {
				message_text = output
			}
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function id:onMessage(message)
	local name, id, username, title, members, output
	local input = mattata.input(message.text)
	if not input then
		if message.reply_to_message then
			if message.reply_to_message.forward_from then
				name = message.reply_to_message.forward_from.first_name
				id = message.reply_to_message.forward_from.id
				if message.reply_to_message.forward_from.last_name then
					name = name .. ' ' .. message.reply_to_message.forward_from.last_name
				elseif message.reply_to_message.forward_from.username then
					username = message.reply_to_message.forward_from.username
					output = 'Name: ' .. name .. '\nID: ' .. id .. '\nUsername: @' .. username
				else
					output = 'Name: ' .. name .. '\nID: ' .. id
				end
			else
				name = message.reply_to_message.from.first_name
				id = message.reply_to_message.from.id
				if message.reply_to_message.from.last_name then
					name = name .. ' ' .. message.reply_to_message.from.last_name
				elseif message.reply_to_message.from.username then
					username = message.reply_to_message.from.username
					output = 'Name: ' .. name .. '\nID: ' .. id .. '\nUsername: @' .. username
				else
					output = 'Name: ' .. name .. '\nID: ' .. id
				end
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
			elseif message.from.username then
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
			mattata.sendMessage(message.chat.id, 'Invalid user ID.', nil, true, false, message.message_id)
			return
		end
		local res = mattata.getChat(input)
		if res then
			name = res.result.first_name
			id = res.result.id
			if res.result.last_name then
				name = name .. ' ' .. res.result.last_name
			elseif res.result.username then
				username = res.result.username
				output = 'Name: ' .. name .. '\nID: ' .. id .. '\nUsername: @' .. username
			else
				output = 'Name: ' .. name .. '\nID: ' .. id
			end
		else
			output = 'I don\'t recognise that user ID.'
		end
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return id