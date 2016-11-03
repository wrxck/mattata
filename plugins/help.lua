local help = {}
local mattata = require('mattata')
local JSON = require('dkjson')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local help_text, db, user_count, plugin_count, pun_count, trump_count

function help:init()
	local configuration = require('configuration')
	local arguments_list = {}
	help_text = '» ' .. configuration.commandPrefix
	for _, plugin in ipairs(self.plugins) do
		if plugin.arguments then
			table.insert(arguments_list, plugin.arguments)
			if plugin.help then
				plugin.help_word = mattata.getWord(plugin.arguments, 1)
			end
		end
	end
	table.insert(arguments_list, 'help <plugin>')
	table.sort(arguments_list)
	help_text = help_text .. table.concat(arguments_list, '\n» ' .. configuration.commandPrefix)
	help.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('help'):c('h').table
	help.inlineCommands = { '^' .. '' .. '' }
	help.help = configuration.commandPrefix .. 'help <plugin> - Usage information for the given plugin. Alias: ' .. configuration.commandPrefix .. 'h.'
	db = self.db
end

function help:onInlineCallback(inline_query)
	local configuration = require('configuration')
	local results = '[{"type":"article","id":"1","title":"/id","description":"@mattatabot /id <username/ID> - Get information about a user/group","input_message_content":{"message_text":"Invalid syntax. Use @mattatabot /id <username/ID>"}}'
	results = results .. ',{"type":"article","id":"2","title":"/ai","description":"@mattatabot /ai <text> - Talk to mattata","input_message_content":{"message_text":"Invalid syntax. Use @mattatabot /ai <text>"}}'
	results = results .. ',{"type":"article","id":"3","title":"/apod","description":"@mattatabot /apod - Get the astronomical photo of the day","input_message_content":{"message_text":"Invalid syntax. Use @mattatabot /apod"}}'
	results = results .. ',{"type":"article","id":"4","title":"/gif","description":"@mattatabot /gif <query> - Search for GIFs","input_message_content":{"message_text":"Invalid syntax. Use @mattatabot /gif <query>"}}'
	results = results .. ']'
	mattata.answerInlineQuery(inline_query.id, results, 0, false, nil, 'More features')
end

function help:onQueryReceive(callback, message)
	local configuration = require('configuration')
	if callback.data == 'help_statistics' then
		plugin_count = 0
		for _ in pairs(self.plugins) do
			plugin_count = plugin_count + 1
		end
		if tonumber(plugin_count) == 1 then
			plugin_count = plugin_count .. ' plugin is enabled'
		else
			plugin_count = plugin_count .. ' plugins are enabled'
		end
		pun_count = 0
		for _ in pairs(configuration.puns) do
			pun_count = pun_count + 1
		end
		if tonumber(pun_count) == 1 then
			pun_count = pun_count .. ' pun configured'
		else
			pun_count = pun_count .. ' puns configured'
		end
		trump_count = 0
		for _ in pairs(configuration.trumps) do
			trump_count = trump_count + 1
		end
		if tonumber(trump_count) == 1 then
			trump_count = trump_count .. ' trump configured'
		else
			trump_count = trump_count .. ' trumps configured'
		end
		local help_statistics = plugin_count .. '\n'
		help_statistics = help_statistics .. pun_count .. '\n'
		help_statistics = help_statistics .. trump_count
		mattata.editMessageText(message.chat.id, message.message_id, help_statistics, nil, true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"help_back"}]]}')
	end
	if callback.data == 'help_commands' then
		if message.chat.type ~= 'private' then
			local res = mattata.sendMessage(callback.from.id, help_text, 'Markdown', true, false, nil, nil)
			if not res then
				mattata.editMessageText(message.chat.id, message.message_id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) to get started.', 'Markdown', true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"help_back"}]]}')
			else
				mattata.editMessageText(message.chat.id, message.message_id, 'I have sent you a private message containing the requested information.', nil, true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"help_back"}]]}')
			end
		else
			mattata.editMessageText(message.chat.id, message.message_id, help_text, 'Markdown', true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"help_back"}]]}')
		end
	end
	if callback.data == 'help_links' then
		local help_links = 'Here are some official links that you may find useful!'
		mattata.editMessageText(message.chat.id, message.message_id, help_links, 'Markdown', true, '{"inline_keyboard":[[{"text":"Official Group", "url":"https://telegram.me/mattata"},{"text":"Source Code", "url":"https://github.com/matthewhesketh/mattata"},{"text":"Rate Me", "url":"https://telegram.me/storebot?start=mattatabot"}],[{"text":"Back", "callback_data":"help_back"}]]}')
	end
	if callback.data == 'help_back' then
		mattata.editMessageText(message.chat.id, message.message_id, configuration.aboutText .. '\n\n*I work well in groups, too!*\nYou can enable and disable plugins in your group(s) using ' .. configuration.commandPrefix .. 'plugins', 'Markdown', true, '{"inline_keyboard":[[{"text":"Links", "callback_data":"help_links"},{"text":"Statistics", "callback_data":"help_statistics"},{"text":"Commands", "callback_data":"help_commands"}]]}')
	end
end

function help:onMessageReceive(message)
	local configuration = require('configuration')
	local input = mattata.input(message.text)
	if input then
		for _, plugin in ipairs(self.plugins) do
			if plugin.help_word == input:gsub('^/', '') then
				local output = 'Help for *' .. plugin.help_word .. '*:\n' .. plugin.help
				mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, nil)
				return
			end
		end
		mattata.sendMessage(message.chat.id, 'Sorry, there is no documented help for that plugin.', nil, true, false, message.message_id, nil)
	else
		mattata.sendMessage(message.chat.id, configuration.aboutText .. '\n\n*I work well in groups, too!*\nYou can enable and disable plugins in your group(s) using ' .. configuration.commandPrefix .. 'plugins', 'Markdown', true, false, nil, '{"inline_keyboard":[[{"text":"Links", "callback_data":"help_links"},{"text":"Statistics", "callback_data":"help_statistics"},{"text":"Commands", "callback_data":"help_commands"}]]}')
	end
end

return help