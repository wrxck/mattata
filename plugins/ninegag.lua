local ninegag = {}
local mattata = require('mattata')
local http = require('socket.http')
local json = require('dkjson')

function ninegag:init(configuration)
	ninegag.arguments = 'ninegag'
	ninegag.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('ninegag').table
	ninegag.help = configuration.commandPrefix .. 'ninegag - Returns a random image from the latest 9gag posts.'
end

function ninegag:onInlineQuery(inline_query, configuration, language)
	local jstr, res = http.request('http://api-9gag.herokuapp.com/')
	if res ~= 200 then
		local results = json.encode({{
			type = 'article',
			id = '1',
			title = 'An error occured!',
			description = language.errors.connection,
			input_message_content = { message_text = language.errors.connection }
		}})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdat = json.decode(jstr)
	local results_list = {}
	local result_id = 1
	for n in pairs(jdat) do
		if jdat[n].src and jdat[n].title then
			local result = {
				type = 'photo',
				id = tostring(result_id),
				photo_url = jdat[n].src,
				thumb_url = jdat[n].src,
				caption = jdat[n].title:gsub('"', '\\"')
			}
			table.insert(results_list, result)
		end
		result_id = result_id + 1
	end
	mattata.answerInlineQuery(inline_query.id, json.encode(results_list), 0)
end

function ninegag:onMessage(message, configuration, language)
	local jstr, res = http.request('http://api-9gag.herokuapp.com/')
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id) return end
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	local jdat = json.decode(jstr)
	local jrnd = math.random(#jdat)
	local keyboard = {}
	keyboard.inline_keyboard = {{{ text = 'Read More', url = jdat[jrnd].url }}}
	mattata.sendPhoto(message.chat.id, jdat[jrnd].src, jdat[jrnd].title, false, message.message_id, json.encode(keyboard))
end

return ninegag