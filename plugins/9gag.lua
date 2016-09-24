local ninegag = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
local telegram_api = require('telegram_api')
function ninegag:init(configuration)
	ninegag.command = '9gag'
	ninegag.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('9gag', true).table
	ninegag.doc = configuration.command_prefix .. '9gag - Returns a random result from the latest 9gag images.'
	url = configuration.ninegag_api
end
function ninegag:fetch_result()
	local b, c = HTTP.request(url)
	if c ~= 200 then
		return nil
	end
	local result = JSON.decode(b)
	local i = math.random(#result)
	local link_image = result[i].src
	local title = result[i].title
	local post_url = result[i].url
	return link_image, title, post_url
end
function ninegag:action(msg, configuration)
	functions.send_action(msg.chat.id, 'upload_photo')
	local url, title, post_url = ninegag:fetch_result()
	if not url then
		functions.send_reply(msg, '`' .. configuration.errors.connection .. '`', true)
		return
	end
	functions.send_photo(msg.chat.id, functions.download_to_file(url), title, msg.message_id, '{"inline_keyboard":[[{"text":"Read more", "url":"' .. post_url .. '"}]]}')
end
return ninegag