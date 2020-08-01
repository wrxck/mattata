--[[
    Based on a plugin by topkecleon. Licensed under GNU AGPLv3
    https://github.com/topkecleon/otouto/blob/master/LICENSE.
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local slap = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function slap:init()
    slap.commands = mattata.commands(self.info.username):command('slap').table
    slap.help = '/slap [target] - Slaps someone, or something. Can be used in reply to someone.'
end

function slap:on_message(message, configuration)
    local input = mattata.input(message)
    local victor, victor_id, victim, victim_id
    local slaps = configuration.slaps
    if message.chat.type ~= 'private' then
        local more = redis:smembers('slaps:' .. message.chat.id)
        if #more > 0 then
            for _, v in pairs(more) do
                table.insert(slaps, v)
            end
        end
    end
    if not input then
        if message.reply then
            victor = message.from.first_name:gsub('%%', '%%%%')
            victor_id = message.from.id
            victim = message.reply.from.first_name:gsub('%%', '%%%%')
            victim_id = message.reply.from.id
        else
            victor = self.info.first_name:gsub('%%', '%%%%')
            victor_id = self.info.id
            victim = message.from.first_name:gsub('%%', '%%%%')
            victim_id = message.from.id
        end
    else
        victor = message.from.first_name:gsub('%%', '%%%%')
        victor_id = message.from.id
        victim = input:gsub('%%', '%%%%')
        victim_id = false
        local success = mattata.get_user(input)
        if success and success.result and success.result.type == 'private' then
            victim = success.result.first_name
            victim = victim:gsub('%%', '%%%%')
            victim_id = success.result.id
        end
    end
    victor = mattata.get_formatted_user(victor_id, victor, 'html')
    victim = victim_id and mattata.get_formatted_user(victim_id, victim, 'html') or mattata.escape_html(victim)
    local output = mattata.escape_html(slaps[math.random(#slaps)])
    output = output:gsub('{THEM}', victim):gsub('{ME}', victor)
    return mattata.send_message(message.chat.id, output, 'html')
end

return slap