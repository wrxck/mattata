--[[
    Migration 007 - v1 Import Tracking
    Adds a helper stored procedure for bulk-importing chat settings
    during v1.5 -> v2.x data migration. Uses ON CONFLICT DO NOTHING
    to preserve any existing v2 settings.
]]

local migration = {}

function migration.up()
    return [[

CREATE OR REPLACE FUNCTION sp_upsert_chat_setting_if_missing(
    p_chat_id BIGINT, p_key TEXT, p_value TEXT
) RETURNS void AS $$
    INSERT INTO chat_settings (chat_id, key, value)
    VALUES (p_chat_id, p_key, p_value)
    ON CONFLICT (chat_id, key) DO NOTHING;
$$ LANGUAGE sql;

    ]]
end

return migration
