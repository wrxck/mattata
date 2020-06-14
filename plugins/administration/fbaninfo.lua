--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local fbaninfo = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function fbaninfo:init()
    fbaninfo.commands = mattata.commands(self.info.username):command('fbaninfo'):command('fbi').table
    fbaninfo.help = '/fbaninfo [Fed UUID] - View information about the Feds you are banned from. When applicable, specify the UUID of a Fed to see your reason. Alias: /fbi.'
end

function fbaninfo.on_message(_, message)
    local input = mattata.input(message.text)
    input = (input and input:match('^%w+%-%w+%-%w+%-%w+%-%w+$')) and input or false
    if not input then
        local all = redis:keys('fedban:*:' .. message.from.id)
        if #all == 0 then
            return mattata.send_reply(message, 'Looks like you\'ve been good! You\'re not banned from any Feds at the moment.')
        end
        local feds = {}
        for _, fed in pairs(all) do
            fed = fed:match('^fedban:(.-):' .. message.from.id .. '$')
            local title = redis:hget('fed:' .. fed, 'title')
            fed = string.format(mattata.symbols.bullet .. ' ' .. mattata.escape_html(title) .. ' <code>[%s]</code>')
            table.insert(feds, fed)
        end
        feds = table.concat(feds, '\n')
        return mattata.send_reply(message, 'I\'m afraid some admins found your messages annoying and you\'ve been Fed-banned from the followings Feds:\n' .. feds, 'html')
    end
    if not redis:hexists('fed:' .. input, 'date_created') then
        return mattata.send_reply(message, 'It appears the UUID you\'ve specified doesn\'t match an existing Fed! Please check you spelled it correctly, then try again.')
    end
    local title = redis:hget('fed:' .. input, 'title')
    local reason = redis:hget('fedban:' .. input .. ':' .. message.from.id, 'reason')
    local banned_on = redis:hget('fedban:' .. input .. ':' .. message.from.id, 'time')
    if not reason then
        return mattata.send_reply(message, 'Phew! It looks like you\'re not banned from that Fed, at this moment in time!')
    end
    local info = {
        '<b>Fed:</b> <em>' .. mattata.escape_html(title) .. '</em>',
        '<b>Ban reason:</b> <em>' .. mattata.escape_html(reason) .. '</em>'
    }
    if banned_on then
        table.insert(info, '<b>Date of ban:</b> <em>' .. os.date('%x', tonumber(banned_on)) .. '</em>')
    end
    info = table.concat(info, '\n')
    return mattata.send_reply(message, info, 'html')
end

return fbaninfo