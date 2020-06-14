--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local fdemote = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function fdemote:init()
    fdemote.commands = mattata.commands(self.info.username):command('fdemote'):command('feddemote'):command('fd').table
    fdemote.help = '/fdemote [user] - Allows the Fed creator to demote a user (by reply or mention), removing their access to Fed admin commands. If you have multiple feds, please specify the Fed as a second parameter, if not it will pick your first one. Aliases: /feddemote, /fd.'
end

function fdemote:on_message(message, configuration, language)
    local fed, id = mattata.has_fed(message.from.id)
    local input = mattata.input(message.text)
    if message.reply and input then
        input = message.reply.from.id .. ' ' .. input
    end
    local input, selected = (message.reply and not input) and tostring(message.reply.from.id) or input, nil
    if input:match('^[@%w_]+ ([%w%-]+)$') then
        input, selected = input:match('^([@%w_]+) ([%w%-]+)$')
    end
    fed, id = mattata.has_fed(message.from.id, selected)
    if not fed then
        local output = 'You need to have your own Fed in order to use this command!'
        if selected then
            output = 'That\'s not one of your Feds!'
        end
        return mattata.send_reply(message, output)
    elseif not input then
        return mattata.send_reply(message, fdemote.help)
    end
    local user = mattata.get_user(input)
    if not user then
        return mattata.send_reply(message, 'I couldn\'t find any information about that user! Try sending this in reply to one of their messages.')
    elseif user.result.id == message.from.id then
        return mattata.send_reply(message, 'You can\'t demote yourself you donut!')
    elseif user.result.id == self.info.id then
        return mattata.send_reply(message, 'Why do you need to demote me? I control all of the Feds!')
    elseif not mattata.is_fed_admin(id, user.result.id) then
        return mattata.send_reply(message, 'That user isn\'t an admin in your Fed anyway!')
    end
    local title = redis:hget('fed:' .. id, 'title')
    redis:srem('fedadmins:' .. id, user.result.id)
    local output = 'Successfully demoted <b>%s</b> from Fed admin in <b>%s</b> <code>[%s]</code>!'
    output = string.format(output, mattata.escape_html(user.result.first_name), mattata.escape_html(title), id)
    return mattata.send_reply(message, output, 'html')
end

return fdemote