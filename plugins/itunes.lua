local itunes = {}
local HTTPS = require('dependencies.ssl.https')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function itunes:init(configuration)
	itunes.arguments = 'itunes <song>'
	itunes.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('itunes', true).table
	itunes.help = configuration.commandPrefix .. 'itunes <song> - Returns information about the given song, from iTunes.'
end

function itunes:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, itunes.help, nil, true, false, msg.message_id, nil)
		return
	end
	local url = configuration.apis.itunes .. URL.escape(input)
	local jstr, res = HTTPS.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
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
			else
				output = configuration.errors.results
			end
			mattata.sendChatAction(msg.chat.id, 'typing')
			mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
			return
		end
	end
end

return itunes