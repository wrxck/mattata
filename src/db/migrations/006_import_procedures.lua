--[[
    Migration 006 - Import Procedures
    Additional stored procedures needed for the import plugin.
    These return columns not covered by the base stored procedures in 005.
]]

local migration = {}

function migration.up()
    return [[

-- Get all settings for a chat (import needs key + value pairs)
CREATE OR REPLACE FUNCTION sp_get_all_chat_settings(
    p_chat_id BIGINT
) RETURNS TABLE(key TEXT, value TEXT) AS $$
    SELECT cs.key, cs.value FROM chat_settings cs
    WHERE cs.chat_id = p_chat_id;
$$ LANGUAGE sql;

-- Get filters with response column (import needs pattern, action, and response)
CREATE OR REPLACE FUNCTION sp_get_filters_full(
    p_chat_id BIGINT
) RETURNS TABLE(pattern TEXT, action VARCHAR(20), response TEXT) AS $$
    SELECT f.pattern, f.action, f.response FROM filters f
    WHERE f.chat_id = p_chat_id;
$$ LANGUAGE sql;

-- Get welcome message with parse_mode (import needs both columns)
CREATE OR REPLACE FUNCTION sp_get_welcome_message_full(
    p_chat_id BIGINT
) RETURNS TABLE(message TEXT, parse_mode TEXT) AS $$
    SELECT wm.message, wm.parse_mode FROM welcome_messages wm
    WHERE wm.chat_id = p_chat_id;
$$ LANGUAGE sql;

    ]]
end

return migration
