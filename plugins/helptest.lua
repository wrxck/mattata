local helptest = {}
local functions = require('functions')
local help_text
function helptest:init(configuration)
	local command_list = {}
	help_text = '*The commands I understand include the following:*\n	» '..configuration.command_prefix
	for _,plugin in ipairs(self.plugins) do
		if plugin.command then
			table.insert(command_list, plugin.command)
			if plugin.doc then
				plugin.help_word = functions.get_word(plugin.command, 1)
			end
		end
	end
	table.insert(command_list, 'help (command)')
	table.sort(command_list)
	help_text = help_text .. table.concat(command_list, '\n	» '..configuration.command_prefix) .. '\n*Arguments: <required> (optional)*'
	helptest.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('helptest', true):t('ht', true).table
	helptest.doc = configuration.command_prefix .. '*help (command)* \n*Usage information for the given command.*'
end
function helptest:action(msg)
	local input = functions.input(msg.text_lower)
	if input then
		for _,plugin in ipairs(self.plugins) do
			if plugin.help_word == input:gsub('^/', '') then
				local output = '*Help for* `' .. plugin.help_word .. '`*:*\n' .. plugin.doc
				functions.send_reply(msg, output, true)
			end
		end
		functions.send_reply(msg, '*Sorry, there is no help for that command!*', true)
	else
		local res = functions.send_message(msg.from.id, help_text, true, nil, true, '{"inline_keyboard":[[{"text":"Official Channel", "url":"https://telegram.me/mattata"}]]}')
		functions.send_reply(msg, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) for command-related help.', true)
	elseif msg.chat.type ~= 'private' then
		functions.send_reply(msg, '*Hi there, mate - I have sent you a private message containing the information you requested.*', true)
	end
end
return helptest