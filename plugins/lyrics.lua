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
		functions.send_reply(msg, '`Invalid argument(s), please enter a search query.`', true)
		return
	end
	local result = configuration.lyricsnmusic_api .. configuration.lyricsnmusic_key .. "&q=" .. URL.escape(input)
	local jstr, res = HTTP.request(result)
	if res ~= 200 then
		functions.send_reply(msg, '`The lyrics API appears to be down. If you think this is an error, then please contact @wrxck.`', true)
		return
	else
		local jdat = JSON.decode(jstr)
		local lyric = jdat[1]
		local output = "*" .. lyric.title .. "* by *" .. lyric.artist.name .. "*\n\n" .. lyric.snippet
		functions.send_reply(msg, output, true, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. lyric.url .. '"}]]}')
	end
end
return lyrics