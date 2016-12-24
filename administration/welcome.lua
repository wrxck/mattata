local welcome = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function welcome:init(configuration)
	welcome.arguments = 'welcome <value>'
	welcome.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('welcome').table
	welcome.help = configuration.commandPrefix .. 'welcome <value> - Sets the group\'s welcome message to the given value.\nUse $id as a placeholder for the user\'s numerical ID, $name as a placeholder for the user\'s name, $title as a placeholder for the group title, and $chatid as a placeholder for the group\'s numerical ID.\nHTML formatting is supported.'
end

function welcome.setWelcomeMessage(message, welcomeMessage)
	local hash = mattata.getRedisHash(message, 'welcomeMessage')
	if hash then redis:hset(hash, 'welcomeMessage', welcomeMessage); return 'Successfully set the new welcome message!' end
end

function welcome.getWelcomeMessage(message)
	local hash = mattata.getRedisHash(message, 'welcomeMessage')
	if hash then local welcomeMessage = redis:hget(hash, 'welcomeMessage'); if not welcomeMessage or welcomeMessage == 'false' then return false else return welcomeMessage end end
end

function welcome:onNewChatMember(message, configuration, language)
	local welcomeMessage = welcome.getWelcomeMessage(message)
	if not welcomeMessage then
		local joinChatMessages = language.joinChatMessages
		local output = joinChatMessages[math.random(#joinChatMessages)]
		mattata.sendMessage(message.chat.id, output:gsub('NAME', message.new_chat_member.first_name), nil, true, false, message.message_id)
	else
		local name = mattata.htmlEscape(message.new_chat_member.first_name)
		if message.new_chat_member.last_name then name = name .. ' ' .. mattata.htmlEscape(message.new_chat_member.last_name) end
		local title = mattata.htmlEscape(message.chat.title)
		welcomeMessage = welcomeMessage:gsub('%$id', message.new_chat_member.id):gsub('%$name', name):gsub('%$title', title):gsub('%$chatid', message.chat.id)
		mattata.sendMessage(message.chat.id, welcomeMessage, 'HTML', true, false, message.message_id)
	end
end

function welcome:onMessage(message, configuration)
	if message.chat.type == 'private' then
		mattata.sendMessage(message.chat.id, 'This command cannot be used in private chat!', nil, true, false, message.message_id)
		return
	elseif not mattata.isGroupAdmin(message.chat.id, message.from.id) and not mattata.isConfiguredAdmin(message.from.id) then
		mattata.sendMessage(message.chat.id, 'You must be an administrator in this chat to use this command.', nil, true, false, message.message_id)
		return
	end
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, welcome.help, nil, true, false) return end
	local validate = mattata.sendMessage(message.chat.id, input, 'HTML', true, false)
	if not validate then mattata.sendMessage(message.chat.id, 'There was an error formatting your message in HTML, please check the syntax and try again.', nil, true, false, message.message_id) return end
	mattata.editMessageText(message.chat.id, validate.result.message_id, welcome.setWelcomeMessage(message, input))
end

return welcome