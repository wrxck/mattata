local lyrics = {}
local functions = require('functions')
local URL = require('socket.url')
local HTTP = require('socket.http')
local JSON = require('dkjson')
function lyrics:init(configuration)
 lyrics.command =  'lyrics <song>'
 lyrics.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('lyrics', true).table
 lyrics.doc = 'Find the lyrics to the specified song.'
end
function lyrics:action(msg, configuration)
 local input = functions.input(msg.text)
 if not input then
  functions.send_reply(self, msg, "Invalid argument(s), please enter a search query.")
  return
 end
 local lyricsnmusic_key = configuration.lyricsnmusic_key
 local query = URL.escape(input)
 local res = "http://api.lyricsnmusic.com/songs?api_key="..lyricsnmusic_key.."&q="..query
 local all_result = HTTP.request(res)
 local response = JSON.decode(all_result)
 local final_result = response[1]
 local output = "*" .. final_result.title .. "* - *" .. final_result.artist.name .. "*\n\n" .. final_result.snippet .. "\n[Click to see more...](" .. final_result.url .. ")"
 functions.send_message(self, msg.chat.id, output, true, nil, true)
end
return lyrics