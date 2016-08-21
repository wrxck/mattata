local dice = {}

local utilities = require('mattata.utilities')

dice.command = 'dice <number of dice> <range of numbers>'

function dice:init(config)
	dice.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('dice', true).table
	dice.doc = config.cmd_pat .. [[dice <number of dice to roll> <range of numbers on the dice>
Rolls a die a given amount of times, with a given range.]]
end

function dice:action(msg)

	local input = utilities.input(msg.text_lower)
	if not input then
		utilities.send_message(self, msg.chat.id, dice.doc, true, msg.message_id, true)
		return
	end

	local count, range
	if input:match('^[%d]+ [%d]+$') then
		count, range = input:match('([%d]+) ([%d]+)')
	elseif input:match('^d?[%d]+$') then
		count = 1
		range = input:match('^d?([%d]+)$')
	else
		utilities.send_message(self, msg.chat.id, dice.doc, true, msg.message_id, true)
		return
	end

	count = tonumber(count)
	range = tonumber(range)

	if range < 2 then
		utilities.send_reply(self, msg, 'The minimum range is 2.')
		return
	end
	if range > 1000 or count > 1000 then
		utilities.send_reply(self, msg, 'The maximum range and count are 1000.')
		return
	end

	local output = '*' .. count .. ' rolls with a range of ' .. range .. '*\n`'
	for _ = 1, count do
		output = output .. math.random(range) .. '\t'
	end
	output = output .. '`'

	utilities.send_message(self, msg.chat.id, output, true, msg.message_id, true)

end

return dice
