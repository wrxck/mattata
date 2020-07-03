--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local fileid = {}
local mattata = require('mattata')
local id = require('plugins.id')

function fileid:init()
    fileid.commands = mattata.commands(self.info.username):command('fileid'):command('fid').table
    fileid.help = '/fileid - Returns available information about the replied-to media. Alias: /fid.'
end

function fileid.on_message(_, message, _, language)
    if not message.reply or not message.reply.is_media then
        return mattata.send_reply(message, 'You must use this command in reply to a type of media!')
    end
    local info = mattata.unpack_file_id(message.reply.file_id, message.reply.media_type)
    if not next(info) then
        return mattata.send_reply(message, language.errors.generic)
    end
    local output = {}
    for k, v in pairs(info) do
        table.insert(output, k:gsub('_', ' '):gsub('^%l', string.upper) .. ': <code>' .. v .. '</code>')
    end
    if info.user_id then
        local lookup = id.resolve_chat(info.user_id, language, nil, nil, nil, true)
        if lookup then
            table.insert(output, '\nInfo I found about the user:\n')
            for _, line in pairs(lookup) do
                table.insert(output, line)
            end
        else
            table.insert(output, '\nI couldn\'t find information about that user because they haven\'t spoken to me before - try using another ID lookup bot!')
        end
    end
    output = table.concat(output, '\n')
    return mattata.send_reply(message, output, 'html')
end

return fileid