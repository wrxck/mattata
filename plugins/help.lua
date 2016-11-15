local help = {}
local mattata = require('mattata')
local redis = require('mattata-redis')
local JSON = require('dkjson')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local helpText, users, userCount, pluginCount, punCount, trumpCount

function help:init()
	local configuration = require('configuration')
	local arguments_list = {}
	helpText = '• ' .. configuration.commandPrefix
	for _, plugin in ipairs(self.plugins) do
		if plugin.arguments then
			table.insert(arguments_list, plugin.arguments)
			if plugin.help then
				plugin.helpWord = mattata.getWord(plugin.arguments, 1)
			end
		end
	end
	table.insert(arguments_list, 'help <plugin>')
	table.sort(arguments_list)
	helpText = helpText .. table.concat(arguments_list, '\n• ' .. configuration.commandPrefix)
	help.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('help'):c('h'):c('start').table
	help.inlineCommands = { '^' .. '' .. '' }
	help.help = configuration.commandPrefix .. 'help <plugin> - Usage information for the given plugin. Alias: ' .. configuration.commandPrefix .. 'h.'
	users = self.users
end

function help:onInlineCallback(inline_query)
	local configuration = require('configuration')
	local results = '[{"type":"article","id":"1","title":"' .. configuration.commandPrefix .. 'id","description":"@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'id <username/ID> - Get information about a user/group","input_message_content":{"message_text":"Invalid syntax. Use @' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'id <username/ID>"}}'
	results = results .. ',{"type":"article","id":"2","title":"' .. configuration.commandPrefix .. 'ai","description":"@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'ai <text> - Talk to mattata","input_message_content":{"message_text":"Invalid syntax. Use @' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'ai <text>"}}'
	results = results .. ',{"type":"article","id":"3","title":"' .. configuration.commandPrefix .. 'apod","description":"@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'apod - Get the astronomical photo of the day","input_message_content":{"message_text":"Invalid syntax. Use @' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'apod"}}'
	results = results .. ',{"type":"article","id":"4","title":"' .. configuration.commandPrefix .. 'gif","description":"@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'gif <query> - Search for GIFs","input_message_content":{"message_text":"Invalid syntax. Use @' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'gif <query>"}}'
	results = results .. ',{"type":"article","id":"5","title":"' .. configuration.commandPrefix .. 'np","description":"@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'np <username> - Returns what you last listened to on last.fm","input_message_content":{"message_text":"Invalid syntax. Use @' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'np <username>"}}'
	results = results .. ',{"type":"article","id":"6","title":"' .. configuration.commandPrefix .. 'lyrics","description":"@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'lyrics <query> - Search for lyrics","input_message_content":{"message_text":"Invalid syntax. Use @' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'lyrics <query>"}}'
	results = results .. ',{"type":"article","id":"7","title":"' .. configuration.commandPrefix .. 'translate","description":"@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'translate <locale> <text> - Translate text","input_message_content":{"message_text":"Invalid syntax. Use @' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'translate <locale> <text>"}}'
	results = results .. ',{"type":"article","id":"8","title":"' .. configuration.commandPrefix .. 'bandersnatch","description":"@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'bandersnatch - Generate a weird name","input_message_content":{"message_text":"Invalid syntax. Use @' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'bandersnatch"}}'
	results = results .. ']'
	mattata.answerInlineQuery(inline_query.id, results, 0, false, nil, 'More features')
end

function help:onQueryReceive(callback, message)
	local configuration = require('configuration')
	if callback.data == 'helpStatistics' then
		userCount = 0
		for _ in pairs(users) do
 			userCount = userCount + 1
 		end
 		if tonumber(userCount) == 1 then
 			userCount = userCount .. ' person is using mattata'
 		else
 			userCount = userCount .. ' people are using mattata'
 		end
		pluginCount = 0
		for _ in pairs(self.plugins) do
			pluginCount = pluginCount + 1
		end
		if tonumber(pluginCount) == 1 then
			pluginCount = pluginCount .. ' plugin is enabled'
		else
			pluginCount = pluginCount .. ' plugins are enabled'
		end
		punCount = 0
		for _ in pairs(configuration.puns) do
			punCount = punCount + 1
		end
		if tonumber(punCount) == 1 then
			punCount = punCount .. ' pun configured'
		else
			punCount = punCount .. ' puns configured'
		end
		trumpCount = 0
		for _ in pairs(configuration.trumps) do
			trumpCount = trumpCount + 1
		end
		if tonumber(trumpCount) == 1 then
			trumpCount = trumpCount .. ' trump configured'
		else
			trumpCount = trumpCount .. ' trumps configured'
		end
		local helpStatistics = userCount .. '\n'
		helpStatistics = helpStatistics .. pluginCount .. '\n'
		helpStatistics = helpStatistics .. punCount .. '\n'
		helpStatistics = helpStatistics .. trumpCount
		mattata.editMessageText(message.chat.id, message.message_id, helpStatistics .. '\n\nYou can view message statistics in groups I\'m part of, using ' .. configuration.commandPrefix .. 'statistics.', nil, true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"helpBack"}]]}')
	end
	if callback.data == 'helpCommands' then
		if message.chat.type ~= 'private' then
			local res = mattata.sendMessage(callback.from.id, helpText, 'Markdown', true, false)
			if not res then
				mattata.editMessageText(message.chat.id, message.message_id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) to get started.', 'Markdown', true, mattata.generateCallbackButton('Back', 'helpBack'))
			else
				mattata.editMessageText(message.chat.id, message.message_id, 'I have sent you a private message containing the requested information.', nil, true, mattata.generateCallbackButton('Back', 'helpBack'))
			end
		else
			mattata.editMessageText(message.chat.id, message.message_id, helpText, 'Markdown', true, mattata.generateCallbackButton('Back', 'helpBack'))
		end
	end
	if callback.data == 'helpLinks' then
		local helpLinks = 'Here are some official links that you may find useful!'
		mattata.editMessageText(message.chat.id, message.message_id, helpLinks, 'Markdown', true, '{"inline_keyboard":[[{"text":"Official Group", "url":"https://telegram.me/mattata"},{"text":"Source Code", "url":"https://github.com/matthewhesketh/mattata"},{"text":"Rate Me", "url":"https://telegram.me/storebot?start=mattatabot"}],[{"text":"Back", "callback_data":"helpBack"}]]}')
	end
	if callback.data == 'helpBack' then
		mattata.editMessageText(message.chat.id, message.message_id, '*Hello, ' .. mattata.markdownEscape(callback.from.first_name) .. '!*\nMy name is ' .. self.info.first_name .. ' and I\'m an intelligent bot written with precision. There are many things I can do - try clicking the \'Commands\' button below to see what I can do for you.\n\n*Oh, and I work well in groups, too!*\nYou can enable and disable plugins in your group(s) using ' .. configuration.commandPrefix .. 'plugins.', 'Markdown', true, '{"inline_keyboard":[[{"text":"Links", "callback_data":"helpLinks"},{"text":"Statistics", "callback_data":"helpStatistics"},{"text":"Commands", "callback_data":"helpCommands"}],[{"text":"Help", "callback_data":"helpHelp"},{"text":"About", "callback_data":"helpAbout"}]]}')
	end
	if callback.data == 'helpHelp' then
		local a, b = mattata.editMessageText(message.chat.id, message.message_id, '*Confused?*\nDon\'t worry, I was programmed to help! Try using ' .. configuration.commandPrefix .. 'help <command> to get help with a specific plugin and its usage.\n\nI\'m also an innovative example of artificial intelligence - yes, that\'s right; I can learn from you! Try speaking to me right here, or mention me by my name in a group. I can also describe images sent in response to messages I send.\n\nYou can also use me inline, try mentioning my username from any group and discover what else I can do!', 'Markdown', true, mattata.generateCallbackButton('Back', 'helpBack'))
	end
	if callback.data == 'helpAbout' then
		mattata.editMessageText(message.chat.id, message.message_id, 'I\'m a bot written in Lua, and built to take advantage of the brilliant Bot API which Telegram offers.\n\nMy creator (and primary maintainer) is @wrxck.\nHe believes that anybody who enjoys programming should be able to work with the code of which I was compiled from, so I\'m proud to say that I am an open source project, which you can discover more about on [GitHub](https://github.com/matthewhesketh/mattata).', 'Markdown', true, mattata.generateCallbackButton('Back', 'helpBack'))
	end
end

function help:onMessageReceive(message)
	local configuration = require('configuration')
	local input = mattata.input(message.text)
	if input then
		for _, plugin in ipairs(self.plugins) do
			if plugin.helpWord == input:gsub('^/', '') then
				local output = 'Help for *' .. plugin.helpWord .. '*:\n' .. plugin.help
				mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
				return
			end
		end
		mattata.sendMessage(message.chat.id, 'I\'m sorry, but I\'m afraid there is no help documented for that plugin at this moment in time. If you believe this is a mistake, please don\'t hesitate to contact [my developer](https://telegram.me/wrxck).', nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, '*Hello, ' .. mattata.markdownEscape(message.from.first_name) .. '!*\nMy name is ' .. self.info.first_name .. ' and I\'m an intelligent bot written with precision. There are many things I can do - try clicking the \'Commands\' button below to see what I can do for you.\n\n*Oh, and I work well in groups, too!*\nYou can enable and disable plugins in your group(s) using ' .. configuration.commandPrefix .. 'plugins.', 'Markdown', true, false, nil, '{"inline_keyboard":[[{"text":"Links", "callback_data":"helpLinks"},{"text":"Statistics", "callback_data":"helpStatistics"},{"text":"Commands", "callback_data":"helpCommands"}],[{"text":"Help", "callback_data":"helpHelp"},{"text":"About", "callback_data":"helpAbout"}]]}')
end

return help
