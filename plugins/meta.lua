--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local meta = {}
local mattata = require('mattata')

function meta:init()
    meta.commands = mattata.commands(self.info.username):command('meta').table
    meta.help = '/meta - Instructs users not to ask to ask, but just to ask.'
end

function meta.on_message(_, message)
    local send_as_reply = false
    local original_message = message.message_id
    if message.reply then
        message.message_id = message.reply.message_id
        send_as_reply = true
    end
    local method = send_as_reply == true and mattata.send_reply or mattata.send_message
    mattata.delete_message(message.chat.id, original_message)
    local output = [[Please don't ask meta-questions, like:

`"Any user of $x here?"`
`"Anyone used technology $y?"`
`"Hello I need help on $z"`

Just ask a *direct question* about your problem, and the probability that someone will help is pretty high.
[Read more.](http://catb.org/~esr/faqs/smart-questions.html)]]
    return method(message, output, true)
end

return meta