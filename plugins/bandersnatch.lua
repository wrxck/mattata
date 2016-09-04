local bandersnatch = {}
local functions = require('functions')
bandersnatch.command = 'bandersnatch'
function bandersnatch:init(configuration)
 bandersnatch.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('bandersnatch'):t('bc').table
 bandersnatch.doc = 'Shun the frumious Bandersnatch (whatever THAT means)... \nAlias: ' .. configuration.command_prefix .. 'bc'
end
function bandersnatch:action(msg, configuration)
 local output
 local fullnames = configuration.bandersnatch_full_names
 local firstnames = configuration.bandersnatch_first_names
 local lastnames = configuration.bandersnatch_last_names
 if math.random(10) == 10 then
  output = fullnames[math.random(#fullnames)]
 else
  output = firstnames[math.random(#firstnames)] .. ' ' .. lastnames[math.random(#lastnames)]
 end
 functions.send_message(self, msg.chat.id, '_'..output..'_', true, nil, true)
end
return bandersnatch