local help = {}
local functions = require('functions')
local help_text
function help:init(configuration)
	local command_list = {}
	help_text = '*The commands I understand include the following:*\n	» ' .. configuration.command_prefix
	for _, plugin in ipairs(self.plugins) do
		if plugin.command then
			table.insert(command_list, plugin.command)
			if plugin.documentation then
				plugin.help_word = functions.get_word(plugin.command, 1)
			end
		end
	end
	table.insert(command_list, 'help (command)')
	table.sort(command_list)
	help_text = help_text .. table.concat(command_list, '\n	» '..configuration.command_prefix) .. '\n\n*Arguments:* <required> (optional)'
	help.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('help', true):t('h', true).table
	help.documentation = configuration.command_prefix .. '*help (command)* \nUsage information for the given command.'
end
function help:action(msg)
	local input = functions.input(msg.text)
	if input then
		for _, plugin in ipairs(self.plugins) do
			if plugin.help_word == input:gsub('^/', '') then
				local output = 'Help for *' .. plugin.help_word .. '*:\n' .. plugin.documentation
				functions.send_reply(msg, output, true)
				return
			end
		end
		functions.send_reply(msg, 'Sorry, there is no documented help for that command.', true)
	else
		local res = functions.send_message(msg.from.id, help_text, true, nil, true, '{"inline_keyboard":[[{"text":"Official Channel", "url":"https://telegram.me/mattata"},{"text":"Source Code", "url":"https://matthewhesketh.github.io/mattata"}]]}')
		if not res then
			functions.send_reply(msg, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) to get started.', true)
		elseif msg.chat.type ~= 'private' then
			functions.send_reply(msg, 'I have sent you a private message containing the requested information.')
		end
	end
end
return help