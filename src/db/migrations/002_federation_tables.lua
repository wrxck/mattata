--[[
    Migration 002 - Federation Tables
    Federation system for cross-group ban management.
    Column names match federation plugin code (id, owner_id, federation_id).
]]

local migration = {}

function migration.up()
    return [[
        CREATE TABLE IF NOT EXISTS federations (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(255) NOT NULL,
            owner_id BIGINT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        CREATE INDEX IF NOT EXISTS idx_federations_owner ON federations (owner_id);

        CREATE TABLE IF NOT EXISTS federation_admins (
            federation_id UUID NOT NULL REFERENCES federations(id) ON DELETE CASCADE,
            user_id BIGINT NOT NULL,
            promoted_by BIGINT,
            promoted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            PRIMARY KEY (federation_id, user_id)
        );

        CREATE TABLE IF NOT EXISTS federation_bans (
            federation_id UUID NOT NULL REFERENCES federations(id) ON DELETE CASCADE,
            user_id BIGINT NOT NULL,
            banned_by BIGINT,
            reason TEXT,
            banned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            PRIMARY KEY (federation_id, user_id)
        );

        CREATE INDEX IF NOT EXISTS idx_federation_bans_user ON federation_bans (user_id);

        CREATE TABLE IF NOT EXISTS federation_chats (
            federation_id UUID NOT NULL REFERENCES federations(id) ON DELETE CASCADE,
            chat_id BIGINT NOT NULL,
            joined_by BIGINT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            PRIMARY KEY (federation_id, chat_id)
        );

        CREATE INDEX IF NOT EXISTS idx_federation_chats_chat ON federation_chats (chat_id);

        CREATE TABLE IF NOT EXISTS federation_allowlist (
            federation_id UUID NOT NULL REFERENCES federations(id) ON DELETE CASCADE,
            user_id BIGINT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            PRIMARY KEY (federation_id, user_id)
        )
    ]]
end

return migration
