--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local redisstats = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function redisstats:init()
    redisstats.commands = mattata.commands(self.info.username):command('redisstats').table
    redisstats.help = '/redisstats - View statistics about the bot\'s database.'
end

function redisstats:on_message(message, configuration)
    local info = redis:info()
    if not info
    then
        return mattata.send_reply(
            message,
            'An error occured!'
        )
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            [[
```
OS: %s
Config File: %s
Mode: %s
TCP Port: %s
Version: %s
Uptime: %s days
Process ID: %s
GCC Version: %s
Expired Keys: %s

Users: %s
Groups: %s
```
            ]],
            info.server.os,
            info.server.config_file,
            info.server.redis_mode,
            info.server.tcp_port,
            info.server.redis_version,
            info.server.uptime_in_days,
            info.server.process_id,
            info.server.gcc_version,
            mattata.comma_value(info.stats.expired_keys),
            mattata.comma_value(
                mattata.get_user_count()
            ),
            mattata.comma_value(
                mattata.get_group_count()
            )
        ),
        'markdown'
    )
end

return redisstats