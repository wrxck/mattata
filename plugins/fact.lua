local fact = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function fact:init(configuration)
	fact.arguments = 'fact'
	fact.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('fact').table
	fact.help = configuration.commandPrefix .. 'fact - Returns a random fact!'
end

function fact:onCallbackQuery(callback_query, message, language)
	if callback_query.data == 'fact' then
		local jstr, res = HTTP.request('http://mentalfloss.com/api/1.0/views/amazing_facts.json?limit=5000')
		if res ~= 200 then
			mattata.editMessageText(message.chat.id, message.message_id, language.errors.connection, nil, true)
			return
		end
		local jdat = JSON.decode(jstr)
		local jrnd = math.random(#jdat)
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'Generate another',
					callback_data = 'fact'
				}
			}
		}
		mattata.editMessageText(message.chat.id, message.message_id, jdat[jrnd].nid:gsub('&lt;', ''):gsub('<p>', ''):gsub('</p>', ''):gsub('<em>', ''):gsub('</em>', ''), nil, true, JSON.encode(keyboard))
	end
end

function fact:onChannelPost(channel_post, configuration)
	local jstr, res = HTTP.request('http://mentalfloss.com/api/1.0/views/amazing_facts.json?limit=5000')
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local jrnd = math.random(#jdat)
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Generate another',
				callback_data = 'fact'
			}
		}
	}
	mattata.sendMessage(channel_post.chat.id, jdat[jrnd].nid:gsub('&lt;', ''):gsub('<p>', ''):gsub('</p>', ''):gsub('<em>', ''):gsub('</em>', ''), nil, true, false, channel_post.message_id, JSON.encode(keyboard))
end

function fact:onMessage(message, language)
	local jstr, res = HTTP.request('http://mentalfloss.com/api/1.0/views/amazing_facts.json?limit=5000')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local jrnd = math.random(#jdat)
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Generate another',
				callback_data = 'fact'
			}
		}
	}
	mattata.sendMessage(message.chat.id, jdat[jrnd].nid:gsub('&lt;', ''):gsub('<p>', ''):gsub('</p>', ''):gsub('<em>', ''):gsub('</em>', ''), nil, true, false, message.message_id, JSON.encode(keyboard))
end

return fact