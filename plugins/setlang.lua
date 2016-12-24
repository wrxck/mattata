local setlang = {}
local mattata = require('mattata')
local json = require('dkjson')
local redis = require('mattata-redis')

function setlang:init(configuration)
	setlang.arguments = 'setlang <language>'
	setlang.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('setlang').table
	setlang.help = configuration.commandPrefix .. 'setlang <language> - Set your language to the given value.'
end

local languages = {
	'en',
	'fr',
	'es',
	'de',
	'ar',
	'ru',
	'it',
	'lv',
	'pl',
	'pt'
}

function setlang.setLanguage(user, language)
	local hash = mattata.getUserRedisHash(user, 'language')
	if hash then
		redis:hset(hash, 'language', language)
		return user.first_name .. '\'s language has been set to \'' .. language .. '\'.'
	end
end

function setlang.getLanguage(user)
	local hash = mattata.getUserRedisHash(user, 'language')
	if hash then
		local language = redis:hget(hash, 'language')
		if not language or language == 'false' then
			return 'Your language is currently \'en\'. Current languages available are: ' .. table.concat(languages, ', ') .. '. Please note that not all strings have been translated yet, but my AI functionality will automatically reply in your language.'
		else
			return 'Your language is currently \'' .. language .. '\'. Current languages available are: ' .. table.concat(languages, ', ') .. '. Please note that not all strings have been translated yet, but my AI functionality will automatically reply in your language.'
		end
	end
end

function setlang:onMessage(message, configuration)
	local input = mattata.input(message.text_lower)
	local keyboard = {
		one_time_keyboard = true,
		selective = true,
		resize_keyboard_keyboard = true,
		keyboard = {}
	}
	if not input then
		for k, v in pairs(languages) do table.insert(keyboard.keyboard, {{ text = configuration.commandPrefix .. 'setlang ' .. v }}) end
		table.insert(keyboard.keyboard, {{ text = 'Cancel' }})
		mattata.sendMessage(message.chat.id, setlang.getLanguage(message.from), nil, true, false, message.message_id, json.encode(keyboard))
		return
	end
	for k, v in pairs(languages) do
		if input == v then
			mattata.sendMessage(message.chat.id, setlang.setLanguage(message.from, input), nil, true, false, message.message_id, json.encode({ remove_keyboard = true }))
			return
		end
	end
	mattata.sendMessage(message.chat.id, 'That language is currently unavailable. Current languages available are: ' .. table.concat(languages, ', ') .. '. Please note that not all strings have been translated yet, but my AI functionality will automatically reply in your language.', nil, true, false, message.message_id)
end

return setlang