local ninegag = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
function ninegag:init(configuration)
	ninegag.command = '9gag'
	ninegag.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('9gag', true).table
	ninegag.inline_triggers = ninegag.triggers
	ninegag.documentation = configuration.command_prefix .. '9gag - Returns a random result from the latest 9gag images.'
end
function ninegag:inline_callback(inline_query, configuration)
	local jstr = HTTP.request(configuration.apis.ninegag)
	local jdat = JSON.decode(jstr)
	local results = '['
	local id = 50
	for n in pairs(jdat) do
		local title = jdat[n].title:gsub('"', '\\"')
		results = results .. '{"type":"photo","id":"' .. id .. '","photo_url":"' .. jdat[n].src .. '","thumb_url":"' .. jdat[n].src .. '","caption":"' .. title .. '","reply_markup":{"inline_keyboard":[[{"text":"Read more", "url":"' .. jdat[n].url .. '"}]]}}'
		id = id + 1
		if n < #jdat then
			results = results .. ','
		end
	end
	local results = results .. ']'
	functions.answer_inline_query(inline_query, results, 50)
end
function ninegag:action(msg, configuration)
	telegram_api.sendChatAction{ chat_id = msg.chat.id, action = 'upload_photo' }
	local url = configuration.apis.ninegag
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	local jrnd = math.random(#jdat)
	local link_image = jdat[jrnd].src
	local title = jdat[jrnd].title
	local post_url = jdat[jrnd].url
	functions.send_photo(msg.chat.id, functions.download_to_file(link_image), title, msg.message_id, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. post_url .. '"}]]}')
end
return ninegag