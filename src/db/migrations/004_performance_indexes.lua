--[[
    Migration 004 - Performance Indexes
    Adds indexes for frequently queried columns to improve read performance.
    Uses IF NOT EXISTS to be idempotent (some may already exist from earlier migrations).
]]

local migration = {}

function migration.up()
    return [[
        CREATE INDEX IF NOT EXISTS idx_federation_bans_user ON federation_bans(user_id);
        CREATE INDEX IF NOT EXISTS idx_federation_chats_chat ON federation_chats(chat_id);
        CREATE INDEX IF NOT EXISTS idx_chat_settings_chat ON chat_settings(chat_id, key);
        CREATE INDEX IF NOT EXISTS idx_warnings_chat_user ON warnings(chat_id, user_id);
        CREATE INDEX IF NOT EXISTS idx_filters_chat ON filters(chat_id);
        CREATE INDEX IF NOT EXISTS idx_triggers_chat ON triggers(chat_id);
        CREATE INDEX IF NOT EXISTS idx_msg_stats_chat_date ON message_stats(chat_id, date);
        CREATE INDEX IF NOT EXISTS idx_cmd_stats_date ON command_stats(date);
        CREATE INDEX IF NOT EXISTS idx_disabled_plugins_chat ON disabled_plugins(chat_id)
    ]]
end

return migration
