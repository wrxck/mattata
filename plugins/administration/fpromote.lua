--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local fpromote = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function fpromote:init()
    fpromote.commands = mattata.commands(self.info.username):command('fpromote'):command('fedpromote'):command('fp').table
    fpromote.help = '/fpromote [user] [fed UUID] - Allows the Fed creator to promote a user (by reply or mention), granting them access to Fed admin commands. If you have multiple feds, please specify the Fed as a second parameter. Aliases: /fedpromote, /fp.'
end

function fpromote:on_message(message)
    local fed, id, multiple = mattata.has_fed(message.from.id)
    local input = mattata.input(message.text)
    local selected
    if message.reply and input then
        input = message.reply.from.id .. ' ' .. input
    end
    input, selected = (message.reply and not input) and tostring(message.reply.from.id) or input, nil
    if input and input:match('^[@%w_]+ ([%w%-]+)$') then
        input, selected = input:match('^([@%w_]+) ([%w%-]+)$')
    elseif not input then
        return mattata.send_reply(message, fpromote.help)
    end
    if not selected and multiple then
        return mattata.send_reply(message, 'Since this group is part of multiple Feds, you need to specify the Fed UUID at the end of your message (i.e. /fpromote @wrxck your-uuid-here). To view Fed UUIDs, send /feds.')
    end
    fed, id = mattata.has_fed(message.from.id, selected)
    if not fed then
        local output = 'You need to have your own Fed in order to use this command!'
        if selected then
            output = 'That\'s not one of your Feds!'
        end
        return mattata.send_reply(message, output)
    elseif not input then
        return mattata.send_reply(message, fpromote.help)
    end
    local user = mattata.get_user(input)
    if not user then
        return mattata.send_reply(message, 'I couldn\'t find any information about that user! Try sending this in reply to one of their messages.')
    elseif user.result.id == message.from.id then
        return mattata.send_reply(message, 'You can\'t promote yourself you donut!')
    elseif user.result.id == self.info.id then
        return mattata.send_reply(message, 'Why do you need to promote me? I control all of the Feds!')
    elseif mattata.is_fed_admin(id, user.result.id) then
        return mattata.send_reply(message, 'That user is already an admin in your Fed!')
    end
    local title = redis:hget('fed:' .. id, 'title')
    redis:sadd('fedadmins:' .. id, user.result.id)
    local output = 'Successfully promoted <b>%s</b> to Fed admin in <b>%s</b> <code>[%s]</code>!'
    output = string.format(output, mattata.escape_html(user.result.first_name), mattata.escape_html(title), id)
    return mattata.send_reply(message, output, 'html')
end

return fpromote