local imdb = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function imdb:init(configuration)
	imdb.command = 'imdb <query>'
	imdb.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('imdb', true).table
	imdb.doc = configuration.command_prefix .. 'imdb <query> - Returns an IMDb entry.'
end
function imdb:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			functions.send_reply(msg, imdb.doc, true)
			return
		end
	end
	local api = configuration.imdb_api .. URL.escape(input)
	local raw_imdb_result, res = HTTP.request(api)
	if res ~= 200 then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	end
	local decoded_imdb_result = JSON.decode(raw_imdb_result)
	if decoded_imdb_result.Response ~= 'True' then
		functions.send_reply(msg, '`' .. configuration.errors.results .. '`', true)
		return
	end
	local output = '*' .. decoded_imdb_result.Title .. ' ('.. decoded_imdb_result.Year ..')*\n'
	output = output .. decoded_imdb_result.imdbRating ..'/10 | '.. decoded_imdb_result.Runtime ..' | '.. decoded_imdb_result.Genre ..'\n'
	output = output .. '_' .. decoded_imdb_result.Plot .. '_\n'
	functions.send_reply(msg, output, true, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. 'http://imdb.com/title/' .. decoded_imdb_result.imdbID .. '"}]]}')
end
return imdb