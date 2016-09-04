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
  if msg.reply_to_message and msg.reply_to_message.text then
  input = msg.reply_to_message.text
  else
  functions.send_message(self, msg.chat.id, lyrics.doc, true, msg.message_id, true)
  return
 end
 local lyricsnmusic_key = configuration.lyricsnmusic_key
 local query = URL.escape(input)
 local results = HTTP.request("http://api.lyricsnmusic.com/songs?api_key=".. lyricsnmusic_key.."&q=" .. query)
 response = JSON.decode(results)
 local result = response[1]
 local output = result.title .. " - " .. result.artist.name .. "\n\n" .. result.snippet .. "\n[Click to see more...](" .. result.url .. ")"
end
functions.send_message(self, msg.chat.id, output, true, nil, true)
end
return lyrics