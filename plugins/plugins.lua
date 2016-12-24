local plugins = {}
local mattata = require('mattata')
local redis = require('mattata-redis')
local json = require('dkjson')
local configuration = require('configuration')

function plugins:init(configuration)
	plugins.arguments = 'plugins <enable/disable> <plugin>'
	plugins.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('plugins').table
	plugins.help = configuration.commandPrefix .. 'plugins enable <plugin> - enable one of ' .. self.info.first_name .. '\'s plugins in your group.\n' .. configuration.commandPrefix .. 'plugins disable <plugin> - disable one of ' .. self.info.first_name .. '\'s plugins in your group.\n' .. configuration.commandPrefix .. 'plugins enable all - enable all of ' .. self.info.first_name .. '\'s non-core plugins in your group.\n' .. configuration.commandPrefix .. 'plugins disabl eall - disable all of' .. self.info.first_name ..  '\'s non-core plugins in your group.\n' .. configuration.commandPrefix .. 'plugins list - list all available plugins.'
end

local corePlugins = {
	'lua',
	'shell',
	'plugins',
	'control',
	'help',
	'ping',
	'setlang',
	'setloc'
}

function plugins:pluginExists(plugin)
	for k, v in pairs(corePlugins) do
		if plugin == v then
			return false
		end
	end
	for k, v in pairs(configuration.plugins) do
		if v == plugin then
			return true
		end
	end
	for k, v in pairs(configuration.administration) do
		if v == plugin then
			return true
		end
	end
	if plugin == 'ai' or plugin == 'telegram' then
		return true
	end
	return false
end

function plugins:disableAllAdministrationPlugins(message)
	for k, v in pairs(configuration.administration) do
		if plugins:pluginExists(v) then
			local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
			if redis:hget(hash, v) ~= 'true' then
				redis:hset(hash, v, true)
			end
		end
	end
	plugins:reloadPlugins(self)
	return 'Success! Use \'' .. configuration.commandPrefix .. 'plugins enable administration\' to enable all of my administration plugins, or use \'' .. configuration.commandPrefix .. 'plugins enable <plugin>\' to enable plugins individually.'
end

function plugins:enableAllAdministrationPlugins(message)
	for k, v in pairs(configuration.administration) do
		local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
		local disabled = redis:hget(hash, v)
		if disabled ~= 'false' then
			redis:hset(hash, v, false)
		end
	end
	plugins:reloadPlugins(self)
	return 'Success! Use \'' .. configuration.commandPrefix .. 'plugins disable administration\' to disable all of my administration plugins, or use \'' .. configuration.commandPrefix .. 'plugins disable <plugin>\' to disable plugins individually.'
end

function plugins:isPluginEnabled(self, plugin)
	for k, v in pairs(enabledPlugins) do
		if plugin == v then
			return k
		end
	end
	return false
end

function plugins:reloadPlugins(self, plugin, status)
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
	end
	return
end

function plugins:enablePlugin(message, plugin)
	if not plugins:pluginExists(plugin) then
		return 'The plugin \'' .. plugin .. '\' doesn\'t exist!'
	end
	local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
	if redis:hget(hash, plugin) == 'true' then
		redis:hset(hash, plugin, false)
		plugins:reloadPlugins(self)
		return 'The plugin \'' .. plugin .. '\' has been️ enabled in this chat.'
	end
	plugins:reloadPlugins(self)
	return 'The plugin \'' .. plugin .. '\' has already been enabled in this chat!'
end

function plugins:disablePlugin(message, plugin)
	if not plugins:pluginExists(plugin) then
		return 'The plugin \'' .. plugin .. '\' doesn\'t exist!'
	end
	local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
	if redis:hget(hash, plugin) ~= 'true' then
		redis:hset(hash, plugin, true)
		plugins:reloadPlugins(self)
		return 'The plugin \'' .. plugin .. '\' has been️ disabled in this chat.'
	end
	plugins:reloadPlugins(self)
	return 'The plugin \'' .. plugin .. '\' has already been disabled in this chat!'
end

function plugins:disableAllPlugins(message)
	for k, v in pairs(configuration.plugins) do
		if plugins:pluginExists(v) then
			local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
			if redis:hget(hash, v) ~= 'true' then
				redis:hset(hash, v, true)
			end
		end
	end
	plugins:reloadPlugins(self)
	return 'Success! Use \'' .. configuration.commandPrefix .. 'plugins enable all\' to enable all of my plugins, or use \'' .. configuration.commandPrefix .. 'plugins enable <plugin>\' to enable plugins individually.'
end

function plugins:listDisabledPlugins(message)
	local disabledPluginList = {}
	local disabledPluginCount = 0
	for k, v in pairs(configuration.plugins) do
		local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
		if redis:hget(hash, v) == 'true' then
			table.insert(disabledPluginList, v)
			disabledPluginCount = disabledPluginCount + 1
		end
	end
	if disabledPluginCount == 0 then
		return 'You haven\'t disabled any plugins in this chat!'
	end
	table.sort(disabledPluginList)
	return 'The following plugins are disabled in this chat:\n' .. table.concat(disabledPluginList, ', ')
end

function plugins:listEnabledPlugins(message)
	local enabledPluginList = {}
	local enabledPluginCount = 0
	for k, v in pairs(configuration.plugins) do
		local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
		if redis:hget(hash, v) ~= 'true' and plugins:pluginExists(v) then
			table.insert(enabledPluginList, v)
			enabledPluginCount = enabledPluginCount + 1
		end
	end
	if enabledPluginCount == 0 then
		return 'You haven\'t enabled any plugins in this chat!'
	end
	table.sort(enabledPluginList)
	return 'The following plugins are enabled in this chat:\n' .. table.concat(enabledPluginList, ', ')
end

function plugins:enableAllPlugins(message)
	for k, v in pairs(configuration.plugins) do
		local hash = 'chat:' .. message.chat.id .. ':disabledPlugins'
		local disabled = redis:hget(hash, v)
		if disabled ~= 'false' then
			redis:hset(hash, v, false)
		end
	end
	plugins:reloadPlugins(self)
	return 'Success! Use \'' .. configuration.commandPrefix .. 'plugins disable all\' to disable all plugins, or use \'' .. configuration.commandPrefix .. 'plugins disable <plugin>\' to disable plugins individually.'
end

function plugins:onMessage(message, configuration)
	if message.chat.type == 'private' then
		mattata.sendMessage(message.chat.id, 'This command cannot be used in private chat.', nil, true, false, message.message_id)
		return
	elseif not mattata.isGroupAdmin(message.chat.id, message.from.id) and not mattata.isConfiguredAdmin(message.from.id) then
		mattata.sendMessage(message.chat.id, 'You must be an administrator of this chat in order to be able to use this command!', nil, true, false, message.message_id)
		return
	end
	if message.text_lower:match('^' .. configuration.commandPrefix .. 'plugins$') or message.text_lower:match('^' .. configuration.commandPrefix .. 'plugins@' .. self.info.username .. '$') then
		mattata.sendMessage(message.chat.id, '<b>Hello, ' .. mattata.htmlEscape(message.from.first_name) .. '!</b>\n\nTo disable a specific plugin, use \'' .. configuration.commandPrefix .. 'plugins disable &lt;plugin&gt;\'. To enable a specific plugin, use \'' .. configuration.commandPrefix .. 'plugins enable &lt;plugin&gt;\'.\n\nFor the sake of convenience, you can enable all of my non-core plugins by using \'' .. configuration.commandPrefix .. 'plugins enable all\'. To disable all of my non-core plugins, you can use \'' .. configuration.commandPrefix .. 'plugins disable all\'.\n\nTo see a list of plugins you\'ve disabled, use \'' .. configuration.commandPrefix .. 'plugins disabled\'. For a list of plugins that can be toggled and haven\'t been disabled in this chat yet, use \'' .. configuration.commandPrefix .. 'plugins enabled\'.\n\nA list of all toggleable plugins can be viewed by using \'' .. configuration.commandPrefix .. 'plugins list\'.', 'HTML', true, false, message.message_id)
		return
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'plugins enable %a+$') then
		local plugin = message.text:gsub('^' .. configuration.commandPrefix .. 'plugins enable ', '')
		local output
		if plugin == 'all' then
			output = plugins:enableAllPlugins(message)
		elseif plugin == 'administration' then
			output = plugins:enableAllAdministrationPlugins(message)
		else
			output = plugins:enablePlugin(message, plugin)
		end
		mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'plugins disable %a+$') then
		local plugin = message.text:gsub('^' .. configuration.commandPrefix .. 'plugins disable ', '')
		local output
		if plugin:lower() == 'all' then
			output = plugins:disableAllPlugins(message)
		elseif plugin:lower() == 'administration' then
			output = plugins:disableAllAdministrationPlugins(message)
		else
			output = plugins:disablePlugin(message, plugin)
		end
		mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'plugins disabled$') then
		mattata.sendMessage(message.chat.id, plugins:listDisabledPlugins(message), nil, true, false, message.message_id)
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'plugins enabled$') then
		mattata.sendMessage(message.chat.id, plugins:listEnabledPlugins(message), nil, true, false, message.message_id)
	elseif message.text_lower:match('^' .. configuration.commandPrefix .. 'plugins list$') then
		local pluginList = {}
		for k, v in pairs(configuration.plugins) do
			if plugins:pluginExists(v) then
				table.insert(pluginList, v)
			end
		end
		table.sort(pluginList)
		mattata.sendMessage(message.chat.id, 'Toggleable plugins:\n' .. table.concat(pluginList, ', '), nil, true, false, message.message_id)
	end
end

return plugins