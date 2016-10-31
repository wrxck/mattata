local messaging = {}
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function messaging:init(configuration)
	messaging.commands = { '' }
end

function messaging:onMessageReceive(msg, configuration)
	if msg.chat.type ~= 'private' then
		if msg.new_chat_member then
			if msg.new_chat_member.id ~= self.info.id then
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
				mattata.sendMessage(msg.chat.id, new .. msg.new_chat_member.first_name .. '!', nil, true, false, msg.message_id, nil)
				return
			else
				mattata.sendMessage(msg.chat.id, 'Hello, World! Thanks for adding me, ' .. msg.from.first_name .. '!', nil, true, false, msg.message_id, nil)
				return
			end
		end
		if msg.left_chat_member then
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
			mattata.sendMessage(msg.chat.id, left .. msg.left_chat_member.first_name .. '.', nil, true, false, msg.message_id, nil)
			return
		end
		if msg.migrate_from_chat_id then
			mattata.sendMessage(msg.chat.id, msg.chat.title .. ' was migrated to a supergroup. The old ID was ' .. msg.migrate_from_chat_id .. ', and the new ID is ' .. msg.chat.id .. '.', nil, true, false, msg.message_id, nil)
			return
		end
		if msg.text then
			if string.match(msg.text_lower, self.info.first_name .. ' ') and not string.match(msg.text, configuration.commandPrefix) then
				local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(msg.text))
				if res ~= 200 then
					return
				end
				local jdat = JSON.decode(jstr)
				mattata.sendChatAction(msg.chat.id, 'typing')
				mattata.sendMessage(msg.chat.id, jdat.clever, nil, true, false, msg.message_id, nil)
				return
			end
			if string.match(msg.text, '😐😐😐') or string.match(msg.text, ':|:|:|') or string.match(msg.text, '🌹🌹🌹') or string.match(msg.text, '😭😭😭') then -- Credit to @aRandomStranger for this idea.
				mattata.sendMessage(msg.chat.id, '*WEEDOW, WEEDOW!*\n_A random, Iranian spammer has been detected!_', 'Markdown', true, false, msg.message_id, nil)
				return
			end
			if string.match(msg.text_lower, 'how many messages have been sent') then
				mattata.sendMessage(msg.chat.id, msg.message_id .. ' messages have been sent in this chat!', nil, true, false, nil, nil)
				return
			end
			if string.match(msg.text_lower, 'xdddd') then
				mattata.sendMessage(msg.chat.id, 'xXDDdDd', nil, true, false, nil, nil)
				return
			end
			if string.match(msg.text_lower, 'hahahaha') then
				mattata.sendMessage(msg.chat.id, 'aAHhAHhAhahahaahh!!1', nil, true, false, nil, nil)
				return
			end
			if string.match(msg.text_lower, ' ayy') or string.match(msg.text_lower, 'ayy ') or msg.text_lower == 'ayy' then -- Credit to @zackpollard for this idea.
				mattata.sendMessage(msg.chat.id, 'lmao', nil, true, false, nil, nil)
				return
			end
			if string.match(msg.text_lower, ' lmao') or string.match(msg.text_lower, 'lmao ') or msg.text_lower == 'lmao' then -- Credit to @zackpollard for this idea.
				mattata.sendMessage(msg.chat.id, 'ayy', nil, true, false, nil, nil)
				return
			end
			if string.match(msg.text_lower, ' rip') or string.match(msg.text_lower, 'rip ') or msg.text_lower == 'rip' then -- Credit to @zackpollard for this idea.
				mattata.sendMessage(msg.chat.id, 'in pieces', nil, true, false, nil, nil)
				return
			end
		end
	else
		if not string.match(msg.text_lower, configuration.commandPrefix) then
			local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(msg.text_lower))
			if res ~= 200 then
				return
			end
			local jdat = JSON.decode(jstr)
			mattata.sendChatAction(msg.chat.id, 'typing')
			mattata.sendMessage(msg.chat.id, jdat.clever, nil, true, false, msg.message_id, nil)
			return
		end
	end
	if msg.reply_to_message then
		if msg.text then
			if not string.match(msg.text, configuration.commandPrefix) then
				if msg.reply_to_message.from.id == self.info.id then
					local jstr, res = HTTPS.request(configuration.messaging.url .. URL.escape(msg.text_lower))
					if res ~= 200 then
						return
					end
					local jdat = JSON.decode(jstr)
					mattata.sendChatAction(msg.chat.id, 'typing')
					mattata.sendMessage(msg.chat.id, jdat.clever, nil, true, false, msg.message_id, nil)
				end
			end
			if msg.text_lower:match('s/.-/.-$') then
				local output = msg.reply_to_message.text
				if msg.reply_to_message.from.id == self.info.id then
					output = output:gsub('Did you mean:\n"', '')
					output = output:gsub('"$', '')
				end
				local pattern, substitution = msg.text:match('s/(.-)/(.-)$')
				if not substitution then
					return true
				end
				local res
				res, output = pcall(
					function()
						return output:gsub(pattern, substitution)
					end
				)
				if res == false then
					mattata.sendMessage(msg.chat.id, 'Invalid pattern.', nil, true, false, msg.message_id, nil)
				else
					local random = math.random(1, 3)
					local message
					if random == 1 then
						message = '*Uh... ' .. msg.reply_to_message.from.first_name .. '? Are you sure you didn\'t mean:*\n' .. mattata.trim(output)
					elseif random == 2 then
						message = '*It appears I am going to have to quickly intervene!* ' .. msg.reply_to_message.from.first_name .. '? Hello? Are you there? ' .. msg.from.first_name .. ' seems to believe you made a mistake, are you SURE you didn\'t mean:\n' .. mattata.trim(output)
					else
						message = '*Ugh. ' .. msg.reply_to_message.from.first_name .. '?? I\'m pretty sure you\'re mistaken mate, are ya\' sure you weren\'t trying to say:*\n' .. mattata.trim(output)
					end
					mattata.sendMessage(msg.chat.id, message, 'Markdown', true, false, msg.message_id, nil)
				end
			end
		end
	end
end

return messaging
