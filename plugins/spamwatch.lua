--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local spamwatch = {}
local mattata = require('mattata')

function spamwatch:init()
    spamwatch.commands = mattata.commands(self.info.username):command('spamwatch'):command('sw').table
    spamwatch.help = '/spamwatch [user] - Returns SpamWatch information for the given user, either specified or replied-to. Alias: /sw.'
end

function spamwatch:on_new_message(message, configuration, language)
    if message.chat.type == 'private' then
        return false
    elseif not mattata.get_setting(message.chat.id, 'ban spamwatch users') then
        return false
    elseif self.is_spamwatch_blocklisted then
        mattata.ban_chat_member(message.chat.id, message.from.id)
    end
    return false
end

function spamwatch:on_message(message, configuration, language)
    local input = message.reply and message.reply.from.id or mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, spamwatch.help)
    end
    local user = mattata.get_user(input)
    if not user then
        if not input:match('^%d+$') then
            return mattata.send_reply(message, 'I couldn\'t get any information about that user. To teach me who they are, forward a message from them. This will only work if they don\'t have forward privacy enabled!')
        end
        user = { ['result'] = { ['id'] = input:match('^(%d+)$') } }
    end
    user = user.result.id
    local res, jdat = mattata.is_spamwatch_blocklisted(user)
    if not res then
        return mattata.send_reply(message, 'That user isn\'t in the SpamWatch database!')
    end
    local output = {
        '<b>ID:</b> ' .. jdat.id,
        '<b>Reason:</b> ' .. mattata.escape_html(jdat.reason),
        '<b>Date banned:</b> ' .. os.date('%x', jdat.date)
    }
    output = table.concat(output, '\n')
    return mattata.send_reply(message, output, 'html')
end

return spamwatch