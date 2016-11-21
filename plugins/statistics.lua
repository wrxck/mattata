local statistics = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function statistics:init(configuration)
	statistics.arguments = 'statistics'
end

function getUserName(user)
	if user.name then
		return user.name
	end
	local text = ''
	if user.first_name then
		text = user.first_name .. ' '
	end
	if user.last_name then
		text = text .. user.last_name
	end
	return text
end

function getUserMessages(id, chat)
	local info = {}
	local userHash = 'user:' .. id
	local user = redis:hgetall(userHash)
	local userMessagesHash = 'messages:' .. id .. ':' .. chat
	info.messages = tonumber(redis:get(userMessagesHash) or 0)
	info.name = getUserName(user)
	return info
end

function commaValue(amount)
	local formatted = amount
	while true do  
		formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end

function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function isempty(s)
	return s == nil or s == ''
end

function chatStatistics(chat)
	local hash = 'chat:' .. chat .. ':users'
	local users = redis:smembers(hash)
	local chatUserInfo = {}
	for i = 1, #users do
		local id = users[i]
		local user = getUserMessages(id, chat)
		table.insert(chatUserInfo, user)
	end
	local totalMessages = 0
	for n, user in pairs(chatUserInfo) do
		local messageCount = chatUserInfo[n].messages
		totalMessages = totalMessages + messageCount
	end
	table.sort(chatUserInfo, function(a, b) 
		if a.messages and b.messages then
			return a.messages > b.messages
		end
	end)
	local text = ''
	for k, v in pairs(chatUserInfo) do
    	local messageCount = v.messages
		local percent = tostring(round(messageCount / totalMessages * 100, 1))
    	text = text .. '*' .. v.name:gsub('%*', '\\*') .. ':* ' .. commaValue(messageCount) .. ' `[`' .. percent .. '%`]`\n'
	end
	if isempty(text) then
		return 'No messages have been sent in this group!'
	end
	local text = '*Message Statistics*\n\n' .. text .. '\n*Total messages sent*: ' .. commaValue(totalMessages)
	return text
end

function statistics:processMessage(message)
	if message.left_chat_member then
		local hash = 'chat:' .. message.chat.id .. ':users'
		local userIdLeft = message.left_chat_member.id
		redis:srem(hash, userIdLeft)
		return message
	end
	local hash = 'user:' .. message.from.id
	if message.from.name then
		redis:hset(hash, 'name', message.from.name)
	end
	if message.from.first_name then
		redis:hset(hash, 'first_name', message.from.first_name)
	end
	if message.from.last_name then
		redis:hset(hash, 'last_name', message.from.last_name)
	end
	if message.chat.type ~= 'private' then
		local hash = 'chat:' .. message.chat.id .. ':users'
		redis:sadd(hash, message.from.id)
	end
	local hash = 'messages:' .. message.from.id .. ':' .. message.chat.id
	redis:incr(hash)
	return message
end

function statistics:onMessageReceive(message)
	if message.chat.type ~= 'private' then
		mattata.sendMessage(message.chat.id, chatStatistics(message.chat.id), 'Markdown', true, false, message.message_id)
		return
	end
end

return statistics