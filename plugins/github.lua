local github = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local functions = require('functions')
function github:init(configuration)
	github.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('github', true).table
end
function github:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		return
	else
		input = input:gsub(' ', '/')
		local jstr = HTTPS.request('https://api.github.com/repos/' .. input)
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
			local forks = jdat.forks
			local forks_url = jdat.forks_url:gsub('api.', ''):gsub('/repos', '')
			local watchers = jdat.watchers
			local open_issues = jdat.open_issues
			local forks_count = ''
			if tonumber(forks) < 1 then
				forks_count = ' forks'
			elseif tonumber(forks) == 1 then
				forks_count = ' fork'
			else
				forks_count = ' forks'
			end
			local stats = '[' .. forks .. forks_count .. '](' .. forks_url .. ') *|* Last updated at ' .. updated_at
			local output = title .. '\n' .. '`' .. description .. '`' .. '\n' .. stats
			functions.send_reply(msg, output, true)
			return
		else
			functions.send_reply(msg, '`' .. configuration.errors.results .. '`', true)
			return
		end
	end
end
return github