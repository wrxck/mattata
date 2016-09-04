local pun = {}
local functions = require('functions')
function pun:init(configuration)
 pun.command = 'pun'
 pun.doc = 'Sends a pun.'
 pun.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('pun').table
end
function pun:action(msg, configuration)
 local puns = configuration.puns
 functions.send_reply(self, msg, puns[math.random(#puns)])
end
return pun