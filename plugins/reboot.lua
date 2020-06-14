--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local reboot = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function reboot:init()
    reboot.commands = mattata.commands(self.info.username):command('reboot'):command('shutdown'):command('reload').table
end

function reboot:on_message(message)
    if not mattata.is_global_admin(message.from.id) or message.date < (os.time() - 2) then
        return false
    end
    if message.command == 'reload' then
        for pkg, _ in pairs(package.loaded) do -- Disable all of mattata's plugins and languages.
            if pkg:match('^plugins%.') or pkg:match('^languages%.') then
                package.loaded[pkg] = nil
            end
        end
        package.loaded['libs.utils'] = nil
        package.loaded['configuration'] = nil
        mattata.init(self)
    end
    package.loaded['mattata'] = require('mattata')
    mattata.is_running = false
    local success = mattata.send_message(message.chat.id, 'Shutting down...')
    redis:set('mattata:shutdown', tostring(message.chat.id) .. ':' .. tostring(success.result.message_id))
    return success
end

return reboot