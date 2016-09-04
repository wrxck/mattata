local fortune = {}
local functions = require('functions')
function fortune:init(configuration)
 fortune.command = 'fortune'
 fortune.doc = 'Returns your fortune through mattata\'s sixth sense.'
 fortune.triggers = functions.triggers(self.info.username, configuration.command_prefix,
  {'[Yy]/[Nn]%p*$'}):t('fortune', true).table
end
function fortune:action(msg, configuration)
 local fortune_answers = configuration.fortune_answers
 local fortune_yes_no_answers = configuration.fortune_yes_no_answers
 local output
 if msg.text_lower:match('y/n%p?$') then
  output = fortune_yes_no_answers[math.random(#fortune_yes_no_answers)]
 else
  output = fortune_answers[math.random(#fortune_answers)]
 end
 functions.send_reply(self, msg, output)
end
return fortune