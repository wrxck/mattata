local minecraft = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function minecraft:init(configuration)
	minecraft.arguments = 'minecraft <username>'
	minecraft.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('minecraft').table
	minecraft.help = configuration.commandPrefix .. 'minecraft <username> - Get information about the given Minecraft player.'
end

function minecraft.getUuid(username)
	local jstr, res = https.request('https://api.mojang.com/users/profiles/minecraft/' .. url.escape(username))
	if res ~= 200 then return false end
	local jdat = json.decode(jstr)
	if not jdat.id then return false end
	return jdat.id
end

function minecraft.usernameChangedDate(date)
	local formatDate = io.popen('date -d @' .. date):read('*all')
	formatDate = formatDate:gsub('  ', ' 0'):gsub('\n', '')
	local month, day, time, year = formatDate:match('^%a+ (%a+) (%d+) (%d%d:%d%d):%d%d %a+ (%d%d%d%d)$')
	if day == 1 or day == 21 or day == 31 then day = day .. 'st'
	elseif day == 2 or day == 22 then day = day .. 'nd'
	elseif day == 3 or day == 23 then day = day .. 'rd'
	else day = day .. 'th' end
	return ' <pre>[' .. day:gsub('^0', '') .. ' ' .. month .. ' ' .. year .. ', ' .. time .. ']</pre>'
end

function minecraft.getHistoryPage(usernameHistory, usernameCount, page)
	local pageBeginsAt = tonumber(page) * 5 - 4
	local pageEndsAt = tonumber(pageBeginsAt) + 4
	if tonumber(pageEndsAt) > tonumber(usernameCount) then pageEndsAt = tonumber(usernameCount) end
	local pageUsernames = {}
	for i = tonumber(pageBeginsAt), tonumber(pageEndsAt) do
		table.insert(pageUsernames, usernameHistory[i])
	end
	return table.concat(pageUsernames, '\n')
end

function minecraft.getUsernameHistory(username)
	if not minecraft.getUuid(username) then return false end
	local uuid = minecraft.getUuid(username)
	local jstr, res = https.request('https://api.mojang.com/user/profiles/' .. url.escape(uuid) .. '/names')
	if res ~= 200 then return false end
	local jdat = json.decode(jstr)
	local names = {}
	for n in pairs(jdat) do
		local result = jdat[n].name
		if jdat[n].changedToAt and tonumber(jdat[n].changedToAt) ~= nil then result = result .. minecraft.usernameChangedDate(math.floor(tonumber(jdat[n].changedToAt) / 1000)) end
		table.insert(names, '• ' .. result)
	end
	local output = '<b>' .. username .. ' has changed his/her username ' .. #jdat .. ' time'
	if #jdat ~= 1 then output = output .. 's' end
	return output .. ':</b>\n' .. table.concat(names, '\n'), #names, names
end

function minecraft.getAvatar(username) return '<a href="https://mcapi.ca/avatar/' .. url.escape(username) .. '/128">' .. mattata.htmlEscape(username) .. '</a>' end

function minecraft:onCallbackQuery(callback_query, message, configuration, language)
	if callback_query.data:match('^uuid:(.-)$') then
		local input = callback_query.data:match('^uuid:(.-)$')
		local output = minecraft.getUuid(input)
		if not output then output = language.errors.results end
		local keyboard = {}
		keyboard.inline_keyboard = {{{ text = 'Back', callback_data = 'minecraft:back:' .. input }}}
		mattata.editMessageText(message.chat.id, message.message_id, output, nil, true, json.encode(keyboard))
	elseif callback_query.data:match('^avatar:(.-)$') then
		local input = callback_query.data:match('^avatar:(.-)$')
		local keyboard = {}
		keyboard.inline_keyboard = {{{ text = 'Back', callback_data = 'minecraft:back:' .. input }}}
		mattata.editMessageText(message.chat.id, message.message_id, minecraft.getAvatar(input), 'HTML', false, json.encode(keyboard))
	elseif callback_query.data:match('^history:(.-)$') then
		local input = callback_query.data:match('^history:(.-):')
		local output, amount, usernames = minecraft.getUsernameHistory(input)
		local keyboard = {}
		keyboard.inline_keyboard = {}
		if not output then output = language.errors.results; else
		local newPage = callback_query.data:match(':(%d+)$')
		local pageCount = math.floor(tonumber(amount) / 5) + 1
		if tonumber(newPage) > tonumber(pageCount) then newPage = 1;
		elseif tonumber(newPage) < 1 then newPage = tonumber(pageCount) end
		table.insert(keyboard.inline_keyboard, {
			{ text = '◀️', callback_data = 'minecraft:history:' .. input .. ':' .. math.floor(tonumber(newPage) - 1) },
			{ text = newPage .. '/' .. pageCount, callback_data = 'minecraft:pages:' .. newPage .. ':' .. pageCount },
			{ text = '▶️', callback_data = 'minecraft:history:' .. input .. ':' .. math.floor(tonumber(newPage) + 1) }
		})
		output = minecraft.getHistoryPage(usernames, amount, newPage) end
		table.insert(keyboard.inline_keyboard, {{ text = 'Back', callback_data = 'minecraft:back:' .. input }})
		mattata.editMessageText(message.chat.id, message.message_id, output, 'HTML', true, json.encode(keyboard))
	elseif callback_query.data:match('^back:(.-)$') then
		local input = callback_query.data:match('^back:(.-)$')
		local keyboard = {}
		keyboard.inline_keyboard = {{
			{ text = 'UUID', callback_data = 'minecraft:uuid:' .. input },
			{ text = 'Avatar', callback_data = 'minecraft:avatar:' .. input }
		}, {{ text = 'Username History', callback_data = 'minecraft:history:' .. input .. ':1' }}}
		mattata.editMessageText(message.chat.id, message.message_id, 'Please select an option:', nil, true, json.encode(keyboard))
	end
end

function minecraft:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then mattata.sendMessage(message.chat.id, minecraft.help, nil, true, false, message.message_id); return
	elseif input:len() > 16 or input:len() < 3 then mattata.sendMessage(message.chat.id, 'Minecraft usernames are between 3 and 16 characters long.', nil, true, false, message.message_id); return end
	local keyboard = {}
	keyboard.inline_keyboard = {{
		{ text = 'UUID', callback_data = 'minecraft:uuid:' .. input },
		{ text = 'Avatar', callback_data = 'minecraft:avatar:' .. input }
	}, {{ text = 'Username History', callback_data = 'minecraft:history:' .. input .. ':1' }}}
	mattata.sendMessage(message.chat.id, 'Please select an option:', nil, true, false, message.message_id, json.encode(keyboard))
end

return minecraft