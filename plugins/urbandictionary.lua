local urbandictionary = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function urbandictionary:init(configuration)
	urbandictionary.command = 'urbandictionary <query>'
	urbandictionary.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('urbandictionary', true):t('ud', true):t('urban', true).table
	urbandictionary.documentation = configuration.command_prefix .. 'urbandictionary <query> - Defines the given word. Urban style. Aliases: ' .. configuration.command_prefix .. 'ud, ' .. configuration.command_prefix .. 'urban.'
end
function urbandictionary:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, urbandictionary.documentation)
		return
	end
	local url = configuration.apis.urbandictionary .. URL.escape(input)
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	else
		local jdat = JSON.decode(jstr)
		if jdat.result_type == "no_results" then
			functions.send_reply(msg, configuration.errors.results)
			return
		end
		local output = '*' .. jdat.list[1].word .. '*\n\n' .. functions.trim(jdat.list[1].definition)
		if string.len(jdat.list[1].example) > 0 then
			output = output .. '_\n\n' .. functions.trim(jdat.list[1].example) .. '_'
		end
		output = output:gsub('%[', ''):gsub('%]', '')
		functions.send_reply(msg, output, true)
		return
	end
end
return urbandictionary