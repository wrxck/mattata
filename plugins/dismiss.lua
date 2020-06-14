--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local dismiss = {}
local mattata = require('mattata')

function dismiss.on_callback_query(_, _, message)
    if message then
        return mattata.delete_message(message.chat.id, message.message_id)
    end
    return
end

return dismiss