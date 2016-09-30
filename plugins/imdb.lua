local imdb = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function imdb:init(configuration)
	imdb.command = 'imdb <query>'
	imdb.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('imdb', true).table
	imdb.documentation = configuration.command_prefix .. 'imdb <query> - Returns an IMDb entry.'
end
function imdb:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, imdb.documentation)
		return
	end
	local url = configuration.apis.imdb .. URL.escape(input)
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.Response ~= 'True' then
		functions.send_reply(msg, configuration.errors.results)
		return
	end
	local output = '*' .. jdat.Title .. ' (' .. jdat.Year .. ')*\n'
	output = output .. jdat.imdbRating .. '/10 | ' .. jdat.Runtime .. ' | ' .. jdat.Genre .. '\n'
	output = output .. '_' .. jdat.Plot .. '_\n'
	functions.send_reply(msg, output, true, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. 'http://imdb.com/title/' .. jdat.imdbID .. '"}]]}')
end
return imdb