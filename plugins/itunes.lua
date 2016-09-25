local itunes = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
function itunes:init(configuration)
	itunes.command = 'itunes <song>'
	itunes.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('itunes', true).table
	itunes.doc = configuration.command_prefix .. 'itunes <song> - Returns information about the given song, from iTunes.'
end
function itunes:action(msg, configuration)
	local input = functions.input(msg.text)
	local url = configuration.itunes_api .. URL.escape(input)
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	else
		if not input then
			functions.send_reply(msg, itunes.doc, true)
			return
		else
			local jdat = JSON.decode(jstr)
			if jdat.results[1] then
				if jdat.results[1].trackName then
					local trackName = jdat.results[1].trackName
					local trackViewUrl = jdat.results[1].trackViewUrl
					output = '*Track Name:* [' .. trackName .. '](' .. trackViewUrl .. ')'
					if jdat.results[1].artistName and jdat.results[1].artistViewUrl then
						local artistName = jdat.results[1].artistName
						local artistViewUrl = jdat.results[1].artistViewUrl
						output = output .. '\n*Artist:* [' .. artistName .. '](' .. artistViewUrl .. ')'
						if jdat.results[1].collectionName then
							local collectionName = jdat.results[1].collectionName
							local collectionViewUrl = jdat.results[1].collectionViewUrl
							output = output .. '\n*Album:* [' .. collectionName .. '](' .. collectionViewUrl .. ')'
							if jdat.results[1].trackNumber then
								local trackNumber = jdat.results[1].trackNumber
								local trackCount = jdat.results[1].trackCount
								output = output .. '\n*Track Number:* ' .. trackNumber .. '/' .. trackCount
								if jdat.results[1].discNumber then
									local discNumber = jdat.results[1].discNumber
									local discCount = jdat.results[1].discCount
									output = output .. '\n*Disc Number:* ' .. discNumber .. '/' .. discCount
								end
							end
						end
					end
				end
			else
				output = '`' .. configuration.errors.results .. '`'
			end
			functions.send_action(msg.chat.id, 'typing')
			functions.send_message(msg.chat.id, output, true, nil, true)
			return
		end
	end
end
return itunes