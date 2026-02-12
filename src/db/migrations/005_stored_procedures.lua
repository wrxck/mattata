--[[
    Migration 005 - Stored Procedures
    Creates PostgreSQL functions for all database operations.
    All user-facing queries go through typed stored procedures to prevent SQL injection.
    Parameters are strongly typed (BIGINT, TEXT, UUID, etc.) providing server-side validation.
]]

local migration = {}

function migration.up()
    return [[

-- ============================================================
-- USER / CHAT MANAGEMENT
-- ============================================================

CREATE OR REPLACE FUNCTION sp_upsert_user(
    p_user_id BIGINT,
    p_username TEXT,
    p_first_name TEXT,
    p_last_name TEXT,
    p_language_code TEXT,
    p_is_bot BOOLEAN,
    p_last_seen TIMESTAMP WITH TIME ZONE
) RETURNS void AS $$
    INSERT INTO users (user_id, username, first_name, last_name, language_code, is_bot, last_seen)
    VALUES (p_user_id, p_username, p_first_name, p_last_name, p_language_code, p_is_bot, p_last_seen)
    ON CONFLICT (user_id) DO UPDATE SET
        username = EXCLUDED.username,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        language_code = EXCLUDED.language_code,
        last_seen = EXCLUDED.last_seen;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_upsert_chat(
    p_chat_id BIGINT,
    p_title TEXT,
    p_chat_type TEXT,
    p_username TEXT
) RETURNS void AS $$
    INSERT INTO chats (chat_id, title, chat_type, username)
    VALUES (p_chat_id, p_title, p_chat_type, p_username)
    ON CONFLICT (chat_id) DO UPDATE SET
        title = EXCLUDED.title,
        chat_type = EXCLUDED.chat_type,
        username = EXCLUDED.username;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_upsert_chat_member(
    p_chat_id BIGINT,
    p_user_id BIGINT,
    p_last_seen TIMESTAMP WITH TIME ZONE
) RETURNS void AS $$
    INSERT INTO chat_members (chat_id, user_id, last_seen)
    VALUES (p_chat_id, p_user_id, p_last_seen)
    ON CONFLICT (chat_id, user_id) DO UPDATE SET
        last_seen = EXCLUDED.last_seen;
$$ LANGUAGE sql;

-- ============================================================
-- PERMISSIONS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_check_group_moderator(
    p_chat_id BIGINT,
    p_user_id BIGINT
) RETURNS TABLE(exists_flag INTEGER) AS $$
    SELECT 1 FROM chat_members
    WHERE chat_id = p_chat_id AND user_id = p_user_id AND role = 'moderator';
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_check_trusted_user(
    p_chat_id BIGINT,
    p_user_id BIGINT
) RETURNS TABLE(exists_flag INTEGER) AS $$
    SELECT 1 FROM chat_members
    WHERE chat_id = p_chat_id AND user_id = p_user_id AND role = 'trusted';
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_moderators(
    p_chat_id BIGINT
) RETURNS TABLE(user_id BIGINT) AS $$
    SELECT cm.user_id FROM chat_members cm
    WHERE cm.chat_id = p_chat_id AND cm.role = 'moderator';
$$ LANGUAGE sql;

-- ============================================================
-- CHAT SETTINGS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_chat_setting(
    p_chat_id BIGINT,
    p_key TEXT
) RETURNS TABLE(value TEXT) AS $$
    SELECT cs.value FROM chat_settings cs
    WHERE cs.chat_id = p_chat_id AND cs.key = p_key;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_upsert_chat_setting(
    p_chat_id BIGINT,
    p_key TEXT,
    p_value TEXT
) RETURNS void AS $$
    INSERT INTO chat_settings (chat_id, key, value)
    VALUES (p_chat_id, p_key, p_value)
    ON CONFLICT (chat_id, key) DO UPDATE SET
        value = EXCLUDED.value;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_disable_chat_setting(
    p_chat_id BIGINT,
    p_key TEXT
) RETURNS void AS $$
    UPDATE chat_settings SET value = 'false'
    WHERE chat_id = p_chat_id AND key = p_key;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_chat_setting(
    p_chat_id BIGINT,
    p_key TEXT
) RETURNS void AS $$
    DELETE FROM chat_settings
    WHERE chat_id = p_chat_id AND key = p_key;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_chat_settings_like(
    p_chat_id BIGINT,
    p_key_pattern TEXT
) RETURNS TABLE(key TEXT, value TEXT) AS $$
    SELECT cs.key, cs.value FROM chat_settings cs
    WHERE cs.chat_id = p_chat_id AND cs.key LIKE p_key_pattern;
$$ LANGUAGE sql;

-- ============================================================
-- ROLE MANAGEMENT
-- ============================================================

CREATE OR REPLACE FUNCTION sp_set_member_role(
    p_chat_id BIGINT,
    p_user_id BIGINT,
    p_role TEXT
) RETURNS void AS $$
    INSERT INTO chat_members (chat_id, user_id, role)
    VALUES (p_chat_id, p_user_id, p_role)
    ON CONFLICT (chat_id, user_id) DO UPDATE SET
        role = EXCLUDED.role;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_reset_member_role(
    p_chat_id BIGINT,
    p_user_id BIGINT
) RETURNS void AS $$
    UPDATE chat_members SET role = 'member'
    WHERE chat_id = p_chat_id AND user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_remove_allowlisted(
    p_chat_id BIGINT,
    p_user_id BIGINT
) RETURNS void AS $$
    UPDATE chat_members SET role = 'member'
    WHERE chat_id = p_chat_id AND user_id = p_user_id AND role = 'allowlisted';
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_allowlisted_users(
    p_chat_id BIGINT
) RETURNS TABLE(user_id BIGINT) AS $$
    SELECT cm.user_id FROM chat_members cm
    WHERE cm.chat_id = p_chat_id AND cm.role = 'allowlisted';
$$ LANGUAGE sql;

-- ============================================================
-- BANS / WARNINGS / ADMIN ACTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_insert_ban(
    p_chat_id BIGINT,
    p_user_id BIGINT,
    p_banned_by BIGINT,
    p_reason TEXT
) RETURNS void AS $$
    INSERT INTO bans (chat_id, user_id, banned_by, reason)
    VALUES (p_chat_id, p_user_id, p_banned_by, p_reason);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_insert_tempban(
    p_chat_id BIGINT,
    p_user_id BIGINT,
    p_banned_by BIGINT,
    p_expires_at TIMESTAMP WITH TIME ZONE
) RETURNS void AS $$
    INSERT INTO bans (chat_id, user_id, banned_by, expires_at)
    VALUES (p_chat_id, p_user_id, p_banned_by, p_expires_at);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_insert_warning(
    p_chat_id BIGINT,
    p_user_id BIGINT,
    p_warned_by BIGINT,
    p_reason TEXT
) RETURNS void AS $$
    INSERT INTO warnings (chat_id, user_id, warned_by, reason)
    VALUES (p_chat_id, p_user_id, p_warned_by, p_reason);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_log_admin_action(
    p_chat_id BIGINT,
    p_admin_id BIGINT,
    p_target_id BIGINT,
    p_action TEXT,
    p_reason TEXT
) RETURNS void AS $$
    INSERT INTO admin_actions (chat_id, admin_id, target_id, action, reason)
    VALUES (p_chat_id, p_admin_id, p_target_id, p_action, p_reason);
$$ LANGUAGE sql;

-- ============================================================
-- BLOCKLIST
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_blocklist(
    p_chat_id BIGINT
) RETURNS TABLE(user_id BIGINT, reason TEXT, created_at TIMESTAMP WITH TIME ZONE) AS $$
    SELECT gb.user_id, gb.reason, gb.created_at FROM group_blocklist gb
    WHERE gb.chat_id = p_chat_id ORDER BY gb.created_at DESC;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_upsert_blocklist_entry(
    p_chat_id BIGINT,
    p_user_id BIGINT,
    p_reason TEXT
) RETURNS void AS $$
    INSERT INTO group_blocklist (chat_id, user_id, reason)
    VALUES (p_chat_id, p_user_id, p_reason)
    ON CONFLICT (chat_id, user_id) DO UPDATE SET
        reason = EXCLUDED.reason;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_blocklist_entry(
    p_chat_id BIGINT,
    p_user_id BIGINT
) RETURNS void AS $$
    DELETE FROM group_blocklist
    WHERE chat_id = p_chat_id AND user_id = p_user_id;
$$ LANGUAGE sql;

-- ============================================================
-- FILTERS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_filter(
    p_chat_id BIGINT,
    p_pattern TEXT
) RETURNS TABLE(id INTEGER) AS $$
    SELECT f.id FROM filters f
    WHERE f.chat_id = p_chat_id AND f.pattern = p_pattern;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_filters(
    p_chat_id BIGINT
) RETURNS TABLE(pattern TEXT, action VARCHAR(20)) AS $$
    SELECT f.pattern, f.action FROM filters f
    WHERE f.chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_filters_ordered(
    p_chat_id BIGINT
) RETURNS TABLE(id INTEGER, pattern TEXT, action VARCHAR(20), created_at TIMESTAMP WITH TIME ZONE) AS $$
    SELECT f.id, f.pattern, f.action, f.created_at FROM filters f
    WHERE f.chat_id = p_chat_id ORDER BY f.created_at;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_update_filter_action(
    p_action TEXT,
    p_chat_id BIGINT,
    p_pattern TEXT
) RETURNS void AS $$
    UPDATE filters SET action = p_action
    WHERE chat_id = p_chat_id AND pattern = p_pattern;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_insert_filter(
    p_chat_id BIGINT,
    p_pattern TEXT,
    p_action TEXT,
    p_created_by BIGINT
) RETURNS void AS $$
    INSERT INTO filters (chat_id, pattern, action, created_by)
    VALUES (p_chat_id, p_pattern, p_action, p_created_by);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_filter_by_pattern(
    p_chat_id BIGINT,
    p_pattern TEXT
) RETURNS BIGINT AS $$
    WITH deleted AS (
        DELETE FROM filters
        WHERE chat_id = p_chat_id AND pattern = p_pattern
        RETURNING id
    )
    SELECT COUNT(*) FROM deleted;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_filter_by_id(
    p_id INTEGER
) RETURNS void AS $$
    DELETE FROM filters WHERE id = p_id;
$$ LANGUAGE sql;

-- ============================================================
-- TRIGGERS (auto-response)
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_triggers(
    p_chat_id BIGINT
) RETURNS TABLE(pattern TEXT, response TEXT, is_media BOOLEAN, file_id TEXT) AS $$
    SELECT t.pattern, t.response, t.is_media, t.file_id FROM triggers t
    WHERE t.chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_triggers_full(
    p_chat_id BIGINT
) RETURNS TABLE(id INTEGER, pattern TEXT, response TEXT, created_by BIGINT, created_at TIMESTAMP WITH TIME ZONE) AS $$
    SELECT t.id, t.pattern, t.response, t.created_by, t.created_at FROM triggers t
    WHERE t.chat_id = p_chat_id ORDER BY t.created_at;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_triggers_ordered(
    p_chat_id BIGINT
) RETURNS TABLE(id INTEGER, pattern TEXT) AS $$
    SELECT t.id, t.pattern FROM triggers t
    WHERE t.chat_id = p_chat_id ORDER BY t.created_at;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_check_trigger_exists(
    p_chat_id BIGINT,
    p_pattern TEXT
) RETURNS TABLE(id INTEGER) AS $$
    SELECT t.id FROM triggers t
    WHERE t.chat_id = p_chat_id AND t.pattern = p_pattern;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_update_trigger_response(
    p_response TEXT,
    p_chat_id BIGINT,
    p_pattern TEXT
) RETURNS void AS $$
    UPDATE triggers SET response = p_response
    WHERE chat_id = p_chat_id AND pattern = p_pattern;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_insert_trigger(
    p_chat_id BIGINT,
    p_pattern TEXT,
    p_response TEXT,
    p_created_by BIGINT
) RETURNS void AS $$
    INSERT INTO triggers (chat_id, pattern, response, created_by)
    VALUES (p_chat_id, p_pattern, p_response, p_created_by);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_trigger_by_id(
    p_id INTEGER
) RETURNS void AS $$
    DELETE FROM triggers WHERE id = p_id;
$$ LANGUAGE sql;

-- ============================================================
-- WELCOME MESSAGES
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_welcome_message(
    p_chat_id BIGINT
) RETURNS TABLE(message TEXT) AS $$
    SELECT wm.message FROM welcome_messages wm
    WHERE wm.chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_upsert_welcome_message(
    p_chat_id BIGINT,
    p_message TEXT
) RETURNS void AS $$
    INSERT INTO welcome_messages (chat_id, message)
    VALUES (p_chat_id, p_message)
    ON CONFLICT (chat_id) DO UPDATE SET
        message = EXCLUDED.message;
$$ LANGUAGE sql;

-- ============================================================
-- RULES
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_rules(
    p_chat_id BIGINT
) RETURNS TABLE(rules_text TEXT) AS $$
    SELECT r.rules_text FROM rules r
    WHERE r.chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_upsert_rules(
    p_chat_id BIGINT,
    p_rules_text TEXT
) RETURNS void AS $$
    INSERT INTO rules (chat_id, rules_text)
    VALUES (p_chat_id, p_rules_text)
    ON CONFLICT (chat_id) DO UPDATE SET
        rules_text = EXCLUDED.rules_text,
        updated_at = NOW();
$$ LANGUAGE sql;

-- ============================================================
-- ALLOWED LINKS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_allowed_links(
    p_chat_id BIGINT
) RETURNS TABLE(link VARCHAR(255)) AS $$
    SELECT al.link FROM allowed_links al
    WHERE al.chat_id = p_chat_id ORDER BY al.link;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_check_allowed_link(
    p_chat_id BIGINT,
    p_link TEXT
) RETURNS TABLE(exists_flag INTEGER) AS $$
    SELECT 1 FROM allowed_links
    WHERE chat_id = p_chat_id AND link = p_link;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_insert_allowed_link(
    p_chat_id BIGINT,
    p_link TEXT
) RETURNS void AS $$
    INSERT INTO allowed_links (chat_id, link)
    VALUES (p_chat_id, p_link);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_allowed_link(
    p_chat_id BIGINT,
    p_link TEXT
) RETURNS void AS $$
    DELETE FROM allowed_links
    WHERE chat_id = p_chat_id AND link = p_link;
$$ LANGUAGE sql;

-- ============================================================
-- NICKNAME
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_nickname(
    p_user_id BIGINT
) RETURNS TABLE(nickname VARCHAR(128)) AS $$
    SELECT u.nickname FROM users u
    WHERE u.user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_set_nickname(
    p_user_id BIGINT,
    p_nickname TEXT
) RETURNS void AS $$
    UPDATE users SET nickname = p_nickname
    WHERE user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_clear_nickname(
    p_user_id BIGINT
) RETURNS void AS $$
    UPDATE users SET nickname = NULL
    WHERE user_id = p_user_id;
$$ LANGUAGE sql;

-- ============================================================
-- USER LOCATIONS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_user_location(
    p_user_id BIGINT
) RETURNS TABLE(latitude DOUBLE PRECISION, longitude DOUBLE PRECISION, address TEXT) AS $$
    SELECT ul.latitude, ul.longitude, ul.address FROM user_locations ul
    WHERE ul.user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_upsert_user_location(
    p_user_id BIGINT,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_address TEXT
) RETURNS void AS $$
    INSERT INTO user_locations (user_id, latitude, longitude, address, updated_at)
    VALUES (p_user_id, p_latitude, p_longitude, p_address, NOW())
    ON CONFLICT (user_id) DO UPDATE SET
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        address = EXCLUDED.address,
        updated_at = NOW();
$$ LANGUAGE sql;

-- ============================================================
-- SAVED NOTES
-- ============================================================

CREATE OR REPLACE FUNCTION sp_list_notes(
    p_chat_id BIGINT
) RETURNS TABLE(note_name VARCHAR(64)) AS $$
    SELECT sn.note_name FROM saved_notes sn
    WHERE sn.chat_id = p_chat_id ORDER BY sn.note_name;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_note(
    p_chat_id BIGINT,
    p_note_name TEXT
) RETURNS TABLE(content TEXT, content_type VARCHAR(20), file_id TEXT) AS $$
    SELECT sn.content, sn.content_type, sn.file_id FROM saved_notes sn
    WHERE sn.chat_id = p_chat_id AND sn.note_name = p_note_name;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_upsert_note(
    p_chat_id BIGINT,
    p_note_name TEXT,
    p_content TEXT,
    p_content_type TEXT,
    p_file_id TEXT,
    p_created_by BIGINT
) RETURNS void AS $$
    INSERT INTO saved_notes (chat_id, note_name, content, content_type, file_id, created_by)
    VALUES (p_chat_id, p_note_name, p_content, p_content_type, p_file_id, p_created_by)
    ON CONFLICT (chat_id, note_name) DO UPDATE SET
        content = EXCLUDED.content,
        content_type = EXCLUDED.content_type,
        file_id = EXCLUDED.file_id,
        created_by = EXCLUDED.created_by;
$$ LANGUAGE sql;

-- ============================================================
-- STATISTICS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_flush_message_stats(
    p_chat_id BIGINT,
    p_user_id BIGINT,
    p_date DATE,
    p_count INTEGER
) RETURNS void AS $$
    INSERT INTO message_stats (chat_id, user_id, date, message_count)
    VALUES (p_chat_id, p_user_id, p_date, p_count)
    ON CONFLICT (chat_id, user_id, date) DO UPDATE SET
        message_count = message_stats.message_count + p_count;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_flush_command_stats(
    p_chat_id BIGINT,
    p_command TEXT,
    p_date DATE,
    p_count INTEGER
) RETURNS void AS $$
    INSERT INTO command_stats (chat_id, command, date, use_count)
    VALUES (p_chat_id, p_command, p_date, p_count)
    ON CONFLICT (chat_id, command, date) DO UPDATE SET
        use_count = command_stats.use_count + p_count;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_top_users(
    p_chat_id BIGINT
) RETURNS TABLE(user_id BIGINT, total BIGINT, first_name VARCHAR(255), last_name VARCHAR(255), username VARCHAR(255)) AS $$
    SELECT ms.user_id, SUM(ms.message_count)::BIGINT AS total,
           u.first_name, u.last_name, u.username
    FROM message_stats ms
    LEFT JOIN users u ON ms.user_id = u.user_id
    WHERE ms.chat_id = p_chat_id
    GROUP BY ms.user_id, u.first_name, u.last_name, u.username
    ORDER BY total DESC
    LIMIT 10;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_total_messages(
    p_chat_id BIGINT
) RETURNS TABLE(total BIGINT) AS $$
    SELECT SUM(message_count)::BIGINT AS total FROM message_stats
    WHERE chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_unique_users(
    p_chat_id BIGINT
) RETURNS TABLE(total BIGINT) AS $$
    SELECT COUNT(DISTINCT user_id)::BIGINT AS total FROM message_stats
    WHERE chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_reset_message_stats(
    p_chat_id BIGINT
) RETURNS void AS $$
    DELETE FROM message_stats WHERE chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_top_commands(
    p_chat_id BIGINT
) RETURNS TABLE(command VARCHAR(64), total BIGINT) AS $$
    SELECT cs.command, SUM(cs.use_count)::BIGINT AS total
    FROM command_stats cs
    WHERE cs.chat_id = p_chat_id
    GROUP BY cs.command
    ORDER BY total DESC
    LIMIT 10;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_reset_command_stats(
    p_chat_id BIGINT
) RETURNS void AS $$
    DELETE FROM command_stats WHERE chat_id = p_chat_id;
$$ LANGUAGE sql;

-- ============================================================
-- GROUPS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_list_groups()
RETURNS TABLE(chat_id BIGINT, title VARCHAR(255), username VARCHAR(255)) AS $$
    SELECT c.chat_id, c.title, c.username FROM chats c
    WHERE c.chat_type IN ('group', 'supergroup')
    ORDER BY c.title LIMIT 50;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_search_groups(
    p_search TEXT
) RETURNS TABLE(chat_id BIGINT, title VARCHAR(255), username VARCHAR(255)) AS $$
    SELECT c.chat_id, c.title, c.username FROM chats c
    WHERE c.chat_type IN ('group', 'supergroup')
    AND LOWER(c.title) LIKE p_search
    ORDER BY c.title LIMIT 50;
$$ LANGUAGE sql;

-- ============================================================
-- INFO / COUNTS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_count_users()
RETURNS TABLE(count BIGINT) AS $$
    SELECT COUNT(*)::BIGINT FROM users;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_count_chats()
RETURNS TABLE(count BIGINT) AS $$
    SELECT COUNT(*)::BIGINT FROM chats;
$$ LANGUAGE sql;

-- ============================================================
-- FEDERATION - CORE
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_chat_federation_id(
    p_chat_id BIGINT
) RETURNS TABLE(federation_id UUID) AS $$
    SELECT fc.federation_id FROM federation_chats fc
    WHERE fc.chat_id = p_chat_id LIMIT 1;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_chat_federation(
    p_chat_id BIGINT
) RETURNS TABLE(id UUID, name VARCHAR(255), owner_id BIGINT) AS $$
    SELECT f.id, f.name, f.owner_id
    FROM federations f
    JOIN federation_chats fc ON f.id = fc.federation_id
    WHERE fc.chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_federation(
    p_federation_id UUID
) RETURNS TABLE(id UUID, name VARCHAR(255), owner_id BIGINT, created_at TIMESTAMP WITH TIME ZONE) AS $$
    SELECT f.id, f.name, f.owner_id, f.created_at FROM federations f
    WHERE f.id = p_federation_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_federation_basic(
    p_federation_id UUID
) RETURNS TABLE(id UUID, name VARCHAR(255)) AS $$
    SELECT f.id, f.name FROM federations f
    WHERE f.id = p_federation_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_federation_owner(
    p_federation_id UUID
) RETURNS TABLE(name VARCHAR(255), owner_id BIGINT) AS $$
    SELECT f.name, f.owner_id FROM federations f
    WHERE f.id = p_federation_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_count_user_federations(
    p_user_id BIGINT
) RETURNS TABLE(count BIGINT) AS $$
    SELECT COUNT(*)::BIGINT FROM federations
    WHERE owner_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_create_federation(
    p_name TEXT,
    p_owner_id BIGINT
) RETURNS TABLE(id UUID) AS $$
    INSERT INTO federations (name, owner_id)
    VALUES (p_name, p_owner_id)
    RETURNING id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_federation(
    p_federation_id UUID
) RETURNS void AS $$
    DELETE FROM federations WHERE id = p_federation_id;
$$ LANGUAGE sql;

-- ============================================================
-- FEDERATION - CHATS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_chat_federation_joined(
    p_chat_id BIGINT
) RETURNS TABLE(id UUID, name VARCHAR(255)) AS $$
    SELECT f.id, f.name
    FROM federations f
    JOIN federation_chats fc ON f.id = fc.federation_id
    WHERE fc.chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_join_federation(
    p_federation_id UUID,
    p_chat_id BIGINT,
    p_joined_by BIGINT
) RETURNS void AS $$
    INSERT INTO federation_chats (federation_id, chat_id, joined_by)
    VALUES (p_federation_id, p_chat_id, p_joined_by);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_leave_federation(
    p_federation_id UUID,
    p_chat_id BIGINT
) RETURNS void AS $$
    DELETE FROM federation_chats
    WHERE federation_id = p_federation_id AND chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_federation_chats(
    p_federation_id UUID
) RETURNS TABLE(chat_id BIGINT) AS $$
    SELECT fc.chat_id FROM federation_chats fc
    WHERE fc.federation_id = p_federation_id;
$$ LANGUAGE sql;

-- ============================================================
-- FEDERATION - BANS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_check_federation_ban(
    p_federation_id UUID,
    p_user_id BIGINT
) RETURNS TABLE(reason TEXT) AS $$
    SELECT fb.reason FROM federation_bans fb
    WHERE fb.federation_id = p_federation_id AND fb.user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_check_federation_ban_exists(
    p_federation_id UUID,
    p_user_id BIGINT
) RETURNS TABLE(exists_flag INTEGER) AS $$
    SELECT 1 FROM federation_bans
    WHERE federation_id = p_federation_id AND user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_insert_federation_ban(
    p_federation_id UUID,
    p_user_id BIGINT,
    p_reason TEXT,
    p_banned_by BIGINT
) RETURNS void AS $$
    INSERT INTO federation_bans (federation_id, user_id, reason, banned_by)
    VALUES (p_federation_id, p_user_id, p_reason, p_banned_by);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_update_federation_ban(
    p_reason TEXT,
    p_banned_by BIGINT,
    p_federation_id UUID,
    p_user_id BIGINT
) RETURNS void AS $$
    UPDATE federation_bans SET reason = p_reason, banned_by = p_banned_by, banned_at = NOW()
    WHERE federation_id = p_federation_id AND user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_federation_ban(
    p_federation_id UUID,
    p_user_id BIGINT
) RETURNS void AS $$
    DELETE FROM federation_bans
    WHERE federation_id = p_federation_id AND user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_fban_info_group(
    p_user_id BIGINT,
    p_chat_id BIGINT
) RETURNS TABLE(reason TEXT, banned_by BIGINT, banned_at TIMESTAMP WITH TIME ZONE, name VARCHAR(255), id UUID) AS $$
    SELECT fb.reason, fb.banned_by, fb.banned_at, f.name, f.id
    FROM federation_bans fb
    JOIN federations f ON fb.federation_id = f.id
    JOIN federation_chats fc ON f.id = fc.federation_id
    WHERE fb.user_id = p_user_id AND fc.chat_id = p_chat_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_fban_info_all(
    p_user_id BIGINT
) RETURNS TABLE(reason TEXT, banned_by BIGINT, banned_at TIMESTAMP WITH TIME ZONE, name VARCHAR(255), id UUID) AS $$
    SELECT fb.reason, fb.banned_by, fb.banned_at, f.name, f.id
    FROM federation_bans fb
    JOIN federations f ON fb.federation_id = f.id
    WHERE fb.user_id = p_user_id;
$$ LANGUAGE sql;

-- ============================================================
-- FEDERATION - ADMINS
-- ============================================================

CREATE OR REPLACE FUNCTION sp_check_federation_admin(
    p_federation_id UUID,
    p_user_id BIGINT
) RETURNS TABLE(exists_flag INTEGER) AS $$
    SELECT 1 FROM federation_admins
    WHERE federation_id = p_federation_id AND user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_insert_federation_admin(
    p_federation_id UUID,
    p_user_id BIGINT,
    p_promoted_by BIGINT
) RETURNS void AS $$
    INSERT INTO federation_admins (federation_id, user_id, promoted_by)
    VALUES (p_federation_id, p_user_id, p_promoted_by);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_federation_admin(
    p_federation_id UUID,
    p_user_id BIGINT
) RETURNS void AS $$
    DELETE FROM federation_admins
    WHERE federation_id = p_federation_id AND user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_federation_admins(
    p_federation_id UUID
) RETURNS TABLE(user_id BIGINT, promoted_at TIMESTAMP WITH TIME ZONE) AS $$
    SELECT fa.user_id, fa.promoted_at FROM federation_admins fa
    WHERE fa.federation_id = p_federation_id ORDER BY fa.promoted_at ASC;
$$ LANGUAGE sql;

-- ============================================================
-- FEDERATION - ALLOWLIST
-- ============================================================

CREATE OR REPLACE FUNCTION sp_check_federation_allowlist(
    p_federation_id UUID,
    p_user_id BIGINT
) RETURNS TABLE(exists_flag INTEGER) AS $$
    SELECT 1 FROM federation_allowlist
    WHERE federation_id = p_federation_id AND user_id = p_user_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_insert_federation_allowlist(
    p_federation_id UUID,
    p_user_id BIGINT
) RETURNS void AS $$
    INSERT INTO federation_allowlist (federation_id, user_id)
    VALUES (p_federation_id, p_user_id);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_delete_federation_allowlist(
    p_federation_id UUID,
    p_user_id BIGINT
) RETURNS void AS $$
    DELETE FROM federation_allowlist
    WHERE federation_id = p_federation_id AND user_id = p_user_id;
$$ LANGUAGE sql;

-- ============================================================
-- FEDERATION - COUNTS / LISTING
-- ============================================================

CREATE OR REPLACE FUNCTION sp_get_federation_counts(
    p_federation_id UUID
) RETURNS TABLE(admin_count BIGINT, chat_count BIGINT, ban_count BIGINT) AS $$
    SELECT
        (SELECT COUNT(*) FROM federation_admins WHERE federation_id = p_federation_id)::BIGINT,
        (SELECT COUNT(*) FROM federation_chats WHERE federation_id = p_federation_id)::BIGINT,
        (SELECT COUNT(*) FROM federation_bans WHERE federation_id = p_federation_id)::BIGINT;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_owned_federations(
    p_user_id BIGINT
) RETURNS TABLE(id UUID, name VARCHAR(255), chat_count BIGINT, ban_count BIGINT) AS $$
    SELECT f.id, f.name,
        (SELECT COUNT(*) FROM federation_chats WHERE federation_id = f.id)::BIGINT AS chat_count,
        (SELECT COUNT(*) FROM federation_bans WHERE federation_id = f.id)::BIGINT AS ban_count
    FROM federations f
    WHERE f.owner_id = p_user_id
    ORDER BY f.created_at ASC;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION sp_get_admin_federations(
    p_user_id BIGINT
) RETURNS TABLE(id UUID, name VARCHAR(255), owner_id BIGINT, chat_count BIGINT, ban_count BIGINT) AS $$
    SELECT f.id, f.name, f.owner_id,
        (SELECT COUNT(*) FROM federation_chats WHERE federation_id = f.id)::BIGINT AS chat_count,
        (SELECT COUNT(*) FROM federation_bans WHERE federation_id = f.id)::BIGINT AS ban_count
    FROM federations f
    JOIN federation_admins fa ON f.id = fa.federation_id
    WHERE fa.user_id = p_user_id AND f.owner_id != p_user_id
    ORDER BY fa.promoted_at ASC;
$$ LANGUAGE sql;

    ]]
end

return migration
