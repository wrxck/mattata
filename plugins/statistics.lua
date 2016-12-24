local statistics = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function statistics:init(configuration)
	statistics.arguments = 'statistics'
	statistics.help = configuration.commandPrefix .. 'statistics - View statistics about the chat you are in. Only the top 10 most talkative users are listed.'
end

function statistics.getUserName(user)
	if user.name then return user.name end
	local text = ''
	if user.first_name then text = user.first_name .. ' ' end
	if user.last_name then text = text .. user.last_name end
	return text
end

function statistics.getUserMessages(id, chat)
	local info = {}
	local userHash = 'user:' .. id
	local user = redis:hgetall(userHash)
	local userMessagesHash = 'messages:' .. id .. ':' .. chat
	info.messages = tonumber(redis:get(userMessagesHash) or 0)
	info.name = statistics.getUserName(user)
	return info
end

function statistics.chatStatistics(chat, title, total)
	local hash = 'chat:' .. chat .. ':users'
	local users = redis:smembers(hash)
	local chatUserInfo = {}
	for i = 1, #users do
		local id = users[i]
		local user = statistics.getUserMessages(id, chat)
		table.insert(chatUserInfo, user)
	end
	table.sort(chatUserInfo, function(a, b) if a.messages and b.messages then return a.messages > b.messages end end)
	local totalMessages = 0
	for n, user in pairs(chatUserInfo) do
		local messageCount = chatUserInfo[n].messages
		totalMessages = totalMessages + messageCount
	end
	local text = ''
	local output = {}
	for i = 1, 10 do table.insert(output, chatUserInfo[i]) end
	for k, v in pairs(output) do
    	local messageCount = v.messages
		local percent = tostring(mattata.round(messageCount / totalMessages * 100, 1))
    	text = text .. mattata.htmlEscape(v.name) .. ': <b>' .. mattata.commaValue(messageCount) .. '</b> [' .. percent .. '%]\n'
	end
	if text == nil or text == '' then return 'No messages have been sent in this chat!' end
	return '<b>Statistics for:</b> ' .. mattata.htmlEscape(title) .. '\n\n' .. text .. '\n<b>Total messages sent:</b> ' .. mattata.commaValue(total)
end

function statistics:processMessage(message)
	if message.left_chat_member then
		local hash = 'chat:' .. message.chat.id .. ':users'
		local userIdLeft = message.left_chat_member.id
		redis:srem(hash, userIdLeft)
		return message
	end
	local hash = 'user:' .. message.from.id
	if message.from.name then redis:hset(hash, 'name', message.from.name) end
	if message.from.first_name then redis:hset(hash, 'first_name', message.from.first_name) end
	if message.from.last_name then redis:hset(hash, 'last_name', message.from.last_name) end
	if message.chat.type ~= 'private' then
		local hash = 'chat:' .. message.chat.id .. ':users'
		redis:sadd(hash, message.from.id)
	end
	local hash = 'messages:' .. message.from.id .. ':' .. message.chat.id
	redis:incr(hash)
	return message
end

function statistics:onMessage(message)
	if message.chat.type == 'private' then return end
	mattata.sendMessage(message.chat.id, statistics.chatStatistics(message.chat.id, message.chat.title, message.message_id), 'HTML', true, false, message.message_id)
end

return statistics