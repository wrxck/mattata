local commit = {}
local functions = require('functions')
function commit:init(configuration)
 commit.command = 'commit'
 commit.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('commit').table
 commit.doc = 'Generates fun (and somewhat-relatable) commit message ideas.'
end
function commit:action(msg, configuration)
 local commits = configuration.commits
 local output = '`' .. commits[math.random(#commits)] .. '`'
 functions.send_message(self, msg.chat.id, output, true, nil, true)
end
return commit