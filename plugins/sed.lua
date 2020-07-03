--[[
    Based on a plugin by topkecleon. Licensed under GNU AGPLv3
    https://github.com/topkecleon/otouto/blob/master/LICENSE.
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local sed = {}
local mattata = require('mattata')
local re = require('re')
local regex = require('rex_pcre')

function sed:init()
    sed.commands = { '^[sS]/.-/.-/?.?$' }
    sed.help = 's/pattern/substitution - Replaces all occurences, of text matching a given Lua pattern, with the given substitution.'
end

local compiled = re.compile[[
invocation <- 's/' {~ pcre ~} '/' {~ replace ~} ('/' modifiers)? !.
pcre <- ( [^\/] / slash / '\' )*
replace <- ( [^\/%$] / percent / slash / capture / '\' / '$' )*

modifiers <- { flags? } {~ matches? ~} {~ probability? ~}

flags <- ('i' / 'm' / 's' / 'x' / 'U' / 'X')+
matches <- ('#' {[0-9]+}) -> '%1'
probability <- ('%' {[0-9]+}) -> '%1'

slash <- ('\' '/') -> '/'
percent <- '%' -> '%%%%'
capture <- ('$' {[0-9]+}) -> '%%%1'
]]

function sed:on_callback_query(callback_query, message, configuration, language)
    if not message.reply then
        return mattata.delete_message(message.chat.id, message.message_id)
    elseif mattata.is_global_admin(callback_query.from.id) then -- we'll pull a sneaky on them
        callback_query.from = message.reply.from
    elseif message.reply.from.id ~= callback_query.from.id then
        return mattata.answer_callback_query(callback_query.id, 'That\'s not your place to say!')
    end
    local output = string.format(
        '<b>%s:</b>\n%s',
        message.text:match('^(.-):'),
        message.text:match(':\n(.-)$')
    )
    if callback_query.data:match('^no$') then
        output = string.format(
            language['sed']['1'],
            output,
            mattata.escape_html(callback_query.from.first_name)
        )
    elseif callback_query.data:match('^yes$') then
        output = string.format(
            language['sed']['2'],
            output,
            mattata.escape_html(callback_query.from.first_name)
        )
    elseif callback_query.data:match('^maybe$') then
        output = string.format(
            language['sed']['3'],
            output,
            mattata.escape_html(callback_query.from.first_name)
        )
    end
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        output,
        'html'
    )
end

function sed:on_message(message, _, language)
    if not message.reply then
        return false
    elseif message.reply.from.id == self.info.id then
        return mattata.send_reply(
            message,
            language['sed']['4'],
            'html'
        )
    end
    local input = message.reply.text
    local text = message.text:match('^[sS]/(.*)$')
    if not text then
        return false
    end
    text = 's/' .. text
    local pattern, replace, flags, matches, probability = compiled:match(text)
    if not pattern then
        return false
    end
    if matches then matches = tonumber(matches) end
    if probability then probability = tonumber(probability) end
    if probability then
        if not matches then
            matches = function()
                return math.random() * 100 < probability
            end
        else
            local remaining = matches
            matches = function()
                local temp
                if remaining > 0 then
                    temp = nil
                else
                    temp = 0
                end
                remaining = remaining - 1
                return math.random() * 100 < probability, temp
            end
        end
    end
    local success, result, matched = pcall(function ()
        return regex.gsub(input, pattern, replace, matches, flags)
    end)
    if success == false then
        return mattata.send_reply(
            message,
            string.format(
                '%s is invalid PCRE regex syntax!',
                mattata.escape_html(text)
            ),
            'html'
        )
    elseif matched == 0 then
        return
    end
    result = mattata.trim(result)
    if not result or result == '' then
        return false
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            language['sed']['6'],
            mattata.escape_html(message.reply.from.first_name),
            mattata.escape_html(result)
        ),
        'html',
        true,
        false,
        message.reply.message_id,
        mattata.inline_keyboard():row(
            mattata.row():callback_data_button(
                utf8.char(128077),
                'sed:yes'
            ):callback_data_button(
                utf8.char(128078),
                'sed:no'
            ):callback_data_button(
                '¯\\_(ツ)_/¯',
                'sed:maybe'
            )
        )
    )
end

return sed