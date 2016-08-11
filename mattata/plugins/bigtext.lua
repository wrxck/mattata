local bindings = require('mattata.bindings')
local utilities = require('mattata.utilities')
local bigtext = {}
function bigtext:init(config)
	bigtext.triggers = utilities.triggers(self.info.username, config.cmd_pat)
		:t('bigtext', true):t('bt', true).table
	bigtext.doc = config.cmd_pat .. [[bigtext <text>
Converts the given text into 'big' unicode text.
Alias: ]] .. config.cmd_pat .. 'bt'
	bigtext.command = 'bigtext <text>'
end
function bigtext:action(msg, config)
	local input = utilities.input(msg.text_lower)
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			utilities.send_reply(self, msg, bigtext.doc, true)
			return
		end
	end
	bindings.sendChatAction(self, { chat_id = msg.chat.id, action = 'typing' } )
	local output = input:gsub('a', '🇦 '):gsub('b', '🇧 '):gsub('c', '🇨 '):gsub('d', '🇩 '):gsub('e', '🇪 '):gsub('f', '🇫 '):gsub('g', '🇬 '):gsub('h', '🇭 '):gsub('i', '🇮 '):gsub('j', '🇯 '):gsub('k', '🇰 '):gsub('l', '🇱 '):gsub('m', '🇲 '):gsub('n', '🇳 '):gsub('o', '🇴 '):gsub('p', '🇵 '):gsub('q', '🇶 '):gsub('r', '🇷 '):gsub('s', '🇸 '):gsub('t', '🇹 '):gsub('u', '🇺 '):gsub('v', '🇻 '):gsub('w', '🇼 '):gsub('x', '🇽 '):gsub('y', '🇾 '):gsub('z', '🇿 ')
	utilities.send_message(self, msg.chat.id, output, true, nil, true)
end
return bigtext