local language = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function language:init(configuration)
	language.arguments = 'setlang <language>'
	language.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('setlang'):c('language').table
	language.help = configuration.commandPrefix .. 'setlang <language> - Set your language to the given value. If no value is given, your current language is sent instead.'
end

function setLanguage(user, language)
	local hash = mattata.getUserRedisHash(user, 'language')
	if hash then
		redis:hset(hash, 'language', language)
		return user.first_name .. '\'s language has been set to \'' .. language .. '\'.'
	end
end

function delLanguage(user)
	local hash = mattata.getUserRedisHash(user, 'language')
	if redis:hexists(hash, 'language') == true then
		redis:hdel(hash, 'language')
		return 'Your language has successfully been reset.'
	else
		return 'You don\'t currently have a language!'
	end
end

function getLanguage(user)
	local hash = mattata.getUserRedisHash(user, 'language')
	if hash then
		local language = redis:hget(hash, 'language')
		if not language or language == 'false' then
			return 'Your language is currently \'en\'. Current languages available are: en, es, de, fr, ru, it, lv, pl and ar. Please note that not all strings have been translated yet, but my AI functionality will automatically reply in your language.'
		else
			return 'Your language is currently \'' .. language .. '\'. Current languages available are: en, es, de, fr, ru, it, lv, pl and ar. Please note that not all strings have been translated yet, but my AI functionality will automatically reply in your language.'
		end
	end
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
	'pl'
}

function language:onMessageReceive(message, configuration)
	local input = mattata.input(message.text_lower)
	if not input then
		mattata.sendMessage(message.chat.id, getLanguage(message.from), nil, true, false, message.message_id)
		return
	end
	for k, v in pairs(languages) do
		if input == v then
			mattata.sendMessage(message.chat.id, setLanguage(message.from, input:lower()), nil, true, false, message.message_id)
			return
		end
	end
	mattata.sendMessage(message.chat.id, 'That language is currently unavailable. Current languages available are: en, es, de, fr, ru, it, lv, pl and ar. Please note that not all strings have been translated yet, but my AI functionality will automatically reply in your language.', nil, true, false, message.message_id)
end

return language