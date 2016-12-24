local wikipedia = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function wikipedia:init(configuration)
	wikipedia.arguments = 'wikipedia <query>'
	wikipedia.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('wikipedia'):command('wiki'):command('w').table
	wikipedia.help = configuration.commandPrefix .. 'wikipedia <query> - Returns an article from Wikipedia. Aliases: ' .. configuration.commandPrefix .. 'w, ' .. configuration.commandPrefix .. 'wiki.'
end

function wikipedia.getTitle(search)
	for _, v in ipairs(search) do
		if not v.snippet:match('may refer to:') then
			return v.title
		end
	end
 	return false
end

function wikipedia:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, wikipedia.help, nil, true, false, message.message_id)
		return
	else
		input = input:gsub('#', ' sharp')
	end
	local jstr, res = https.request('http://' .. configuration.language .. '.wikipedia.org/w/api.php?action=query&list=search&format=json&srsearch=' .. url.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = json.decode(search_jstr)
	if jdat.query.searchinfo.totalhits == 0 then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local title = wikipedia.getTitle(jdat.query.search)
	if not title then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local resultJstr, resultRes = https.request('https://' .. configuration.language .. '.wikipedia.org/w/api.php?action=query&prop=extracts&format=json&exchars=4000&exsectionformat=plain&titles=' .. url.escape(title))
	if resultRes ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local _
	local text = json.decode(resultJstr).query.pages
	_, text = next(text)
	if not text then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	else
		text = text.extract
	end
	text = text:gsub('</?.->', '')
	local l = text:find('\n')
	if l then
		text = text:sub(1, l - 1)
	end
	local url = 'https://' .. configuration.language .. '.wikipedia.org/wiki/' .. url.escape(title)
	title = title:gsub('%(.+%)', '')
	local output
	if text:sub(1, title:len()):match(title) then
		output = '*' .. title .. '*' .. text:sub(title:len()+1)
	else
		output = '*' .. title:gsub('%(.+%)', '') .. '*\n' .. text:gsub('%[.+%]','')
	end
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'Read More', url = url:gsub('%)', '\\)') }}}
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id, json.encode(keyboard))
end

return wikipedia