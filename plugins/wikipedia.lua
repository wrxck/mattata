local wikipedia = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function wikipedia:init(configuration)
	wikipedia.command = 'wikipedia <query>'
	wikipedia.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('wikipedia', true):t('wiki', true):t('w', true).table
	wikipedia.doc = configuration.command_prefix .. 'wikipedia <query> - Returns an article from Wikipedia. Aliases: ' .. configuration.command_prefix .. 'w, ' .. configuration.command_prefix .. 'wiki.'
end
local get_title = function(search)
	for _,v in ipairs(search) do
		if not v.snippet:match('may refer to:') then
			return v.title
		end
	end
 	return false
end
function wikipedia:action(msg, configuration)
	local input = functions.input(msg.text)
	if not input then
		if msg.reply_to_message and msg.reply_to_message.text then
			input = msg.reply_to_message.text
		else
			functions.send_message(msg.chat.id, wikipedia.doc, true, msg.message_id, true)
			return
		end
	end
	input = input:gsub('#', ' sharp')
	local jstr, res, jdat
	local search_url = 'http://en.wikipedia.org/w/api.php?action=query&list=search&format=json&srsearch='
	jstr, res = HTTPS.request(search_url .. URL.escape(input))
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	jdat = JSON.decode(jstr)
	if jdat.query.searchinfo.totalhits == 0 then
		functions.send_reply(msg, configuration.errors.results)
		return
	end
	local title = get_title(jdat.query.search)
	if not title then
		functions.send_reply(msg, configuration.errors.results)
		return
	end
	local res_url = 'https://en.wikipedia.org/w/api.php?action=query&prop=extracts&format=json&exchars=4000&exsectionformat=plain&titles='
	jstr, res = HTTPS.request(res_url .. URL.escape(title))
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local _
	local text = JSON.decode(jstr).query.pages
	_, text = next(text)
	if not text then
		functions.send_reply(msg, configuration.errors.results)
		return
	else
		text = text.extract
	end
	text = text:gsub('</?.->', '')
	local l = text:find('\n')
	if l then
		text = text:sub(1, l-1)
	end
	local url = 'https://en.wikipedia.org/wiki/' .. URL.escape(title)
	title = title:gsub('%(.+%)', '')
	local output
	if string.match(text:sub(1, title:len()), title) then
		output = '*' .. title .. '*' .. text:sub(title:len()+1)
	else
		output = '*' .. title:gsub('%(.+%)', '') .. '*\n' .. text:gsub('%[.+%]','')
	end
	functions.send_reply(msg, output, true, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. url:gsub('%)', '\\)') .. '"}]]}')
end
return wikipedia