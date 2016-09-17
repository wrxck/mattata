local lyrics = {}
local functions = require('functions')
local URL = require('socket.url')
local HTTP = require('socket.http')
local JSON = require('dkjson')
function lyrics:init(configuration)
	lyrics.command =  'lyrics <query>'
	lyrics.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('lyrics', true).table
	lyrics.doc = configuration.command_prefix .. 'lyrics <query> - Find the lyrics to the specified song.'
end
function lyrics:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(self, msg, "Invalid argument(s), please enter a search query.")
		return
	end
	local res = configuration.lyricsnmusic_api .. configuration.lyricsnmusic_key .. "&q=" .. URL.escape(input)
	if res ~= 200 then
		functions.send_reply(self, msg, configuration.errors.connection, true)
		return
	end
	local all_result = HTTP.request(res)
	local response = JSON.decode(all_result)
	local final_result = response[1]
	local output = "*" .. final_result.title .. "* - *" .. final_result.artist.name .. "*\n\n" .. final_result.snippet .. "\n[Click to see more...](" .. final_result.url .. ")"
	functions.send_reply(self, msg, output, true)
end
return lyrics