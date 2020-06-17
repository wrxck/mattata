--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local myfeds = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function myfeds:init()
    myfeds.commands = mattata.commands(self.info.username):command('myfeds'):command('mf').table
    myfeds.help = '/myfeds - View a list of Feds you own/administrate. Alias: /mf.'
end

function myfeds.on_message(_, message)
    local feds = redis:keys('fed:*')
    local admins = redis:keys('fedadmins:*')
    local owned = {}
    local administrate = {}
    local output = { '<b>You currently own the following Feds:</b>\n' }
    for _, fed in pairs(feds) do
        if redis:hget(fed, 'creator') == tostring(message.from.id) then
            table.insert(owned, fed:match('^fed:(.-)$'))
        end
    end
    if #owned == 0 then
        table.insert(output, '<em>None</em>')
    else
        for _, fed in pairs(owned) do
            local title = redis:hget('fed:' .. fed, 'title')
            table.insert(output, '<em>' .. mattata.escape_html(title) .. '</em> <code>[' .. fed .. ']</code>')
        end
    end
    for _, fed in pairs(admins) do
        if redis:sismember(fed, message.from.id) and not mattata.is_fed_creator(fed:match('^fedadmins:(.-)$'), message.from.id) then
            table.insert(administrate, fed:match('^fedadmins:(.-)$'))
        end
    end
    table.insert(output, '\n<b>You currently administrate the following Feds:</b>\n')
    if #administrate == 0 then
        table.insert(output, '<em>None</em>')
    else
        for _, fed in pairs(administrate) do
            local title = redis:hget('fed:' .. fed, 'title')
            table.insert(output, '<em>' .. mattata.escape_html(title) .. '</em> <code>[' .. fed .. ']</code>')
        end
    end
    output = table.concat(output, '\n')
    return mattata.send_reply(message, output, 'html')
end

return myfeds