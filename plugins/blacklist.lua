local blacklist = {}
local mattata = require('mattata')
local redis = require('mattata-redis')
local configuration = require('configuration')

function blacklist:init(configuration)
	blacklist.arguments = 'blacklist <user ID> | whitelist <user ID>'
	blacklist.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('blacklist'):c('whitelist').table
	blacklist.help = configuration.commandPrefix .. 'blacklist <user ID> - Prevent a user from using ' .. self.info.username .. ', permanently. ' .. configuration.commandPrefix .. 'whitelist <user ID> - Allow a blacklisted user to start using ' .. self.info.username .. ' again.'
end

function blacklist:reloadPlugins(self, configuration)
	for pac, _ in pairs(package.loaded) do
		if pac:match('^plugins%.') then
			package.loaded[pac] = nil
		end
	end
	package.loaded['mattata'] = nil
	package.loaded['configuration'] = nil
	mattata.init(self, configuration)
	return
end

function blacklist:onMessageReceive(message, configuration)
	if message.from.id ~= configuration.owner then
		return true
	end
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, blacklist.help, nil, true, false, message.message_id)
		return
	end
	if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'blacklist') then
		local hash = 'blacklist:' .. message.text_lower:gsub(configuration.commandPrefix .. 'blacklist ', '')
		redis:set(hash, true)
		blacklist:reloadPlugins(self, configuration)
		mattata.sendMessage(message.chat.id, 'That user is now blacklisted from using me.', nil, true, false, message.message_id)
		return
	end
	local hash = 'blacklist:' .. message.text_lower:gsub(configuration.commandPrefix .. 'whitelist ', '')
	redis:del(hash)
	blacklist:reloadPlugins(self, configuration)
	mattata.sendMessage(message.chat.id, 'That user is now able to use me again.', nil, true, false, message.message_id)
end

return blacklist
