--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local control = {}

local mattata = require('mattata')

function control:init()
    control.commands = mattata.commands(
        self.info.username
    ):command('reload')
     :command('reboot')
     :command('icanhazreboot').table
end

function control:on_message(message, configuration)
    if not mattata.is_global_admin(message.from.id) then
        return mattata.send_reply(
            message,
            'Pfft, you wish!'
        )
    end
    for p, _ in pairs(package.loaded) do
        if p:match('^plugins%.') then
            package.loaded[p] = nil
        end
    end
    package.loaded['mattata'] = nil
    package.loaded['configuration'] = nil
    for k, v in pairs(configuration) do
        configuration[k] = v
    end
    mattata.init(
        self,
        configuration
    )
    return mattata.send_message(
        message.chat.id,
        self.info.name .. ' is reloading...'
    )
end

return control