local dice = {}
local functions = require('functions')
function dice:init(configuration)
	dice.command = 'dice <number of dice> <range of numbers>'
	dice.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('dice', true).table
	dice.documentation = configuration.command_prefix .. 'dice <number of dice to roll> <range of numbers on the dice> - Rolls a die a given amount of times, with a given range.'
end
function dice:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, dice.documentation)
		return
	end
	local count, range
	if input:match('^[%d]+ [%d]+$') then
		count, range = input:match('([%d]+) ([%d]+)')
	elseif input:match('^d?[%d]+$') then
		count = 1
		range = input:match('^d?([%d]+)$')
	end
	count = tonumber(count)
	range = tonumber(range)
	if range < configuration.dice.minimum_range then
		functions.send_reply(msg, 'The minimum range is ' .. configuration.dice.minimum_range .. '.')
		return
	end
	if range > configuration.dice.maximum_range or count > configuration.dice.maximum_count then
		if configuration.dice.maximum_range == configuration.dice.maximum_count then
			functions.send_reply(msg, 'The maximum range and count are both ' .. configuration.dice.maximum_range .. '.')
			return
		else
			functions.send_reply(msg, 'The maximum range is ' .. configuration.dice.maximum_range .. ', and the maximum count is ' .. configuration.dice.maximum_count .. '.')
			return
		end
	end
	local output = '*' .. count .. '* rolls with a range of *' .. range .. '*\n'
	for _ = 1, count do
		output = output .. math.random(range) .. '\t'
	end
	functions.send_reply(msg, output, true)
end
return dice