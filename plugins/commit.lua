local commit = {}
local functions = require('functions')
function commit:init(configuration)
	commit.command = 'commit'
	commit.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('commit', true).table
	commit.documentation = configuration.command_prefix .. 'commit - Generates fun (and somewhat-relatable) commit message ideas.'
end
function commit:action(msg, configuration)
	local commits = configuration.commits
	functions.send_reply(msg, commits[math.random(#commits)])
end
return commit