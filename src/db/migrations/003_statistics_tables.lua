--[[
    Migration 003 - Statistics Tables
    Per-user/chat/day message stats and command usage tracking.
]]

local migration = {}

function migration.up()
    return [[
        CREATE TABLE IF NOT EXISTS message_stats (
            chat_id BIGINT NOT NULL,
            user_id BIGINT NOT NULL,
            date DATE NOT NULL DEFAULT CURRENT_DATE,
            message_count INTEGER DEFAULT 1,
            PRIMARY KEY (chat_id, user_id, date)
        );

        CREATE INDEX IF NOT EXISTS idx_message_stats_date ON message_stats (date);

        CREATE TABLE IF NOT EXISTS command_stats (
            chat_id BIGINT NOT NULL,
            command VARCHAR(64) NOT NULL,
            date DATE NOT NULL DEFAULT CURRENT_DATE,
            use_count INTEGER DEFAULT 1,
            PRIMARY KEY (chat_id, command, date)
        );

        CREATE INDEX IF NOT EXISTS idx_command_stats_date ON command_stats (date)
    ]]
end

return migration
