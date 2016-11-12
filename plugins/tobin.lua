local tobin = {}
local mattata = require('mattata')

function tobin:init(configuration)
	tobin.arguments = 'tobin <number>'
	tobin.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('tobin').table
	tobin.help = configuration.commandPrefix .. 'tobin <number> - Converts the given number to binary.'
end

function tobin:onMessageReceive(message)
  local input = mattata.input(message.text)
  if not input then
		mattata.sendMessage(message.chat.id, tobin.help, nil, true, false, message.message_id, nil)
		return
	else
    if tonumber(input) ~= nil then
      input = tonumber(input)
      local bits = {}
      while input > 0 do
        rem = math.fmod(input, 2)
        bits[#bits + 1] = rem
        input = (input - rem) / 2
      end
      bits = table.concat(bits)
      mattata.sendMessage(message.chat.id, '`' .. bits .. '`', 'Markdown', true, false, message.message_id, nil)
    else
      mattata.sendMessage(message.chat.id, 'Must be a number.', 'Markdown', true, false, message.message_id, nil)
    end
  end
end

return tobin
