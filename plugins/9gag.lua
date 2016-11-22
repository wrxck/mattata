local ninegag = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local JSON = require('dkjson')

function ninegag:init(configuration)
	ninegag.arguments = '9gag'
	ninegag.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('9gag').table
	ninegag.inlineCommands = ninegag.commands
	ninegag.help = configuration.commandPrefix .. '9gag - Returns a random result from the latest 9gag images.'
end

function ninegag:onInlineQuery(inline_query, language)
	local jstr, res = HTTP.request('http://api-9gag.herokuapp.com/')
	if res ~= 200 then
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.connection,
				input_message_content = {
					message_text = language.errors.connection
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdat = JSON.decode(jstr)
	local resultsList = {}
	local resultId = 1
	for n in pairs(jdat) do
		if jdat[n].src and jdat[n].title then
			local result = {
				type = 'photo',
				id = tostring(resultId),
				photo_url = jdat[n].src,
				thumb_url = jdat[n].src,
				caption = jdat[n].title:gsub('"', '\\"')
			}
			table.insert(resultsList, result)
		end
		resultId = resultId + 1
	end
	mattata.answerInlineQuery(inline_query.id, JSON.encode(resultsList), 0)
end

function ninegag:onChannelPost(channel_post, configuration)
	local jstr, res = HTTP.request('http://api-9gag.herokuapp.com/')
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
				text = 'Read more',
				url = jdat[jrnd].url
			}
		}
	}
	mattata.sendPhoto(channel_post.chat.id, jdat[jrnd].src, jdat[jrnd].title, false, channel_post.message_id, JSON.encode(keyboard))
end

function ninegag:onMessage(message, language)
	local jstr, res = HTTP.request('http://api-9gag.herokuapp.com/')
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	local jdat = JSON.decode(jstr)
	local jrnd = math.random(#jdat)
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Read more',
				url = jdat[jrnd].url
			}
		}
	}
	mattata.sendPhoto(message.chat.id, jdat[jrnd].src, jdat[jrnd].title, false, message.message_id, JSON.encode(keyboard))
end

return ninegag