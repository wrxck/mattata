local blacklist = {}
local mattata = require('mattata')
local redis = require('mattata-redis')
local configuration = require('configuration')

function blacklist:init(configuration) blacklist.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('blacklist'):command('whitelist').table end

function blacklist:reloadPlugins(self, configuration)
	for pac, _ in pairs(package.loaded) do if pac:match('^plugins%.') then package.loaded[pac] = nil end end
	package.loaded['mattata'] = nil
	package.loaded['configuration'] = nil
	mattata.init(self, configuration)
	return
end

function blacklist:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not mattata.isConfiguredAdmin(message.from.id) and not input then return end
	local arguments = message.text_lower:gsub('^' .. configuration.commandPrefix .. 'blacklist ', ''):gsub('^' .. configuration.commandPrefix .. 'whitelist ', '')
	if message.text_lower:match('^' .. configuration.commandPrefix .. 'blacklist') then
		if tonumber(arguments) == nil then mattata.sendMessage(message.chat.id, language.specifyBlacklistedUser, nil, true, false, message.message_id) return end
		local hash = 'blacklist:' .. message.text_lower:gsub(configuration.commandPrefix .. 'blacklist ', '')
		redis:set(hash, true)
		blacklist:reloadPlugins(self, configuration)
		mattata.sendMessage(message.chat.id, language.userNowBlacklisted, nil, true, false, message.message_id)
		return
	end
	if tonumber(arguments) == nil then mattata.sendMessage(message.chat.id, language.specifyBlacklistedUser, nil, true, false, message.message_id) return end
	local hash = 'blacklist:' .. message.text_lower:gsub(configuration.commandPrefix .. 'whitelist ', '')
	redis:del(hash)
	blacklist:reloadPlugins(self, configuration)
	mattata.sendMessage(message.chat.id, language.userNowWhitelisted, nil, true, false, message.message_id)
end

return blacklist