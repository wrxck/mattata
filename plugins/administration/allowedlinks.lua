--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local allowedlinks = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function allowedlinks:init()
    allowedlinks.commands = mattata.commands(self.info.username):command('allowedlinks'):command('al').table
    allowedlinks.help = '/allowedlinks - View the Telegram invite links you\'re allowed to send in this chat. Alias: /al.'
end

function allowedlinks:on_message(message, _, language)
    if message.chat.type ~= 'supergroup' then
        return mattata.send_reply(message, language.errors.supergroup)
    elseif not mattata.get_setting(message.chat.id, 'antilink') then
        return mattata.send_reply(message, 'You\'re as free as a bird! Feel free to send any links in this chat (make sure you check the `/rules` first!). Admins can setup anti-link by using `/settings`, enabling `Anti-Link` and sending `/allowlink <links>`.', true)
    end
    local allowed = redis:keys('allowlisted_links:' .. message.chat.id .. ':*')
    local output = { 'You\'re allowed to send the following links in this group:\n' }
    if #allowed == 0 then
        return mattata.send_reply(message, 'There are no allowlisted groups here. Admins can allowlist Telegram links (or @username) by sending `/allowlink <links>`.', true)
    end
    for _, link in pairs(allowed) do
        link = link:match('^allowlisted_links:' .. tostring(message.chat.id):gsub('%-', '%%-') .. ':(.-)$')
        link = 't.me/' .. link
        table.insert(output, mattata.symbols.bullet .. ' ' .. link)
    end
    output = table.concat(output, '\n')
    return mattata.send_reply(message, output, nil, true)
end

return allowedlinks