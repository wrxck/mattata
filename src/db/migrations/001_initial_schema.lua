--[[
    Migration 001 - Core Tables
    Creates the fundamental tables for users, chats, settings, and admin features.
]]

local migration = {}

function migration.up()
    return [[
        CREATE TABLE IF NOT EXISTS users (
            user_id BIGINT PRIMARY KEY,
            username VARCHAR(255),
            first_name VARCHAR(255),
            last_name VARCHAR(255),
            language_code VARCHAR(10),
            is_bot BOOLEAN DEFAULT FALSE,
            nickname VARCHAR(128),
            last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);

        CREATE TABLE IF NOT EXISTS chats (
            chat_id BIGINT PRIMARY KEY,
            title VARCHAR(255),
            chat_type VARCHAR(20) NOT NULL DEFAULT 'supergroup',
            username VARCHAR(255),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_chats_username ON chats (username);

        CREATE TABLE IF NOT EXISTS chat_settings (
            chat_id BIGINT NOT NULL REFERENCES chats(chat_id) ON DELETE CASCADE,
            key VARCHAR(255) NOT NULL,
            value TEXT,
            PRIMARY KEY (chat_id, key)
        );

        CREATE TABLE IF NOT EXISTS chat_members (
            chat_id BIGINT NOT NULL,
            user_id BIGINT NOT NULL,
            role VARCHAR(20) DEFAULT 'member',
            last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            PRIMARY KEY (chat_id, user_id)
        );

        CREATE INDEX IF NOT EXISTS idx_chat_members_user ON chat_members (user_id);

        CREATE TABLE IF NOT EXISTS bans (
            id SERIAL PRIMARY KEY,
            chat_id BIGINT NOT NULL,
            user_id BIGINT NOT NULL,
            banned_by BIGINT,
            reason TEXT,
            expires_at TIMESTAMP WITH TIME ZONE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_bans_chat_user ON bans (chat_id, user_id);

        CREATE TABLE IF NOT EXISTS warnings (
            id SERIAL PRIMARY KEY,
            chat_id BIGINT NOT NULL,
            user_id BIGINT NOT NULL,
            warned_by BIGINT,
            reason TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_warnings_chat_user ON warnings (chat_id, user_id);

        CREATE TABLE IF NOT EXISTS custom_commands (
            id SERIAL PRIMARY KEY,
            chat_id BIGINT NOT NULL,
            command VARCHAR(64) NOT NULL,
            response TEXT NOT NULL,
            created_by BIGINT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE (chat_id, command)
        );

        CREATE TABLE IF NOT EXISTS filters (
            id SERIAL PRIMARY KEY,
            chat_id BIGINT NOT NULL,
            pattern TEXT NOT NULL,
            action VARCHAR(20) DEFAULT 'delete',
            response TEXT,
            created_by BIGINT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_filters_chat ON filters (chat_id);

        CREATE TABLE IF NOT EXISTS rules (
            chat_id BIGINT PRIMARY KEY,
            rules_text TEXT NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS welcome_messages (
            chat_id BIGINT PRIMARY KEY,
            message TEXT NOT NULL,
            parse_mode VARCHAR(10) DEFAULT 'html',
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS saved_notes (
            id SERIAL PRIMARY KEY,
            chat_id BIGINT NOT NULL,
            note_name VARCHAR(64) NOT NULL,
            content TEXT NOT NULL,
            content_type VARCHAR(20) DEFAULT 'text',
            file_id TEXT,
            created_by BIGINT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE (chat_id, note_name)
        );

        CREATE TABLE IF NOT EXISTS user_locations (
            user_id BIGINT PRIMARY KEY,
            latitude DOUBLE PRECISION NOT NULL,
            longitude DOUBLE PRECISION NOT NULL,
            address TEXT,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE TABLE IF NOT EXISTS disabled_plugins (
            chat_id BIGINT NOT NULL,
            plugin_name VARCHAR(64) NOT NULL,
            PRIMARY KEY (chat_id, plugin_name)
        );

        CREATE TABLE IF NOT EXISTS admin_actions (
            id SERIAL PRIMARY KEY,
            chat_id BIGINT NOT NULL,
            admin_id BIGINT NOT NULL,
            target_id BIGINT,
            action VARCHAR(32) NOT NULL,
            reason TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_admin_actions_chat ON admin_actions (chat_id, created_at);

        CREATE TABLE IF NOT EXISTS group_blocklist (
            chat_id BIGINT NOT NULL,
            user_id BIGINT NOT NULL,
            reason TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            PRIMARY KEY (chat_id, user_id)
        );

        CREATE TABLE IF NOT EXISTS allowed_links (
            chat_id BIGINT NOT NULL,
            link VARCHAR(255) NOT NULL,
            PRIMARY KEY (chat_id, link)
        );

        CREATE TABLE IF NOT EXISTS triggers (
            id SERIAL PRIMARY KEY,
            chat_id BIGINT NOT NULL,
            pattern TEXT NOT NULL,
            response TEXT NOT NULL,
            is_media BOOLEAN DEFAULT FALSE,
            file_id TEXT,
            created_by BIGINT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_triggers_chat ON triggers (chat_id);

        CREATE TABLE IF NOT EXISTS aliases (
            chat_id BIGINT NOT NULL,
            alias VARCHAR(64) NOT NULL,
            command VARCHAR(64) NOT NULL,
            PRIMARY KEY (chat_id, alias)
        )
    ]]
end

return migration
