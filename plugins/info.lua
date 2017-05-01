--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local info = {}
local mattata = require('mattata')
local redis = require('mattata-redis')

function info:init()
    info.commands = mattata.commands(self.info.username):command('info').table
    info.help = '/info - View system information & statistics about the bot.'
end

function info:on_message(message, configuration, language)
    local info = redis:info()
    if not info
    then
        return mattata.send_reply(
            message,
            language['errors']['generic']
        )
    end
    return mattata.send_message(
        message.chat.id,
        string.format(
            language['info']['1'],
            mattata.symbols.bullet,
            info.server.config_file,
            mattata.symbols.bullet,
            info.server.redis_mode,
            mattata.symbols.bullet,
            info.server.tcp_port,
            mattata.symbols.bullet,
            info.server.redis_version,
            mattata.symbols.bullet,
            info.server.uptime_in_days,
            mattata.symbols.bullet,
            info.server.process_id,
            mattata.symbols.bullet,
            mattata.comma_value(info.stats.expired_keys),
            mattata.symbols.bullet,
            mattata.comma_value(
                mattata.get_user_count()
            ),
            mattata.symbols.bullet,
            mattata.comma_value(
                mattata.get_group_count()
            ),
            mattata.symbols.bullet,
            io.popen('uname -a'):read('*all')
        ),
        'markdown'
    )
end

return info