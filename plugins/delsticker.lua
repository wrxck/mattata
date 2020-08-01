--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local delsticker = {}
local mattata = require('mattata')

function delsticker:init()
    delsticker.commands = mattata.commands(self.info.username):command('delsticker').table
    delsticker.help = '/delsticker - Deletes the replied-to sticker from your sticker pack.'
end

function delsticker.on_message(_, message)
    if not message.reply or not message.reply.sticker then
        return mattata.send_reply(message, 'You must use this command in reply to a sticker!')
    elseif message.reply.sticker.is_animated then
        return mattata.send_reply(message, 'I\'m afraid animated stickers aren\'t supported at the moment.')
    end
    local success, res = mattata.delete_sticker_from_set(message.reply.file_id)
    if not success then
        local description = res.description:match('STICKERSET_NOT_MODIFIED') and 'It appears that sticker has already been deleted from your pack!' or 'I don\'t have permission to delete that sticker, are you sure it\'s from your pack?'
        return mattata.send_reply(message, 'An error occurred. ' .. description)
    end
    return mattata.send_reply(message, 'I\'ve successfully removed that sticker from your pack!')
end

return delsticker