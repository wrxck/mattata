local isp = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function isp:init(configuration)
	isp.arguments = 'isp <URL>'
	isp.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('isp').table
	isp.help = configuration.commandPrefix .. 'isp <URL> - Sends information about the given URL\'s ISP.'
end

function isp:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, isp.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTP.request('http://ip-api.com/json/' .. input .. '?lang=' .. configuration.language .. '&fields=country,regionName,city,zip,isp,org,as,status,message,query')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.status == 'fail' then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	if jdat.isp ~= '' then
		output = '*' .. jdat.isp .. '*\n'
	elseif jdat.zip ~= '' then
		output = output .. jdat.zip .. '\n'
	elseif jdat.city ~= '' then
		output = output .. jdat.city .. '\n'
	elseif jdat.regionName ~= '' then
		output = output .. jdat.regionName .. '\n'
	elseif jdat.country ~= '' then
		output = output .. jdat.country .. '\n'
	end
	mattata.sendMessage(channel_post.chat.id, '`' .. input:gsub('`', '\\`') .. ':`\n' .. output, 'Markdown', true, false, channel_post.message_id)
end

function isp:onMessage(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, isp.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://ip-api.com/json/' .. input .. '?lang=' .. language.locale .. '&fields=country,regionName,city,zip,isp,org,as,status,message,query')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.status == 'fail' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	if jdat.isp ~= '' then
		output = '*' .. jdat.isp .. '*\n'
	elseif jdat.zip ~= '' then
		output = output .. jdat.zip .. '\n'
	elseif jdat.city ~= '' then
		output = output .. jdat.city .. '\n'
	elseif jdat.regionName ~= '' then
		output = output .. jdat.regionName .. '\n'
	elseif jdat.country ~= '' then
		output = output .. jdat.country .. '\n'
	end
	mattata.sendMessage(message.chat.id, '`' .. input:gsub('`', '\\`') .. ':`\n' .. output, 'Markdown', true, false, message.message_id)
end

return isp