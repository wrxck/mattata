--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local setlang = {}

local mattata = require('mattata')
local redis = require('mattata-redis')
local json = require('dkjson')

function setlang:init(configuration)
    setlang.arguments = 'setlang'
    setlang.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('setlang').table
    setlang.help = '/setlang - Set your language.'
end

setlang.languages = {

    ['en'] = 'English 🇬🇧',

    ['it'] = 'Italiano 🇮🇹',

    ['es'] = 'Español 🇪🇸',

    ['pt'] = 'Português 🇧🇷',

    ['ru'] = 'Русский 🇷🇺',

    ['de'] = 'Deutsch 🇩🇪',

    ['ar'] = 'العربية 🇸🇩',

    ['fr'] = 'Français 🇫🇷',

    ['nl'] = 'Dutch 🇱🇺',

    ['lv'] = 'Latvijas 🇱🇻',

    ['pl'] = 'Polskie 🇵🇱'

}

function setlang.get_keyboard(user_id)
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    for k, v in pairs(setlang.languages) do
        table.insert(
            keyboard.inline_keyboard,
            {
                {
                    ['text'] = v,
                    ['callback_data'] = 'setlang:' .. user_id .. ':' .. k
                }
            }
        )
    end
    return keyboard
end

function setlang.set_lang(user_id, language)
    redis:hset(
        'user:' .. user_id .. ':language',
        'language',
        language
    )
    return 'Your language has been set to ' .. language .. '!'
end

function setlang.get_lang(user_id)
    local language = redis:hget(
        'user:' .. user_id .. ':language',
        'language'
    )
    if not language then
        language = 'en'
    end
    for k, v in pairs(setlang.languages) do
        if k == language then
            language = v
            break
        end
    end
    return 'Your language is currently ' .. language .. '.\nPlease note that this feature is currently in beta and not all string are translated as of yet. If you\'d like to change your language, select one using the keyboard below:'
end

function setlang:on_callback_query(callback_query, message)
    local user_id, new_language = callback_query.data:match('^(.-)%:(.-)$')
    if not user_id or not new_language then
        return
    end
    local keyboard = setlang.get_keyboard(user_id)
    local output = setlang.set_lang(user_id, new_language)
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        output,
        nil,
        true,
        json.encode(keyboard)
    )
end

function setlang:on_message(message, configuration, language)
    if message.chat.type ~= 'private' then
        return mattata.send_reply(
            message,
            language.setlang['112']
        )
    end
    local keyboard = setlang.get_keyboard(message.from.id)
    local current = setlang.get_lang(message.from.id)
    return mattata.send_reply(
        message,
        current,
        nil,
        true,
        json.encode(keyboard)
    )
end

return setlang