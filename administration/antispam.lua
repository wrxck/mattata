local antispam = {}
local mattata = require('mattata')
local redis = require('mattata-redis')
local configuration = require('configuration')

function antispam:init(configuration)
	antispam.arguments = 'antispam'
	antispam.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('antispam').table
	antispam.help = configuration.commandPrefix .. 'antispam - Toggles the anti-spam plugin in the chat.'
end

function antispam.isUserFlooding(message)
    local messages = redis:get('spam:' .. message.chat.id .. ':' .. message.from.id)
    if tonumber(messages) == nil then messages = 1 end
	redis:setex('spam:' .. message.chat.id .. ':' .. message.from.id, 5, tonumber(messages) + 1)
	if tonumber(messages) > 4 then return true end
	return false
end

function antispam:reloadPlugins(self)
	for pac, _ in pairs(package.loaded) do if pac:match('^plugins%.') then package.loaded[pac] = nil end end
	package.loaded['mattata'] = nil
	package.loaded['configuration'] = nil
	mattata.init(self, configuration)
	return true
end

function antispam:enablePlugin(message)
	local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
	if redis:hget(hash, 'antispam') == 'true' then
		redis:hset(hash, 'antispam', false)
		antispam:reloadPlugins(self)
		return 'The plugin \'antispam\' has been️ enabled in this chat.'
	end
	antispam:reloadPlugins(self)
	return false
end

function antispam:disablePlugin(message)
	local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
	if redis:hget(hash, 'antispam') ~= 'true' then
		redis:hset(hash, 'antispam', true)
		antispam:reloadPlugins(self)
		return 'The plugin \'antispam\' has been️ disabled in this chat.'
	end
	antispam:reloadPlugins(self)
	return false
end

function antispam.processMessage(self, message, configuration)
	if mattata.isGroupAdmin(message.chat.id, message.from.id) then return end
	local flooding = antispam.isUserFlooding(message)
	if not flooding then return true end
	local name = message.from.first_name
	if message.from.last_name then name = name .. ' ' .. message.from.last_name end
	local res = mattata.kickChatMember(message.chat.id, message.from.id)
	if not res then return end
	mattata.unbanChatMember(message.chat.id, message.from.id)
	local output = mattata.htmlEscape(self.info.first_name) .. ' [' .. self.info.id .. '] has kicked ' .. mattata.htmlEscape(message.from.first_name) .. ' [' .. message.from.id .. '] from ' .. mattata.htmlEscape(message.chat.title) .. ' [' .. message.chat.id .. '] for flooding the chat.'
	if configuration.logAdministrativeActions and configuration.administrationLog ~= '' then mattata.sendMessage(configuration.administrationLog, '<pre>' .. output .. '</pre>', 'HTML', true, false) end
	mattata.sendMessage(message.chat.id, '<pre>' .. output .. '</pre>', 'HTML', true, false)
	return false
end

function antispam:onMessage(message)
	if not mattata.isGroupAdmin(message.chat.id, message.from.id) and not mattata.isConfiguredAdmin(message.from.id) then return end
	local output = antispam:disablePlugin(message)
	if not output then output = antispam:enablePlugin(message) end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return antispam