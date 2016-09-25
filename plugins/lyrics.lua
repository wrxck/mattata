local lyrics = {}
local functions = require('functions')
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
function lyrics:init(configuration)
	lyrics.command =  'lyrics <query>'
	lyrics.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('lyrics', true).table
	lyrics.doc = configuration.command_prefix .. 'lyrics <query> - Find the lyrics to the specified song.'
end
function lyrics:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, lyrics.doc, true)
		return
	end
	local url_id = configuration.lyrics_api .. 'track.search?apikey=' .. configuration.lyrics_key .. '&q_track=' .. input:gsub(' ', '%%20')
	local jstr_id, res_id = HTTPS.request(url_id)
	local jdat_id = JSON.decode(jstr_id)
	if res_id ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	end
	if jdat_id.message.header.available == 0 or nil then
		functions.send_reply(msg, '`' .. configuration.errors.results .. '`', true)
		return
	elseif jdat_id.message.body.track_list[1] then
		local url = configuration.lyrics_api .. 'track.lyrics.get?apikey=' .. configuration.lyrics_key .. '&track_id=' .. jdat_id.message.body.track_list[1].track.track_id
		local jstr, res_lyrics = HTTPS.request(url)
		if res_lyrics ~= 200 then
			functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
			return
		end
		local jdat = JSON.decode(jstr)
		if jdat.message.body.lyrics == nil then
			functions.send_reply(msg, '`' .. configuration.errors.results .. '`', true)
			return
		end
		local lyrics = '*' .. jdat_id.message.body.track_list[1].track.track_name .. ' - ' .. jdat_id.message.body.track_list[1].track.artist_name .. '*\n\n' .. jdat.message.body.lyrics.lyrics_body:gsub('%...', ''):gsub('This Lyrics is NOT for Commercial use', '')
		functions.send_message(msg.chat.id, lyrics, true, nil, true, '{"inline_keyboard":[[{"text":"Read more", "url":"'..jdat_id.message.body.track_list[1].track.track_share_url..'"}]]}')
	end
end
return lyrics