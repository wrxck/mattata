local messaging = {}
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local URL = require('socket.url')
local ltn12 = require('ltn12')
local JSON = require('dkjson')
local mattata = require('mattata')

function messaging:init(configuration)
	messaging.commands = { '' }
end

function messaging:onMessageReceive(message, configuration)
	if message.reply_to_message then
		if message.photo then
			if message.reply_to_message.from.id == self.info.id then
				mattata.sendChatAction(message.chat.id, 'typing')
				local getFile = mattata.getFile(message.photo[1].file_id)
				local url = 'https://api.telegram.org/file/bot' .. configuration.botToken .. '/' .. getFile.result.file_path
				local filePath = configuration.fileDownloadLocation .. os.time() .. url:match('.+/(.-)$')
				local body = {}
				local protocol = HTTP
				local redirect = true
				if url:match('^https') then
					protocol = HTTPS
					redirect = false
				end
				local _, res = protocol.request {
					url = url,
					sink = ltn12.sink.table(body),
					redirect = redirect
				}
				if res ~= 200 then
					mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id)
					return
				end
				local file = io.open(filePath, 'w+')
				file:write(table.concat(body))
				file:close()
				local output = io.popen('./plugins/captionbotai.sh "' .. filePath .. '"'):read('*all')
				os.remove(filePath)
				mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
				return
			end
		end
		if message.text then
			if not string.match(message.text, configuration.commandPrefix) then
				if message.reply_to_message.from.id == self.info.id then
					local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(message.text_lower))
					if res ~= 200 then
						return
					end
					local jdat = JSON.decode(jstr)
					mattata.sendChatAction(message.chat.id, 'typing')
					mattata.sendMessage(message.chat.id, jdat.clever, nil, true, false, message.message_id, nil)
					return
				end
			end
		end
	end
	if message.chat.type ~= 'private' then
		if message.new_chat_member then
			if message.new_chat_member.id ~= self.info.id then
				local randomNew = math.random(5)
				local new
				if randomNew < 2 then
					new = 'Welcome, '
				elseif randomNew == 3 then
					new = 'Hello, '
				elseif randomNew == 4 then
					new = 'Howdy, '
				else
					new = 'Hi, '
				end 
				mattata.sendMessage(message.chat.id, new .. message.new_chat_member.first_name .. '!', nil, true, false, message.message_id, nil)
				return
			else
				mattata.sendMessage(message.chat.id, 'Hello, World! Thanks for adding me, ' .. message.from.first_name .. '!', nil, true, false, message.message_id, nil)
				return
			end
		end
		if message.left_chat_member then
			local randomLeft = math.random(5)
			local left
			if randomLeft < 2 then
				left = 'RIP, '
			elseif randomLeft == 3 then
				left = 'Farewell, '
			elseif randomLeft == 4 then
				left = 'So long, '
			else
				left = 'Goodbye, '
			end
			mattata.sendMessage(message.chat.id, left .. message.left_chat_member.first_name .. '.', nil, true, false, message.message_id, nil)
			return
		end
		if message.migrate_from_chat_id then
			mattata.sendMessage(message.chat.id, message.chat.title .. ' was migrated to a supergroup. The old ID was ' .. message.migrate_from_chat_id .. ', and the new ID is ' .. message.chat.id .. '.', nil, true, false, message.message_id, nil)
			return
		end
		if message.text then
			if string.match(message.text_lower, self.info.first_name .. ' ') and not string.match(message.text, configuration.commandPrefix) then
				local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(message.text))
				if res ~= 200 then
					return
				end
				local jdat = JSON.decode(jstr)
				mattata.sendChatAction(message.chat.id, 'typing')
				mattata.sendMessage(message.chat.id, jdat.clever, nil, true, false, message.message_id, nil)
				return
			end
			if string.match(message.text, '😐😐😐') or string.match(message.text, ':|:|:|') or string.match(message.text, '🌹🌹🌹') or string.match(message.text, '😭😭😭') then -- Credit to @aRandomStranger for this idea.
				mattata.sendMessage(message.chat.id, '*WEEDOW, WEEDOW!*\n_A random, Iranian spammer has been detected!_', 'Markdown', true, false, message.message_id, nil)
				return
			end
			if string.match(message.text_lower, 'how many messages have been sent') then
				mattata.sendMessage(message.chat.id, message.message_id .. ' messages have been sent in this chat!', nil, true, false, nil, nil)
				return
			end
		end
	else
		if not string.match(message.text_lower, configuration.commandPrefix) then
			local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(message.text_lower))
			if res ~= 200 then
				return
			end
			local jdat = JSON.decode(jstr)
			mattata.sendChatAction(message.chat.id, 'typing')
			mattata.sendMessage(message.chat.id, jdat.clever, nil, true, false, message.message_id, nil)
			return
		end
	end
end

return messaging
