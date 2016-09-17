local bandersnatch = {}
local functions = require('functions')
function bandersnatch:init(configuration)
	bandersnatch.command = 'bandersnatch'
	bandersnatch.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('bandersnatch'):t('bc').table
	bandersnatch.doc = configuration.command_prefix .. 'bandersnatch - Shun the frumious Bandersnatch (whatever THAT means)... Alias: ' .. configuration.command_prefix .. 'bc'
end
function bandersnatch:action(msg, configuration)
	local output
	local fullnames = configuration.bandersnatch_full_names
	local firstnames = configuration.bandersnatch_first_names
	local lastnames = configuration.bandersnatch_last_names
	if math.random(10) == 10 then
		output = '`' .. fullnames[math.random(#fullnames)] .. '`'
	else
		output = '`' .. firstnames[math.random(#firstnames)] .. ' ' .. lastnames[math.random(#lastnames)] .. '`'
	end
	functions.send_reply(self, msg, output, true)
end
return bandersnatch