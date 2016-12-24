local id = {}
local mattata = require('mattata')
local json = require('dkjson')

function id:init(configuration)
	id.arguments = 'id <user/group/channel/bot>'
	id.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('id').table
	id.inlineCommands = id.commands
	id.help = configuration.commandPrefix .. 'id <user/group/channel/bot> - Sends the name, ID, and (if applicable) username for the given user/group/channel/bot. Input is also accepted via reply. This command can also be used inline!'
end

function id.resolveChat(message)
	local input = message.text or message.query
	input = mattata.input(input)
	local name = ''
	local id = ''
	local username = ''
	local chatTitle = ''
	local chatId = ''
	local chatUsername = ''
	local chatType = ''
	local chatAdminCount = ''
	local chatUserCount = ''
	local lastSeen = ''
	if message.reply_to_message then
		if message.reply_to_message.forward_from then message.reply_to_message.from = message.reply_to_message.forward_from end
		name = '<b>Name:</b> ' .. mattata.htmlEscape(message.reply_to_message.from.first_name)
		if message.reply_to_message.from.last_name then name = name .. ' ' .. mattata.htmlEscape(message.reply_to_message.from.last_name) end
		name = name .. '\n'
		id = '<b>User ID:</b> ' .. message.reply_to_message.from.id .. '\n'
		if message.reply_to_message.from.username then username = '<b>Username:</b> @' .. message.reply_to_message.from.username .. '\n' end
		if message.reply_to_message.forward_from_chat then message.reply_to_message.chat = message.reply_to_message.forward_from_chat end
		chatTitle = '<b>Chat title:</b> ' .. mattata.htmlEscape(message.reply_to_message.chat.title) .. '\n'
		chatId = '<b>Chat ID:</b> ' .. message.reply_to_message.chat.id .. '\n'
		if message.reply_to_message.chat.username then chatUsername = '<b>Chat username:</b> @' .. message.reply_to_message.chat.username .. '\n' end
		chatType = '<b>Chat type:</b> ' .. message.reply_to_message.chat.type .. '\n'
		return name .. id .. username .. chatTitle .. chatId .. chatUsername
	elseif input then
		if tonumber(input) == nil then if not input:match('^@') then input = '@' .. input end end
		local res = mattata.request('getChat', { chat_id = input }, nil, 'https://api.pwrtelegram.xyz/bot')
		if not res then return '\'' .. mattata.htmlEscape(input) .. '\' is an invalid username/ID.' end
		res = res.result
		if res.type == 'private' then
			name = '<b>Name:</b> ' .. mattata.htmlEscape(res.first_name)
			if res.last_name then name = name .. ' ' .. mattata.htmlEscape(res.last_name) end
			name = name .. '\n'
			if res.when then lastSeen = '<b>Last seen:</b> ' .. res.when .. '\n' end
			if res.username then username = '<b>Username:</b> @' .. res.username .. '\n' end
			id = '<b>ID:</b> ' .. res.id .. '\n'
		else
			chatType = '<b>Type:</b> ' .. res.type .. '\n'
			chatTitle = '<b>Title:</b> ' .. mattata.htmlEscape(res.title) .. '\n'
			if res.admins_count and res.admins_count ~= 0 then chatAdminCount = '<b>Admin count:</b> ' .. res.admins_count .. '\n' end
			if res.participants_count then chatUserCount = '<b>User count:</b> ' .. res.participants_count .. '\n' end
			if res.username then chatUsername = '<b>Username:</b> @' .. res.username .. '\n' end
			id = '<b>ID:</b> ' .. res.id .. '\n'
		end
		return name .. chatTitle .. chatType .. id .. chatId .. username .. lastSeen .. chatUserCount .. chatAdminCount
	else
		return 'Please specify a user, group or channel by stating their username or numerical ID as a command argument. Alternatively, you can reply to a message from, or forwarded from, the user, group or channel you\'d like to target.'
	end
end

function id:onInlineQuery(inline_query, configuration)
	local input = mattata.input(inline_query.query)
	local output = id.resolveChat(inline_query)
	local results = json.encode({{
		type = 'article',
		id = '1',
		title = input,
		description = 'Click to send the result!',
		input_message_content = { message_text = output, parse_mode = 'HTML' }
	}})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function id:onMessage(message) mattata.sendMessage(message.chat.id, id.resolveChat(message), 'HTML', true, false, message.message_id) end

return id