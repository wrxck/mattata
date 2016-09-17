local commit = {}
local functions = require('functions')
function commit:init(configuration)
	commit.command = 'commit'
	commit.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('commit').table
	commit.doc = configuration.command_prefix .. 'commit - Generates fun (and somewhat-relatable) commit message ideas.'
end
function commit:action(msg, configuration)
	local commits = configuration.commits
	local output = '`' .. commits[math.random(#commits)] .. '`'
	functions.send_reply(self, msg, output, true)
end
return commit