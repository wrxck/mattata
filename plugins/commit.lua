local commit = {}
local mattata = require('mattata')

function commit:init(configuration)
	commit.arguments = 'commit'
	commit.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('commit').table
	commit.help = configuration.commandPrefix .. 'commit - Generates fun (and somewhat-relatable) commit message ideas.'
end

function commit:onMessageReceive(message, configuration)
	local commits = configuration.commits
	mattata.sendMessage(message.chat.id, commits[math.random(#commits)], nil, true, false, message.message_id, nil)
end

return commit