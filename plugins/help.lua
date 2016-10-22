local help = {}
local mattata = require('mattata')
local help_text

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
	table.insert(arguments_list, 'help <arguments>')
	table.sort(arguments_list)
	help_text = help_text .. table.concat(arguments_list, '\n	» '..configuration.commandPrefix) .. '\n\n*Arguments:* <required> (optional)'
	help.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('help', true):c('h', true).table
	help.help = configuration.commandPrefix .. '*help <arguments>* \nUsage information for the given arguments.'
end

function help:onMessageReceive(msg)
	local input = mattata.input(msg.text)
	if input then
		for _, plugin in ipairs(self.plugins) do
			if plugin.help_word == input:gsub('^/', '') then
				local output = 'Help for *' .. plugin.help_word .. '*:\n' .. plugin.help
				mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
				return
			end
		end
		mattata.sendMessage(msg.chat.id, 'Sorry, there is no documented help for that arguments.', nil, true, false, msg.message_id, nil)
	else
		local res = mattata.sendMessage(msg.from.id, help_text, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"Official Channel", "url":"https://telegram.me/mattata"},{"text":"Source Code", "url":"https://github.com/matthewhesketh/mattata"},{"text":"Rate me", "url":"https://telegram.me/storebot?start=mattatabot"}]]}')
		if not res then
			mattata.send_reply(msg.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) to get started.', 'Markdown', true, false, msg.message_id, nil)
		elseif msg.chat.type ~= 'private' then
			mattata.sendMessage(msg.chat.id, 'I have sent you a private message containing the requested information.', nil, true, false, msg.message_id, nil)
		end
	end
end

return help