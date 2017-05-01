--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local setai = {}
local mattata = require('mattata')
local redis = require('mattata-redis')
local json = require('dkjson')

function setai:init()
    setai.commands = mattata.commands(self.info.username):command('setai').table
    setai.help = '/setai - Allows you to select which version of mattata-ai you\'d like to use in conversation with mattata.'
end

function setai.get_keyboard(user_id, language)
    return mattata.inline_keyboard():row(
        mattata.row()
        :callback_data_button(
            language['setai']['1'],
            'setai:' .. user_id .. ':cleverbot'
        )
        :callback_data_button(
            language['setai']['2'],
            'setai:' .. user_id .. ':mitsuku'
        )
    )
end

function setai:on_callback_query(callback_query, message)
    local user_id, endpoint = callback_query.data:match('^(.-)%:(.-)$')
    if not user_id
    or not endpoint
    then
        return
    end
    if tostring(callback_query.from.id) ~= user_id
    then
        return
    end
    if endpoint == 'cleverbot'
    then
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
        string.format(
            language['setai']['3'],
            endpoint:gsub('^%l', string.upper)
        ),
        nil,
        true,
        setai.get_keyboard(
            user_id,
            language
        )
    )
    if not success
    then
        return mattata.answer_callback_query(
            callback_query.id,
            string.format(
                language['setai']['4'],
                endpoint
            )
        )
    end
end

function setai:on_message(message, configuration, language)
    local endpoint = redis:get('ai:' .. message.from.id .. ':use_cleverbot')
    and language['setai']['1']
    or language['setai']['2']
    return mattata.send_message(
        message.chat.id,
        string.format(
            language['setai']['5'],
            endpoint
        ),
        nil,
        true,
        false,
        nil,
        setai.get_keyboard(
            message.from.id,
            language
        )
    )
end

return setai