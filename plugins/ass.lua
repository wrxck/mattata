local ass = {}
local HTTP = require('dependencies.socket.http')
local JSON = require('dependencies.dkjson')
local functions = require('functions')
function ass:init(configuration)
	ass.command = 'ass (id)'
	ass.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('ass', true).table
	ass.documentation = configuration.command_prefix .. 'ass (id) - If no arguments are given, returns a random picture of some ass. If an ID is specified as an argument, returns the specific ass that matches the inputted ID.'
end
function ass:action(msg, configuration)
	if msg.chat.type == 'private' then
		local jstr, res = HTTP.request(configuration.apis.ass.noise)
		local input = tonumber(functions.input(msg.text))
		if res ~= 200 then
			functions.send_reply(msg, configuration.errors.connection)
			return
		end
		local jdat = ''
		if not input then
			jdat = JSON.decode(jstr)
			output = configuration.apis.ass.media .. jdat[1].preview
			functions.send_action(msg.chat.id, 'upload_photo')
			functions.send_photo(msg.chat.id, functions.download_to_file(output), 'Image #' .. tonumber(jdat[1].id), msg.message_id)
			return
		elseif input < 7 then 
			jdat = JSON.decode(jstr)
			output = configuration.apis.ass.media .. jdat[1].preview
			functions.send_action(msg.chat.id, 'upload_photo')
			functions.send_photo(msg.chat.id, functions.download_to_file(output), 'That ID doesn\'t belong to an image, so here is: Image #' .. tonumber(jdat[1].id), msg.message_id)
			return
		elseif input > 3990 then
			jdat = JSON.decode(jstr)
			output = configuration.apis.ass.media .. jdat[1].preview
			functions.send_action(msg.chat.id, 'upload_photo')
			functions.send_photo(msg.chat.id, functions.download_to_file(output), 'That ID doesn\'t belong to an image, so here is: Image #' .. tonumber(jdat[1].id), msg.message_id)
			return
		elseif tonumber(input) == nil then
			jdat = JSON.decode(jstr)
			output = configuration.apis.ass.media .. jdat[1].preview
			functions.send_action(msg.chat.id, 'upload_photo')
			functions.send_photo(msg.chat.id, functions.download_to_file(output), 'That ID doesn\'t belong to an image, so here is: Image #' .. tonumber(jdat[1].id), msg.message_id)
			return
		else
			local input = tonumber(functions.input(msg.text))
			local jstr, res = HTTP.request(configuration.apis.ass.get .. input)
			jdat = JSON.decode(jstr)
			output = configuration.apis.ass.media .. jdat[1].preview
			if res ~= 200 then
				functions.send_reply(msg, configuration.errors.connection)
				return
			end
			functions.send_action(msg.chat.id, 'upload_photo')
			functions.send_photo(msg.chat.id, functions.download_to_file(output), 'Image #' .. tonumber(jdat[1].id), msg.message_id)
			return
		end
	else
		functions.send_reply(msg, 'Since this is NSFW, please execute this command in a private chat with me.', false, '{"inline_keyboard":[[{"text":"Take me there!", "url":"http://telegram.me/' .. self.info.username .. '?start=ass"}]]}')
		return
	end
end
return ass