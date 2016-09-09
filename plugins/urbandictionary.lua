local urbandictionary = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function urbandictionary:init(configuration)
	urbandictionary.command = 'urbandictionary <query>'
	urbandictionary.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('urbandictionary', true):t('ud', true):t('urban', true).table
	urbandictionary.doc = configuration.command_prefix .. [[urbandictionary <query> Defines the given word - the Urban Dictionary way. Aliases: ]] .. configuration.command_prefix .. 'ud, ' .. configuration.command_prefix .. 'urban'
end
function urbandictionary:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			functions.send_message(self, msg.chat.id, urbandictionary.doc, true, msg.message_id, true)
			return
		end
	end
	local url = 'http://api.urbandictionary.com/v0/define?term=' .. URL.escape(input)
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		functions.send_reply(self, msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.result_type == "no_results" then
		functions.send_reply(self, msg, configuration.errors.results)
		return
	end
	local output = '*' .. jdat.list[1].word .. '*\n\n' .. functions.trim(jdat.list[1].definition)
	if string.len(jdat.list[1].example) > 0 then
		output = output .. '_\n\n' .. functions.trim(jdat.list[1].example) .. '_'
	end
	output = output:gsub('%[', ''):gsub('%]', '')
	functions.send_message(self, msg.chat.id, output, true, nil, true)
end
return urbandictionary