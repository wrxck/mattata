local mchistory = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local JSON = require('dkjson')

function mchistory:init(configuration)
	mchistory.arguments = 'mchistory <Minecraft username>'
	mchistory.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('mchistory').table
	mchistory.help = configuration.commandPrefix .. 'mchistory <Minecraft username> - Returns the name history of a Minecraft username.'
end

function mchistory:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, mchistory.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr_uuid, res_uuid = HTTPS.request('https://api.mojang.com/users/profiles/minecraft/' .. input)
	if res_uuid ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat_uuid = JSON.decode(jstr_uuid)
	local jstr, res = HTTPS.request('https://api.mojang.com/user/profiles/' .. jdat_uuid.id .. '/names')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local output, summary
	for n in pairs(jdat) do
		if n == 1 then
			summary = '*This player has changed their username 1 time:*\n'
			output = mattata.markdownEscape(jdat[n].name)
		else
			summary = '*This player has changed their username ' .. #jdat .. ' times:*\n'
			output = output .. mattata.markdownEscape(jdat[n].name)
		end
		if n < #jdat then
			output = output .. ', '
		end
	end
	mattata.sendMessage(channel_post.chat.id, summary .. output, 'Markdown', true, false, channel_post.message_id)
end

function mchistory:onMessage(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, mchistory.help, nil, true, false, message.message_id)
		return
	end
	local jstr_uuid, res_uuid = HTTPS.request('https://api.mojang.com/users/profiles/minecraft/' .. input)
	if res_uuid ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat_uuid = JSON.decode(jstr_uuid)
	local jstr, res = HTTPS.request('https://api.mojang.com/user/profiles/' .. jdat_uuid.id .. '/names')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local output, summary
	for n in pairs(jdat) do
		if n == 1 then
			summary = '*This player has changed their username 1 time:*\n'
			output = mattata.markdownEscape(jdat[n].name)
		else
			summary = '*This player has changed their username ' .. #jdat .. ' times:*\n'
			output = output .. mattata.markdownEscape(jdat[n].name)
		end
		if n < #jdat then
			output = output .. ', '
		end
	end
	mattata.sendMessage(message.chat.id, summary .. output, 'Markdown', true, false, message.message_id)
end

return mchistory