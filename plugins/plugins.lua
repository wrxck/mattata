local plugins = {}
local mattata = require('mattata')
local redis = require('mattata-redis')
local JSON = require('dkjson')
local configuration = require('configuration')

function plugins:init(configuration)
	plugins.arguments = 'plugins <enable/disable> <plugin>'
	plugins.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('plugins').table
	plugins.help = configuration.commandPrefix .. 'plugins <enable/disable> <plugin> - enable or disable one of mattata\'s plugins in your group.'
end

function plugins:pluginExists(plugin)
	for k, v in pairs(configuration.plugins) do
		if v == plugin then
			return true
		end
	end
	return false
end

function plugins:isPluginEnabled(plugin, chat)
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

function plugins:enablePlugin(self, configuration, plugin)
	if plugins:isPluginEnabled(plugin) then
		return 'The plugin \'' .. plugin .. '\' is already enabled in this chat!'
	end
	if plugins:pluginExists(plugin) then
		redis:sadd('mattata:enabledPlugins', plugin)
		return plugins:reloadPlugins(self, configuration, plugin, 'enabled.')
	else
		return 'The plugin \'' .. plugin .. '\' doesn\'t exist!'
	end
end

function plugins:enablePluginInChat(message, plugin)
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

function plugins:disablePlugin(self, configuration, plugin)
	if not plugins:pluginExists(plugin) then
		return 'The plugin \'' .. plugin .. '\' doesn\'t exist!'
	end
	local k = plugins:isPluginEnabled(plugin)
	if not k then
		return 'The plugin \'' .. plugin .. '\' is already disabled in this chat!'
	end
	redis:srem('mattata:enabledPlugins', plugin)
	return plugins:reloadPlugins(self, configuration, plugin, 'disabled.')
end

function plugins:disablePluginInChat(message, plugin)
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

function plugins:onMessageReceive(message, configuration)
	if message.from.id == configuration.owner then
		if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'plugins globalenable %a+') then
			local plugin = message.text_lower:gsub(configuration.commandPrefix .. 'plugins globalenable ', '')
			local output = plugins:enablePlugin(self, configuration, plugin)
			mattata.sendMessage(message.chat.id, output, nil)
			return
		end
		if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'plugins globaldisable %a+') then
			local plugin = message.text_lower:gsub(configuration.commandPrefix .. 'plugins globaldisable ', '')
			local output = plugins:disablePlugin(self, configuration, plugin)
			mattata.sendMessage(message.chat.id, output, nil)
			return
		end
	end
	if message.chat.type ~= 'private' then
		if mattata.isGroupAdmin(message.chat.id, message.from.id) or message.from.id == configuration.owner then
			if not mattata.input(message.text) then
				mattata.sendMessage(message.chat.id, plugins.help, nil, true, false, message.message_id)
				return
			end
			if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'plugins enable %a+') then
				local plugin = message.text_lower:gsub(configuration.commandPrefix .. 'plugins enable ', '')
				local output = plugins:enablePluginInChat(message, plugin)
				mattata.sendMessage(message.chat.id, output, nil)
				return
			end
			if string.match(message.text_lower, '^' .. configuration.commandPrefix .. 'plugins disable %a+') and not string.match(message.text_lower, 'plugins$') and not string.match(message.text_lower, 'lua$') and not string.match(message.text_lower, 'help$') and not string.match(message.text_lower, 'control$') then
				local plugin = message.text_lower:gsub(configuration.commandPrefix .. 'plugins disable ', '')
				local output = plugins:disablePluginInChat(message, plugin)
				mattata.sendMessage(message.chat.id, output, nil)
				return
			end
		else
			mattata.sendMessage(message.chat.id, 'You don\'t have permission to use this command.', nil)
			return
		end
	else
		mattata.sendMessage(message.chat.id, 'You can\'t use this command in private chat!', nil)
		return
	end
end

return plugins
