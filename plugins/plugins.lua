local plugins = {}
local mattata = require('mattata')
local redis = require('mattata-redis')
local JSON = require('dkjson')
local configuration = require('configuration')

function plugins:init(configuration)
	plugins.arguments = 'plugins <enable/disable> <plugin>'
	plugins.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('plugins').table
	plugins.help = configuration.commandPrefix .. 'plugins enable <plugin> - enable one of ' .. self.info.first_name .. '\'s plugins in your group.\n' .. configuration.commandPrefix .. 'plugins disable <plugin> - disable one of ' .. self.info.first_name .. '\'s plugins in your group.\n' .. configuration.commandPrefix .. 'plugins enableall - enable all of ' .. self.info.first_name .. '\'s non-core plugins in your group.\n' .. configuration.commandPrefix .. 'plugins disableall - disable all of' .. self.info.first_name ..  '\'s non-core plugins in your group.\n' .. configuration.commandPrefix .. 'plugins list - list all available plugins.'
end

function plugins:pluginExists(plugin)
	for k, v in pairs(configuration.plugins) do
		if v == plugin then
			return true
		end
	end
	for k, v in pairs(configuration.administrationPlugins) do
		if v == plugin then
			return true
		end
	end
	if plugin == 'ai' then
		return true
	end
	return false
end

function plugins:isPluginEnabled(self, plugin, chat)
	for k, v in pairs(enabledPlugins) do
		if plugin == v then
			return k
		end
	end
	return false
end

function plugins:reloadPlugins(self, configuration, plugin, status)
	for pac, _ in pairs(package.loaded) do
		if pac:match('^plugins%.') then
			package.loaded[pac] = nil
		end
	end
	package.loaded['mattata'] = nil
	package.loaded['configuration'] = nil
	mattata.init(self, configuration)
	if plugin then
		return 'The plugin \'' .. plugin .. '\' is now ' .. status
	else
		return
	end
end

function plugins:enablePlugin(message, plugin)
	if not plugins:pluginExists(plugin) then
		return 'The plugin \'' .. plugin .. '\' doesn\'t exist!'
	end
	local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
	local disabled = redis:hget(hash, plugin)
	if disabled == 'true' then
		redis:hset(hash, plugin, false)
		plugins:reloadPlugins(self, configuration)
		return 'The plugin \'' .. plugin .. '\' has been️ enabled in this chat.'
	else
		return 'The plugin \'' .. plugin .. '\' is already enabled in this chat!'
	end
end

function plugins:disablePlugin(message, plugin)
	if not plugins:pluginExists(plugin) then
		return 'The plugin \'' .. plugin .. '\' doesn\'t exist!'
	end
	local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
	local disabled = redis:hget(hash, plugin)
	if disabled ~= 'true' then
		redis:hset(hash, plugin, true)
		plugins:reloadPlugins(self, configuration)
		return 'The plugin \'' .. plugin .. '\' has been️ disabled in this chat.'
	else
		return 'The plugin \'' .. plugin .. '\' is already disabled in this chat!'
	end
end

function plugins:disableAllPlugins(message)
	for k, v in pairs(configuration.plugins) do
		if v ~= 'lua' and v ~= 'shell' and v ~= 'plugins' and v ~= 'control' and v ~= 'help' then
			local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
			local disabled = redis:hget(hash, v)
			if disabled ~= 'true' then
				redis:hset(hash, v, true)
			end
		end
	end
	plugins:reloadPlugins(self, configuration)
	return 'Success! Use ' .. configuration.commandPrefix .. 'plugins enableall to enable all plugins, or use ' .. configuration.commandPrefix .. 'plugins enable <plugin> to enable plugins individually.'
end

function plugins:enableAllPlugins(message)
	for k, v in pairs(configuration.plugins) do
		local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
		local disabled = redis:hget(hash, v)
		if disabled ~= 'false' then
			redis:hset(hash, v, false)
		end
	end
	plugins:reloadPlugins(self, configuration)
	return 'Success! Use ' .. configuration.commandPrefix .. 'plugins disableall to disable all plugins, or use ' .. configuration.commandPrefix .. 'plugins disable <plugin> to disable plugins individually.'
end

function plugins:onMessage(message, configuration)
	if message.chat.type ~= 'private' then
		if mattata.isGroupAdmin(message.chat.id, message.from.id) or mattata.isConfiguredAdmin(message.from.id) then
			if not mattata.input(message.text) then
				mattata.sendMessage(message.chat.id, plugins.help, nil, true, false, message.message_id)
				return
			end
			if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'plugins enable %a+') then
				mattata.sendMessage(message.chat.id, plugins:enablePlugin(message, message.text_lower:gsub(configuration.commandPrefix .. 'plugins enable ', '')), nil, true, false, message.message_id)
				return
			end
			if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'plugins disable %a+') and not string.match(message.text_lower, 'plugins$') and not string.match(message.text_lower, 'lua$') and not string.match(message.text_lower, 'help$') and not string.match(message.text_lower, 'control$') and not string.match(message.text_lower, 'bash$') and not string.match(message.text_lower, 'ping$') then
				mattata.sendMessage(message.chat.id, plugins:disablePlugin(message, message.text_lower:gsub(configuration.commandPrefix .. 'plugins disable ', '')), nil)
				return
			end
			if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'plugins disableall') then
				mattata.sendMessage(message.chat.id, plugins:disableAllPlugins(message), nil, true, false, message.message_id)
				return
			end
			if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'plugins enableall') then
				mattata.sendMessage(message.chat.id, plugins:enableAllPlugins(message), nil, true, false, message.message_id)
				return
			end
			if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'plugins list') then
				local pluginList = {}
				for k, v in pairs(configuration.plugins) do
					table.insert(pluginList, v)
				end
				table.sort(pluginList)
				mattata.sendMessage(message.chat.id, 'Available plugins:\n' .. table.concat(pluginList, ', '), nil, true, false, message.message_id)
				return
			end
		else
			mattata.sendMessage(message.chat.id, 'You don\'t have permission to use this command.', nil, true, false, message.message_id)
			return
		end
	else
		mattata.sendMessage(message.chat.id, 'You can\'t use this command in private chat!', nil, true, false, message.message_id)
		return
	end
end

return plugins