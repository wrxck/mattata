package = 'mattata'
version = '2.2-0'
source = {
    url = 'git://github.com/wrxck/mattata.git',
    tag = 'v2.2.0'
}
description = {
    summary = 'A feature-rich Telegram bot written in Lua',
    detailed = 'mattata is a powerful, plugin-based Telegram group management and utility bot.',
    homepage = 'https://github.com/wrxck/mattata',
    maintainer = 'Matthew Hesketh <matthew@matthewhesketh.com>',
    license = 'MIT'
}
dependencies = {
    'lua >= 5.3',
    'telegram-bot-lua >= 3.0',
    'pgmoon >= 1.16'
}
build = {
    type = 'builtin',
    modules = {
        ['mattata.core.config'] = 'src/core/config.lua',
        ['mattata.core.loader'] = 'src/core/loader.lua',
        ['mattata.core.router'] = 'src/core/router.lua',
        ['mattata.core.middleware'] = 'src/core/middleware.lua',
        ['mattata.core.database'] = 'src/core/database.lua',
        ['mattata.core.redis'] = 'src/core/redis.lua',
        ['mattata.core.http'] = 'src/core/http.lua',
        ['mattata.core.i18n'] = 'src/core/i18n.lua',
        ['mattata.core.logger'] = 'src/core/logger.lua',
        ['mattata.core.permissions'] = 'src/core/permissions.lua',
        ['mattata.core.session'] = 'src/core/session.lua'
    }
}
