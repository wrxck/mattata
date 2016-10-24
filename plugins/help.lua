local help = {}
local mattata = require('mattata')
local help_text, db, user_count, plugin_count, pun_count, trump_count

function help:init(configuration)
	local arguments_list = {}
	help_text = '*The commands I understand include the following:*\n	» ' .. configuration.commandPrefix
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
	help_text = help_text .. table.concat(arguments_list, '\n	» ' .. configuration.commandPrefix) .. '\n\n*Arguments:* <required> (optional)'
	help.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('help', true):c('h', true).table
	help.help = configuration.commandPrefix .. '*help <plugin>* \nUsage information for the given plugin.'
	db = self.db
end

function help:onQueryReceive(callback, msg, configuration)
	if callback.data == 'help_statistics' then
		user_count = 0
		for _ in pairs(db.users) do
			user_count = user_count + 1
		end
		if tonumber(user_count) == 1 then
			user_count = user_count .. ' person is using mattata'
		else
			user_count = user_count .. ' people are using mattata'
		end
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
		local help_statistics = '*Statistics*\n'
		help_statistics = help_statistics .. user_count .. '\n'
		help_statistics = help_statistics .. plugin_count .. '\n'
		help_statistics = help_statistics .. pun_count .. '\n'
		help_statistics = help_statistics .. trump_count
		local update_time = '\n\n`' .. os.time() .. '`'
		help_statistics = help_statistics .. update_time
		mattata.editMessageText(msg.chat.id, msg.message_id, help_statistics, 'Markdown', true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"help_back"},{"text":"Refresh", "callback_data":"help_statistics"}]]}')
	end
	if callback.data == 'help_commands' then
		if msg.chat.type ~= 'private' then
			local res = mattata.sendMessage(callback.from.id, configuration.aboutText, 'Markdown', true, false, nil, '{"inline_keyboard":[[{"text":"Links", "callback_data":"help_links"},{"text":"Statistics", "callback_data":"help_statistics"},{"text":"Commands", "callback_data":"help_commands"}]]}')
			if not res then
				mattata.editMessageText(msg.chat.id, msg.message_id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) to get started.', 'Markdown', true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"help_back"}]]}')
			else
				mattata.editMessageText(msg.chat.id, msg.message_id, 'I have sent you a private message containing the requested information.', nil, true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"help_back"}]]}')
			end
		else
			mattata.editMessageText(msg.chat.id, msg.message_id, help_text, 'Markdown', true, '{"inline_keyboard":[[{"text":"Back", "callback_data":"help_back"}]]}')
		end
	end
	if callback.data == 'help_links' then
		local help_links = 'Here are some official links that you may find useful!'
		mattata.editMessageText(msg.chat.id, msg.message_id, help_links, 'Markdown', true, '{"inline_keyboard":[[{"text":"Official Group", "url":"https://telegram.me/mattata"},{"text":"Source Code", "url":"https://github.com/matthewhesketh/mattata"},{"text":"Rate Me", "url":"https://telegram.me/storebot?start=mattatabot"}],[{"text":"Back", "callback_data":"help_back"}]]}')
	end
	if callback.data == 'help_back' then
		mattata.editMessageText(msg.chat.id, msg.message_id, configuration.aboutText, 'Markdown', true, '{"inline_keyboard":[[{"text":"Links", "callback_data":"help_links"},{"text":"Statistics", "callback_data":"help_statistics"},{"text":"Commands", "callback_data":"help_commands"}]]}')
	end
end

function help:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if input then
		for _, plugin in ipairs(self.plugins) do
			if plugin.help_word == input:gsub('^/', '') then
				local output = 'Help for *' .. plugin.help_word .. '*:\n' .. plugin.help
				mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
				return
			end
		end
		mattata.sendMessage(msg.chat.id, 'Sorry, there is no documented help for that plugin.', nil, true, false, msg.message_id, nil)
	else
		mattata.sendMessage(msg.chat.id, configuration.aboutText, 'Markdown', true, false, nil, '{"inline_keyboard":[[{"text":"Links", "callback_data":"help_links"},{"text":"Statistics", "callback_data":"help_statistics"},{"text":"Commands", "callback_data":"help_commands"}]]}')
	end
end

return help