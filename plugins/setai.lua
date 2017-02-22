--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local setai = {}

local mattata = require('mattata')
local redis = require('mattata-redis')
local json = require('dkjson')

function setai:init()
    setai.commands = mattata.commands(
        self.info.username
    ):command('setai').table
    setai.help = [[/setai - Allows you to select which version of mattata-ai you'd like to use in conversation with mattata.]]
end

function setai.get_keyboard(user_id)
    return mattata.inline_keyboard():row(
        mattata.row():callback_data_button(
            'Cleverbot',
            'setai:' .. user_id .. ':cleverbot'
        ):callback_data_button(
            'Mitsuku',
            'setai:' .. user_id .. ':mitsuku'
        )
    )
end

function setai.set_lang(user_id, locale, language)
    redis:set(
        'ai:' .. user_id .. ':use_cleverbot',
        true,
        locale
    )
    return 'Your language has been set to ' .. language .. '!'
end

function setai.get_lang(user_id)
    local language = redis:hget(
        'user:' .. user_id .. ':language',
        'language'
    )
    if not language then
        language = 'en'
    end
    for k, v in pairs(setai.languages) do
        if k == language then
            language = v
            break
        end
    end
    return 'Your language is currently ' .. language .. '.\nPlease note that this feature is currently in beta and not all string are translated as of yet. If you\'d like to change your language, select one using the keyboard below:'
end

function setai:on_callback_query(callback_query, message)
    local user_id, endpoint = callback_query.data:match('^(.-)%:(.-)$')
    if not user_id or not endpoint then
        return
    end
    if tostring(callback_query.from.id) ~= user_id then
        return
    end
    if endpoint == 'cleverbot' then
        redis:set(
            'ai:' .. user_id .. ':use_cleverbot',
            true
        )
    else
        redis:del('ai:' .. user_id .. ':use_cleverbot')
    end
    local success = mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        'You are currently using the ' .. endpoint:gsub('^%l', string.upper) .. ' AI endpoint.',
        nil,
        true,
        setai.get_keyboard(user_id)
    )
    if not success then
        return mattata.answer_callback_query(
            callback_query.id,
            'You are already using the ' .. endpoint .. ' AI endpoint!'
        )
    end
end

function setai:on_message(message, configuration)
    local endpoint = redis:get('ai:' .. message.from.id .. ':use_cleverbot') and 'Cleverbot' or 'Mitsuku'
    return mattata.send_message(
        message.chat.id,
        'You are currently using the ' .. endpoint .. ' AI endpoint.',
        nil,
        true,
        false,
        nil,
        setai.get_keyboard(message.from.id)
    )
end

return setai