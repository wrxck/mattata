local commit = {}
local mattata = require('mattata')

function commit:init(configuration)
	commit.arguments = 'commit'
	commit.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('commit', true).table
	commit.help = configuration.commandPrefix .. 'commit - Generates fun (and somewhat-relatable) commit message ideas.'
end

function commit:onMessageReceive(msg, configuration)
	local commits = configuration.commits
	mattata.sendMessage(msg.chat.id, commits[math.random(#commits)], nil, true, false, msg.message_id, nil)
end

return commit