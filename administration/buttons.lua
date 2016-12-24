local buttons = {}
local mattata = require('mattata')
local json = require('dkjson')

function buttons:init(configuration)
	buttons.arguments = 'buttons <text> \\n <button text> \\n <button url>'
	buttons.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('buttons').table
	buttons.help = configuration.commandPrefix .. 'buttons <text>\n"<button 1 text>" = "<button 1 url>"\n"<button 2 text>" = "<button 2 url>"\n(and so forth...)'
end

function buttons.generateKeyboard(input)
	if not input:match('\n%".-%" %= %".-%"') then return false, false end
	local keyboard = {}
	keyboard.inline_keyboard = {}
	for text, url in input:gmatch('\n"(.-)" = "(.-)"') do
		local button = {{ text = text, url = url }}
		table.insert(keyboard.inline_keyboard, button)
	end
	return input:gsub('\n%".-%" %= %".-%"', ''), json.encode(keyboard)
end

function buttons:onMessage(message)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, buttons.help, nil, true, false, message.message_id) return end
	local output, keyboard = buttons.generateKeyboard(input)
	if not output then mattata.sendMessage(message.chat.id, buttons.help, nil, true, false, message.message_id) return end
	local res = mattata.sendMessage(message.chat.id, output, nil, true, false, nil, keyboard)
	if not res then mattata.sendMessage(message.chat.id, 'There was an error processing your request, please check the button data is in the correct format and try again.', nil, true, false, message.message_id) end
end

return buttons