local bible = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local functions = require('functions')
function bible:init(configuration)
	bible.command = 'bible <reference>'
	bible.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('bible', true).table
	bible.doc = configuration.command_prefix .. 'bible <reference> - Returns a verse from the American Standard Version of the Bible, or an apocryphal verse from the King James Version. Results from biblia.com.'
end
function bible:action(msg, configuration)
	local input = functions.input_from_msg(msg)
	if not input then
		functions.send_reply(msg, bible.doc, true)
		return
	end
	local url = configuration.bible_asv_api .. configuration.bible_key .. '&passage=' .. URL.escape(input)
	local output, res = HTTP.request(url)
	if not output or res ~= 200 or output:len() == 0 then
		url = configuration.bible_kjv_api .. configuration.bible_key .. '&passage=' .. URL.escape(input)
		output, res = HTTP.request(url)
	end
	if not output or res ~= 200 or output:len() == 0 then
		output = configuration.errors.results
	end
	if output:len() > 4000 then
		output = 'The text is too long to post here. Try and be more specific.'
	end
	functions.send_reply(msg, '`' .. output .. '`', true)
end
return bible