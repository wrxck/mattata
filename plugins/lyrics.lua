local lyrics = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local JSON = require('dkjson')

function lyrics:init(configuration)
	lyrics.arguments =  'lyrics <query>'
	lyrics.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('lyrics', true).table
	lyrics.help = configuration.commandPrefix .. 'lyrics <query> - Find the lyrics to the specified song.'
end

function lyrics:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, lyrics.help, nil, true, false, msg.message_id, nil)
		return
	end
	local url_id = configuration.apis.lyrics .. 'track.search?apikey=' .. configuration.keys.lyrics .. '&q_track=' .. input:gsub(' ', '%%20')
	local jstr_id, res_id = HTTPS.request(url_id)
	local jdat_id = JSON.decode(jstr_id)
	if res_id ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	if jdat_id.message.header.available == 0 or nil then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	elseif jdat_id.message.body.track_list[1] then
		local url = configuration.apis.lyrics .. 'track.lyrics.get?apikey=' .. configuration.keys.lyrics .. '&track_id=' .. jdat_id.message.body.track_list[1].track.track_id
		local jstr, res_lyrics = HTTPS.request(url)
		if res_lyrics ~= 200 then
			mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
			return
		end
		local jdat = JSON.decode(jstr)
		if jdat.message.body.lyrics == nil then
			mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
			return
		end
		local lyrics = '*' .. jdat_id.message.body.track_list[1].track.track_name .. ' - ' .. jdat_id.message.body.track_list[1].track.artist_name .. '*\n\n' .. jdat.message.body.lyrics.lyrics_body:gsub('%...', ''):gsub('This Lyrics is NOT for Commercial use', '')
		mattata.sendMessage(msg.chat.id, lyrics, 'Markdown', true, false, msg.message_id, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. jdat_id.message.body.track_list[1].track.track_share_url .. '"}]]}')
	end
end

return lyrics