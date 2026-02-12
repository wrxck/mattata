--[[
    Tests for src/middleware/language.lua
    Tests user language selection, group language override.
]]

describe('middleware.language', function()
    local language_mw
    local test_helper = require('spec.helpers.test_helper')
    local env, ctx, message

    local mock_en_gb = { errors = { connection = 'Connection error.' } }
    local mock_de_de = { errors = { connection = 'Verbindungsfehler.' } }
    local mock_pt_br = { errors = { connection = 'Erro de conexao.' } }

    before_each(function()
        package.loaded['src.middleware.language'] = nil
        package.loaded['src.core.i18n'] = {
            get = function(code)
                if code == 'de_de' then return mock_de_de end
                if code == 'pt_br' then return mock_pt_br end
                return mock_en_gb
            end,
            exists = function(code)
                return code == 'en_gb' or code == 'de_de' or code == 'pt_br'
            end,
        }
        package.loaded['src.core.session'] = {
            get_setting = function(id, key)
                -- Return nil by default, tests override via redis
                return env.redis.get('cache:setting:' .. tostring(id) .. ':' .. key)
            end,
        }

        language_mw = require('src.middleware.language')
        env = test_helper.setup()
        message = test_helper.make_message()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    describe('name', function()
        it('should be "language"', function()
            assert.are.equal('language', language_mw.name)
        end)
    end)

    describe('default language', function()
        it('should default to en_gb', function()
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('en_gb', new_ctx.lang_code)
        end)

        it('should set lang table in context', function()
            local new_ctx = language_mw.run(ctx, message)
            assert.is_not_nil(new_ctx.lang)
        end)
    end)

    describe('user language', function()
        it('should use user language setting when set', function()
            env.redis.setex('cache:setting:' .. message.from.id .. ':language', 300, 'de_de')
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('de_de', new_ctx.lang_code)
            assert.are.same(mock_de_de, new_ctx.lang)
        end)

        it('should fall back to Telegram language code when no setting', function()
            message.from.language_code = 'de_de'
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('de_de', new_ctx.lang_code)
        end)

        it('should ignore unsupported Telegram language code', function()
            message.from.language_code = 'zz_zz'
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('en_gb', new_ctx.lang_code)
        end)

        it('should prefer user setting over Telegram language', function()
            message.from.language_code = 'de_de'
            env.redis.setex('cache:setting:' .. message.from.id .. ':language', 300, 'pt_br')
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('pt_br', new_ctx.lang_code)
        end)
    end)

    describe('group language override', function()
        it('should use group language when force is set', function()
            ctx.is_group = true
            env.redis.setex('cache:setting:' .. message.chat.id .. ':force group language', 300, 'true')
            env.redis.setex('cache:setting:' .. message.chat.id .. ':group language', 300, 'de_de')
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('de_de', new_ctx.lang_code)
        end)

        it('should not override in private chats', function()
            ctx.is_group = false
            env.redis.setex('cache:setting:' .. message.from.id .. ':language', 300, 'pt_br')
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('pt_br', new_ctx.lang_code)
        end)

        it('should not override when force is not set', function()
            ctx.is_group = true
            env.redis.setex('cache:setting:' .. message.from.id .. ':language', 300, 'pt_br')
            env.redis.setex('cache:setting:' .. message.chat.id .. ':group language', 300, 'de_de')
            -- No 'force group language' key
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('pt_br', new_ctx.lang_code)
        end)

        it('should fall back to en_gb when forced but no group lang set', function()
            ctx.is_group = true
            env.redis.setex('cache:setting:' .. message.chat.id .. ':force group language', 300, 'true')
            -- No 'group language' set
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('en_gb', new_ctx.lang_code)
        end)
    end)

    describe('when message has no from', function()
        it('should still set a default language', function()
            message.from = nil
            local new_ctx = language_mw.run(ctx, message)
            assert.are.equal('en_gb', new_ctx.lang_code)
            assert.is_not_nil(new_ctx.lang)
        end)
    end)

    describe('always continues', function()
        it('should always return true', function()
            local _, should_continue = language_mw.run(ctx, message)
            assert.is_true(should_continue)
        end)
    end)
end)
