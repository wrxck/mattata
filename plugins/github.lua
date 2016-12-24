local github = {}
local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')

function github:init(configuration)
	github.arguments = 'github <username> <repository>'
	github.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('github').table
	github.help = configuration.commandPrefix .. 'github <username> <repository> - Returns information about the specified GitHub repository.'
end

function github:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, github.help, nil, true, false, message.message_id) return end
	input = input:gsub(' ', '/')
	local jstr, res = https.request('https://api.github.com/repos/' .. input)
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	local jdat = json.decode(jstr)
	if not jdat.id then mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id) return end
	local title = '[' .. jdat.full_name .. '](' .. jdat.html_url .. ') *|* ' .. jdat.language
	local description, forks, stargazers, subscribers
	if jdat.description then description = '\n' .. '```\n' .. jdat.description .. '\n```' .. '\n' else description = '\n\n' end
	if jdat.forks_count == 1 then forks = ' fork' else forks = ' forks' end
	if jdat.stargazers_count == 1 then stargazers = ' star' else stargazers = ' stars' end
	if jdat.subscribers_count == 1 then subscribers = ' watcher' else subscribers = ' watchers' end
	mattata.sendMessage(message.chat.id, title .. description .. '[' .. jdat.forks_count .. forks .. '](' .. jdat.html_url .. '/network) *|* [' .. jdat.stargazers_count .. stargazers .. '](' .. jdat.html_url .. '/stargazers) *|* [' .. jdat.subscribers_count .. subscribers .. '](' .. jdat.html_url .. '/watchers) \nLast updated at ' .. jdat.updated_at:gsub('T', ' '):gsub('Z', ''), 'Markdown', true, false, message.message_id)
end

return github