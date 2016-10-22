local wikipedia = {}
local HTTPS = require('dependencies.ssl.https')
local URL = require('dependencies.socket.url')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function wikipedia:init(configuration)
	wikipedia.arguments = 'wikipedia <query>'
	wikipedia.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('wikipedia', true):c('wiki', true):c('w', true).table
	wikipedia.help = configuration.commandPrefix .. 'wikipedia <query> - Returns an article from Wikipedia. Aliases: ' .. configuration.commandPrefix .. 'w, ' .. configuration.commandPrefix .. 'wiki.'
end

local get_title = function(search)
	for _,v in ipairs(search) do
		if not v.snippet:match('may refer to:') then
			return v.title
		end
	end
 	return false
end

function wikipedia:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, wikipedia.help, nil, true, false, msg.message_id, nil)
		return
	else
		input = input:gsub('#', ' sharp')
	end
	local search_url = 'http://' .. configuration.wikiLanguage .. '.wikipedia.org/w/api.php?onMessageReceive=query&list=search&format=json&srsearch='
	local search_jstr, search_res = HTTPS.request(search_url .. URL.escape(input))
	if search_res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local search_jdat = JSON.decode(search_jstr)
	if search_jdat.query.searchinfo.totalhits == 0 then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	end
	local title = get_title(search_jdat.query.search)
	if not title then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	end
	local result_url = 'https://' .. configuration.wikiLanguage .. '.wikipedia.org/w/api.php?onMessageReceive=query&prop=extracts&format=json&exchars=4000&exsectionformat=plain&titles='
	local result_jstr, result_res = HTTPS.request(result_url .. URL.escape(title))
	if result_res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local _
	local text = JSON.decode(result_jstr).query.pages
	_, text = next(text)
	if not text then
		mattata.sendMessage(msg.chat.id, configuration.errors.results, nil, true, false, msg.message_id, nil)
		return
	else
		text = text.extract
	end
	text = text:gsub('</?.->', '')
	local l = text:find('\n')
	if l then
		text = text:sub(1, l-1)
	end
	local url = 'https://' .. configuration.wikiLanguage .. '.wikipedia.org/wiki/' .. URL.escape(title)
	title = title:gsub('%(.+%)', '')
	local output
	if string.match(text:sub(1, title:len()), title) then
		output = '*' .. title .. '*' .. text:sub(title:len()+1)
	else
		output = '*' .. title:gsub('%(.+%)', '') .. '*\n' .. text:gsub('%[.+%]','')
	end
	mattata.sendMessage(msg.chat.id, output, 'Markdown', nil, true, false, msg.message_id, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. url:gsub('%)', '\\)') .. '"}]]}')
end

return wikipedia