--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local setlang = {}

local mattata = require('mattata')
local redis = require('mattata-redis')
local json = require('dkjson')

function setlang:init(configuration)
    setlang.arguments = 'setlang <locale>'
    setlang.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('setlang').table
    setlang.help = configuration.command_prefix .. 'setlang <locale> - Set your language to the given locale.'
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

function setlang.set_lang(user, language)
    local hash = mattata.get_user_redis_hash(
        user,
        'language'
    )
    if hash then
        redis:hset(
            hash,
            'language',
            language
        )
        return user.first_name .. '\'s language has been set to \'' .. language .. '\'.'
    end
end

function setlang.get_lang(user)
    local hash = mattata.get_user_redis_hash(
        user,
        'language'
    )
    if hash then
        local language = redis:hget(
            hash,
            'language'
        )
        if not language or language == 'false' then
            return 'Your language is currently \'en\'. Current languages available are: ' .. table.concat(
                languages,
                ', '
            ) .. '. Please note that not all strings have been translated yet, but my AI functionality will automatically reply in your language.'
        else
            return 'Your language is currently \'' .. language .. '\'. Current languages available are: ' .. table.concat(
                languages,
                ', '
            ) .. '. Please note that not all strings have been translated yet, but my AI functionality will automatically reply in your language.'
        end
    end
end

function setlang:on_message(message, configuration)
    local input = mattata.input(message.text_lower)
    local keyboard = {
        ['one_time_keyboard'] = true,
        ['selective'] = true,
        ['resize_keyboard'] = true,
        ['keyboard'] = {}
    }
    if not input then
        for k, v in pairs(languages) do
            table.insert(
                keyboard.keyboard,
                {
                    {
                        ['text'] = configuration.command_prefix .. 'setlang ' .. v
                    }
                }
            )
        end
        table.insert(
            keyboard.keyboard,
            {
                {
                    ['text'] = 'Cancel'
                }
            }
        )
        return mattata.send_message(
            message.chat.id,
            setlang.get_lang(message.from),
            nil,
            true,
            false,
            nil,
            json.encode(keyboard)
        )
    end
    for k, v in pairs(languages) do
        if input == v then
            return mattata.send_message(
                message.chat.id,
                setlang.set_lang(
                    message.from,
                    input
                ),
                nil,
                true,
                false,
                nil,
                json.encode(
                    {
                        ['remove_keyboard'] = true
                    }
                )
            )
        end
    end
    return mattata.send_reply(
        message,
        'That language is currently unavailable. Current languages available are: ' .. table.concat(
            languages,
            ', '
        ) .. '. Please note that not all strings have been translated yet, but my AI functionality will automatically reply in your language.'
    )
end

return setlang