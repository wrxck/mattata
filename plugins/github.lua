local github = {}
local HTTPS = require('dependencies.ssl.https')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function github:init(configuration)
	github.arguments = 'github <username> <repository>'
	github.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('github', true).table
	github.help = configuration.commandPrefix .. 'github <username> <repository> - Returns information about the specified GitHub repository.'
end

function github:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, github.help, nil, true, false, msg.message_id, nil)
		return
	else
		input = input:gsub(' ', '/')
	end
	local jstr = HTTPS.request(configuration.apis.github .. input)
	local jdat = JSON.decode(jstr)
	if jdat.id then
		local full_name = ''
		if jdat.full_name then
			full_name = jdat.full_name
		end
		local html_url = ''
		if jdat.html_url then
			html_url = jdat.html_url
		end
		local language = jdat.language
		local title = '[' .. full_name .. '](' .. html_url .. ') *|* ' .. language
		local updated_at = ''
		if jdat.updated_at then
			updated_at = jdat.updated_at:gsub('T', ' '):gsub('Z', '')
		end
		local description = ''
		if jdat.description then
			description = jdat.description
		end
		local forks = ''
		if jdat.forks_count then
			forks = jdat.forks_count
		end
		local forks_count = ''
		if tonumber(forks) == 1 then
			forks_count = ' fork'
		else
			forks_count = ' forks'
		end
		local forks_url = html_url .. '/forks'
		local watchers = ''
		if jdat.watchers_count then
			watchers = jdat.watchers_count
		end
		local watchers_count = ''
		if tonumber(watchers) == 1 then
			watchers_count = ' watcher'
		else
			watchers_count = ' watchers'
		end
		local watchers_url = html_url .. '/watchers'
		local stargazers = ''
		if jdat.stargazers_count then
			stargazers = jdat.stargazers_count
		end
		local stargazers_count = ''
		if tonumber(stargazers) == 1 then
			stargazers_count = ' stargazer'
		else
			stargazers_count = ' stargazers'
		end
		local stargazers_url = html_url .. '/stargazers'
		local stats = '[' .. forks .. forks_count .. '](' .. forks_url .. ') *|* [' .. watchers .. watchers_count .. '](' .. watchers_url .. ') *|* [' .. stargazers .. stargazers_count .. '](' .. stargazers_url .. ') \nLast updated at ' .. updated_at
		local output = title .. '\n\n' .. '`' .. description .. '`' .. '\n\n' .. stats
		mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
		return
	else
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	end
end

return github