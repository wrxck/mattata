--[[
    mattata v2.0 - Structured Logging Module
]]

local logger = {}

local config = require('src.core.config')

local LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

local COLORS = {
    DEBUG = '\27[36m',
    INFO = '\27[32m',
    WARN = '\27[33m',
    ERROR = '\27[31m',
    RESET = '\27[0m'
}

local current_level = LEVELS.INFO

function logger.set_level(level)
    level = level:upper()
    if LEVELS[level] then
        current_level = LEVELS[level]
    end
end

local function log(level, fmt, ...)
    if LEVELS[level] < current_level then
        return
    end
    local msg
    if select('#', ...) > 0 then
        msg = string.format(fmt, ...)
    else
        msg = tostring(fmt)
    end
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    io.write(string.format(
        '%s[%s]%s [%s] %s\n',
        COLORS[level], level, COLORS.RESET,
        timestamp, msg
    ))
    io.flush()
end

function logger.debug(fmt, ...)
    log('DEBUG', fmt, ...)
end

function logger.info(fmt, ...)
    log('INFO', fmt, ...)
end

function logger.warn(fmt, ...)
    log('WARN', fmt, ...)
end

function logger.error(fmt, ...)
    log('ERROR', fmt, ...)
end

-- Initialize log level from config
function logger.init()
    if config.debug() then
        logger.set_level('DEBUG')
    end
end

return logger
