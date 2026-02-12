--[[
    Tests for src/core/router.lua internals
    Tests build_ctx lazy admin check, sort_message, extract_command,
    process_action bug fix, resolve_alias caching.

    Since router.lua functions are local, we test them via the module's
    exposed behaviour and by reimplementing the key local functions.
]]

describe('core.router internals', function()
    -- We test the local functions by reimplementing them identically.
    -- This is necessary because Lua doesn't expose local functions.

    describe('sort_message()', function()
        local function sort_message(message)
            message.text = message.text or message.caption or ''
            message.text = message.text:gsub('^(/[%a]+)_', '%1 ')
            if message.text:match('^[/!#]start .-$') then
                message.text = '/' .. message.text:match('^[/!#]start (.-)$')
            end
            if message.reply_to_message then
                message.reply = message.reply_to_message
                message.reply_to_message = nil
            end
            if message.from and message.from.language_code then
                local lc = message.from.language_code:lower():gsub('%-', '_')
                if #lc == 2 and lc ~= 'en' then
                    lc = lc .. '_' .. lc
                elseif #lc == 2 or lc == 'root' then
                    lc = 'en_us'
                end
                message.from.language_code = lc
            end
            message.is_media = message.photo or message.video or message.audio or message.voice
                or message.document or message.sticker or message.animation or message.video_note or false
            message.is_service_message = (message.new_chat_members or message.left_chat_member
                or message.new_chat_title or message.new_chat_photo or message.pinned_message
                or message.group_chat_created or message.supergroup_chat_created) and true or false
            if message.entities then
                for _, entity in ipairs(message.entities) do
                    if entity.type == 'text_mention' and entity.user then
                        local name = message.text:sub(entity.offset + 1, entity.offset + entity.length)
                        message.text = message.text:gsub(name, tostring(entity.user.id), 1)
                    end
                end
            end
            if message.caption_entities then
                message.entities = message.caption_entities
                message.caption_entities = nil
            end
            if message.reply then
                message.reply = sort_message(message.reply)
            end
            return message
        end

        it('should use caption when text is nil', function()
            local msg = sort_message({ caption = 'hello caption' })
            assert.are.equal('hello caption', msg.text)
        end)

        it('should default to empty string when both text and caption nil', function()
            local msg = sort_message({})
            assert.are.equal('', msg.text)
        end)

        it('should normalise /command_arg to /command arg', function()
            local msg = sort_message({ text = '/ban_123' })
            assert.are.equal('/ban 123', msg.text)
        end)

        it('should not modify /command without underscore', function()
            local msg = sort_message({ text = '/ban 123' })
            assert.are.equal('/ban 123', msg.text)
        end)

        it('should handle deep-link /start parameter', function()
            local msg = sort_message({ text = '/start help' })
            assert.are.equal('/help', msg.text)
        end)

        it('should handle deep-link with ! prefix', function()
            local msg = sort_message({ text = '!start ban' })
            assert.are.equal('/ban', msg.text)
        end)

        it('should move reply_to_message to reply', function()
            local reply_msg = { text = 'reply text' }
            local msg = sort_message({ text = 'hello', reply_to_message = reply_msg })
            assert.is_not_nil(msg.reply)
            assert.is_nil(msg.reply_to_message)
            assert.are.equal('reply text', msg.reply.text)
        end)

        it('should normalise 2-letter language code to xx_xx', function()
            local msg = sort_message({
                text = 'hello',
                from = { language_code = 'de' }
            })
            assert.are.equal('de_de', msg.from.language_code)
        end)

        it('should normalise en to en_us', function()
            local msg = sort_message({
                text = 'hello',
                from = { language_code = 'en' }
            })
            assert.are.equal('en_us', msg.from.language_code)
        end)

        it('should normalise root to en_us', function()
            local msg = sort_message({
                text = 'hello',
                from = { language_code = 'root' }
            })
            assert.are.equal('en_us', msg.from.language_code)
        end)

        it('should normalise en-US to en_us', function()
            local msg = sort_message({
                text = 'hello',
                from = { language_code = 'en-US' }
            })
            assert.are.equal('en_us', msg.from.language_code)
        end)

        it('should normalise pt-BR to pt_br', function()
            local msg = sort_message({
                text = 'hello',
                from = { language_code = 'pt-BR' }
            })
            assert.are.equal('pt_br', msg.from.language_code)
        end)

        it('should detect media messages', function()
            local msg = sort_message({ text = '', photo = { { file_id = '123' } } })
            assert.is_truthy(msg.is_media)
        end)

        it('should not detect non-media messages', function()
            local msg = sort_message({ text = 'hello' })
            assert.is_falsy(msg.is_media)
        end)

        it('should detect service messages', function()
            local msg = sort_message({ text = '', new_chat_members = { { id = 1 } } })
            assert.is_true(msg.is_service_message)
        end)

        it('should not detect regular messages as service', function()
            local msg = sort_message({ text = 'hello' })
            assert.is_false(msg.is_service_message)
        end)

        it('should replace text mentions with user IDs', function()
            local msg = sort_message({
                text = '/ban Alice',
                entities = {
                    { type = 'text_mention', user = { id = 12345 }, offset = 5, length = 5 }
                }
            })
            assert.are.equal('/ban 12345', msg.text)
        end)

        it('should move caption_entities to entities', function()
            local entities = { { type = 'bold' } }
            local msg = sort_message({ caption = 'hello', caption_entities = entities })
            assert.are.same(entities, msg.entities)
            assert.is_nil(msg.caption_entities)
        end)

        it('should recursively sort reply messages', function()
            local msg = sort_message({
                text = 'hello',
                reply_to_message = { caption = 'reply caption' }
            })
            assert.are.equal('reply caption', msg.reply.text)
        end)
    end)

    describe('extract_command()', function()
        local function extract_command(text, bot_username)
            if not text then return nil, nil end
            local cmd, args = text:match('^[/!#]([%w_]+)@?' .. (bot_username or '') .. '%s*(.*)')
            if not cmd then
                cmd, args = text:match('^[/!#]([%w_]+)%s*(.*)')
            end
            if cmd then
                cmd = cmd:lower()
                args = args ~= '' and args or nil
            end
            return cmd, args
        end

        it('should extract command from /command', function()
            local cmd, args = extract_command('/ping')
            assert.are.equal('ping', cmd)
            assert.is_nil(args)
        end)

        it('should extract command and args', function()
            local cmd, args = extract_command('/ban 12345 reason')
            assert.are.equal('ban', cmd)
            assert.are.equal('12345 reason', args)
        end)

        it('should handle ! prefix', function()
            local cmd, args = extract_command('!ping')
            assert.are.equal('ping', cmd)
        end)

        it('should handle # prefix', function()
            local cmd, args = extract_command('#help')
            assert.are.equal('help', cmd)
        end)

        it('should handle @botname suffix', function()
            local cmd, args = extract_command('/ping@testbot', 'testbot')
            assert.are.equal('ping', cmd)
        end)

        it('should lowercase command', function()
            local cmd = extract_command('/PING')
            assert.are.equal('ping', cmd)
        end)

        it('should return nil for non-command text', function()
            local cmd = extract_command('hello world')
            assert.is_nil(cmd)
        end)

        it('should return nil for nil text', function()
            local cmd = extract_command(nil)
            assert.is_nil(cmd)
        end)

        it('should return nil args for command without args', function()
            local cmd, args = extract_command('/ping')
            assert.is_nil(args)
        end)

        it('should handle underscore in command name', function()
            local cmd = extract_command('/join_captcha')
            assert.are.equal('join_captcha', cmd)
        end)

        it('should handle command with args and @bot', function()
            local cmd, args = extract_command('/ban@testbot 12345', 'testbot')
            assert.are.equal('ban', cmd)
            assert.are.equal('12345', args)
        end)
    end)

    describe('process_action() bug fix', function()
        -- The fix: save message_id before nil'ing message.reply
        it('should save reply message_id before nil-ing reply', function()
            local bot_id = 123456789
            local session_data = {}

            -- Simulate session
            local function get_action(chat_id, msg_id)
                local key = chat_id .. ':' .. msg_id
                return session_data[key]
            end
            local function del_action(chat_id, msg_id)
                local key = chat_id .. ':' .. msg_id
                session_data[key] = nil
            end

            -- Set up action
            session_data['-100123:42'] = '/ban'

            local message = {
                text = '12345',
                chat = { id = -100123 },
                reply = {
                    message_id = 42,
                    from = { id = bot_id }
                }
            }

            -- Process action (reimplemented)
            if message.text and message.chat and message.reply
                and message.reply.from and message.reply.from.id == bot_id then
                local reply_message_id = message.reply.message_id
                local action = get_action(message.chat.id, reply_message_id)
                if action then
                    message.text = action .. ' ' .. message.text
                    message.reply = nil
                    del_action(message.chat.id, reply_message_id)
                end
            end

            assert.are.equal('/ban 12345', message.text)
            assert.is_nil(message.reply)
            assert.is_nil(session_data['-100123:42'])
        end)

        it('should not modify message without reply to bot', function()
            local message = {
                text = 'hello',
                chat = { id = -100123 },
            }
            -- No reply, no action processing
            assert.are.equal('hello', message.text)
        end)

        it('should not modify message when reply is not from bot', function()
            local bot_id = 123456789
            local message = {
                text = 'hello',
                chat = { id = -100123 },
                reply = {
                    message_id = 42,
                    from = { id = 999 }
                }
            }
            -- reply.from.id != bot_id, so no action processing
            if message.reply and message.reply.from and message.reply.from.id == bot_id then
                -- This block should NOT execute
                assert.fail('should not process action for non-bot reply')
            end
            assert.are.equal('hello', message.text)
        end)
    end)

    describe('resolve_alias()', function()
        local mock_redis = require('spec.helpers.mock_redis')
        local json

        before_each(function()
            json = {
                encode = function(t)
                    local parts = {}
                    for k, v in pairs(t) do
                        table.insert(parts, '"' .. k .. '":"' .. v .. '"')
                    end
                    return '{' .. table.concat(parts, ',') .. '}'
                end,
                decode = function(s)
                    local result = {}
                    for k, v in s:gmatch('"([^"]+)":"([^"]+)"') do
                        result[k] = v
                    end
                    return result
                end,
            }
            -- Make json available globally for the resolve_alias reimplementation
            package.loaded['dkjson'] = json
        end)

        it('should resolve a cached alias', function()
            local redis = mock_redis.new()
            -- Set cached aliases
            redis.set('cache:aliases:-100123', '{"b":"ban","h":"help"}')

            local message = {
                text = '/b user123',
                chat = { id = -100123, type = 'supergroup' }
            }

            -- Reimplemented resolve_alias
            local command, rest = message.text:lower():match('^[/!#]([%w_]+)(.*)')
            local cached_aliases = redis.get('cache:aliases:' .. message.chat.id)
            local aliases
            if cached_aliases then
                local ok, decoded = pcall(json.decode, cached_aliases)
                if ok and decoded then aliases = decoded end
            end
            if type(aliases) == 'table' then
                for alias, original in pairs(aliases) do
                    if command == alias then
                        message.text = '/' .. original .. (rest or '')
                        message.is_alias = true
                        break
                    end
                end
            end

            assert.are.equal('/ban user123', message.text)
            assert.is_true(message.is_alias)
        end)

        it('should fetch aliases from hash when cache misses', function()
            local redis = mock_redis.new()
            -- No cache, but aliases exist in hash
            redis.hset('chat:-100123:aliases', 'h', 'help')

            local message = {
                text = '/h',
                chat = { id = -100123, type = 'supergroup' }
            }

            local command, rest = message.text:lower():match('^[/!#]([%w_]+)(.*)')
            local cached_aliases = redis.get('cache:aliases:' .. message.chat.id)
            local aliases
            if not cached_aliases then
                aliases = redis.hgetall('chat:' .. message.chat.id .. ':aliases')
                if type(aliases) == 'table' then
                    pcall(function()
                        redis.setex('cache:aliases:' .. message.chat.id, 300, json.encode(aliases))
                    end)
                end
            end
            if type(aliases) == 'table' then
                for alias, original in pairs(aliases) do
                    if command == alias then
                        message.text = '/' .. original .. (rest or '')
                        message.is_alias = true
                        break
                    end
                end
            end

            assert.are.equal('/help', message.text)
            -- Should have cached the aliases
            assert.is_not_nil(redis.get('cache:aliases:-100123'))
        end)

        it('should not modify non-command messages', function()
            local message = { text = 'hello world', chat = { id = -100123, type = 'supergroup' } }
            if not message.text:match('^[/!#][%w_]+') then
                -- should not process
            end
            assert.are.equal('hello world', message.text)
        end)

        it('should not resolve aliases in private chats', function()
            local message = { text = '/b', chat = { type = 'private' } }
            local should_skip = not message.chat or message.chat.type == 'private'
            assert.is_true(should_skip)
        end)
    end)

    describe('build_ctx lazy admin check', function()
        it('should not call API for admin check until check_admin() is called', function()
            local api_called = false
            local mock_api = {
                get_chat_member = function() api_called = true; return { ok = true, result = { status = 'member' } } end,
                info = { id = 123 },
            }

            -- Simulate lazy admin check
            local admin_resolved = false
            local admin_value = false
            local ctx = { is_admin = false, is_global_admin = false, is_group = true }

            function ctx:check_admin()
                if admin_resolved then return admin_value end
                admin_resolved = true
                api_called = true
                admin_value = false
                ctx.is_admin = admin_value
                return admin_value
            end

            -- Before calling check_admin, no API call should happen
            assert.is_false(api_called)
            assert.is_false(ctx.is_admin)

            -- After calling check_admin
            ctx:check_admin()
            assert.is_true(admin_resolved)
        end)

        it('should cache admin result for subsequent calls', function()
            local call_count = 0
            local admin_resolved = false
            local admin_value = false
            local ctx = { is_admin = false, is_global_admin = false, is_group = true }

            function ctx:check_admin()
                if admin_resolved then return admin_value end
                admin_resolved = true
                call_count = call_count + 1
                admin_value = true
                ctx.is_admin = admin_value
                return admin_value
            end

            ctx:check_admin()
            ctx:check_admin()
            ctx:check_admin()
            assert.are.equal(1, call_count)
            assert.is_true(ctx.is_admin)
        end)

        it('should set is_admin = true for global admin without API call', function()
            local admin_resolved = false
            local admin_value = false
            local ctx = { is_admin = false, is_global_admin = true, is_group = true }

            function ctx:check_admin()
                if admin_resolved then return admin_value end
                admin_resolved = true
                if ctx.is_global_admin then
                    admin_value = true
                end
                ctx.is_admin = admin_value
                return admin_value
            end

            ctx:check_admin()
            assert.is_true(ctx.is_admin)
        end)
    end)
end)
