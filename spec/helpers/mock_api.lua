--[[
    mattata v2.1 - Mock Telegram Bot API
    Records all calls and returns configurable responses for testing.
    Includes async/handler stubs for copas-based concurrency support.
]]

local mock_api = {}

function mock_api.new()
    local api = {
        info = { id = 123456789, username = 'testbot', first_name = 'Test Bot' },
        calls = {},
    }

    local custom_handlers = {}

    local function record(method, ...)
        table.insert(api.calls, { method = method, args = {...} })
    end

    function api.send_message(chat_id, text, opts)
        record('send_message', chat_id, text, opts)
        return { ok = true, result = { message_id = #api.calls, chat = { id = chat_id } } }
    end

    function api.get_chat_member(chat_id, user_id)
        record('get_chat_member', chat_id, user_id)
        if custom_handlers.get_chat_member then
            return custom_handlers.get_chat_member(chat_id, user_id)
        end
        -- Default: regular member
        return { ok = true, result = { status = 'member', user = { id = user_id } } }
    end

    function api.ban_chat_member(chat_id, user_id, opts)
        record('ban_chat_member', chat_id, user_id, opts)
        return { ok = true, result = true }
    end

    function api.unban_chat_member(chat_id, user_id)
        record('unban_chat_member', chat_id, user_id)
        return { ok = true, result = true }
    end

    function api.restrict_chat_member(chat_id, user_id, permissions, opts)
        record('restrict_chat_member', chat_id, user_id, permissions, opts)
        return { ok = true, result = true }
    end

    function api.send_photo(chat_id, photo, opts)
        record('send_photo', chat_id, photo, opts)
        return { ok = true, result = { message_id = #api.calls, chat = { id = chat_id } } }
    end

    function api.send_document(chat_id, document, opts)
        record('send_document', chat_id, document, opts)
        return { ok = true, result = { message_id = #api.calls, chat = { id = chat_id } } }
    end

    function api.send_video(chat_id, video, opts)
        record('send_video', chat_id, video, opts)
        return { ok = true, result = { message_id = #api.calls, chat = { id = chat_id } } }
    end

    function api.send_audio(chat_id, audio, opts)
        record('send_audio', chat_id, audio, opts)
        return { ok = true, result = { message_id = #api.calls, chat = { id = chat_id } } }
    end

    function api.delete_message(chat_id, message_id)
        record('delete_message', chat_id, message_id)
        return { ok = true, result = true }
    end

    function api.pin_chat_message(chat_id, message_id, opts)
        record('pin_chat_message', chat_id, message_id, opts)
        return { ok = true, result = true }
    end

    function api.unpin_chat_message(chat_id, opts)
        record('unpin_chat_message', chat_id, opts)
        return { ok = true, result = true }
    end

    function api.send_dice(chat_id, opts)
        record('send_dice', chat_id, opts)
        return { ok = true, result = { message_id = #api.calls, dice = { value = 4 } } }
    end

    function api.get_chat(chat_id)
        record('get_chat', chat_id)
        return { ok = true, result = { id = chat_id, first_name = 'Test User' } }
    end

    function api.edit_message_text(chat_id, message_id, text, opts)
        record('edit_message_text', chat_id, message_id, text, opts)
        return { ok = true, result = { message_id = message_id } }
    end

    function api.edit_message_reply_markup(chat_id, message_id, opts)
        record('edit_message_reply_markup', chat_id, message_id, opts)
        return { ok = true, result = { message_id = message_id } }
    end

    function api.answer_callback_query(callback_id, opts)
        record('answer_callback_query', callback_id, opts)
        return { ok = true }
    end

    function api.get_updates(timeout, offset, limit, allowed)
        record('get_updates', timeout, offset, limit, allowed)
        return { ok = true, result = {} }
    end

    function api.leave_chat(chat_id)
        record('leave_chat', chat_id)
        return { ok = true, result = true }
    end

    function api.inline_keyboard()
        local kb = {}
        function kb:row(...)
            return self
        end
        return kb
    end

    function api.row()
        local r = {}
        function r:callback_data_button(text, data)
            return self
        end
        function r:url_button(text, url)
            return self
        end
        return r
    end

    -- Helper to set custom get_chat_member behavior
    function api.set_admin(chat_id, user_id)
        local original_handler = custom_handlers.get_chat_member
        custom_handlers.get_chat_member = function(cid, uid)
            if cid == chat_id and uid == user_id then
                return {
                    ok = true,
                    result = {
                        status = 'administrator',
                        user = { id = uid },
                        can_restrict_members = true,
                        can_delete_messages = true,
                        can_pin_messages = true,
                        can_promote_members = true,
                        can_invite_users = true,
                    }
                }
            end
            if original_handler then
                return original_handler(cid, uid)
            end
            return { ok = true, result = { status = 'member', user = { id = uid } } }
        end
    end

    -- Helper to set the bot as an admin with specified permissions
    function api.set_bot_admin(chat_id, perms)
        perms = perms or {}
        local original_handler = custom_handlers.get_chat_member
        custom_handlers.get_chat_member = function(cid, uid)
            if cid == chat_id and uid == api.info.id then
                return {
                    ok = true,
                    result = {
                        status = 'administrator',
                        user = { id = uid },
                        can_restrict_members = perms.can_restrict_members or false,
                        can_delete_messages = perms.can_delete_messages or false,
                        can_pin_messages = perms.can_pin_messages or false,
                        can_promote_members = perms.can_promote_members or false,
                        can_invite_users = perms.can_invite_users or false,
                    }
                }
            end
            if original_handler then
                return original_handler(cid, uid)
            end
            return { ok = true, result = { status = 'member', user = { id = uid } } }
        end
    end

    function api.set_creator(chat_id, user_id)
        local original_handler = custom_handlers.get_chat_member
        custom_handlers.get_chat_member = function(cid, uid)
            if cid == chat_id and uid == user_id then
                return {
                    ok = true,
                    result = {
                        status = 'creator',
                        user = { id = uid },
                    }
                }
            end
            if original_handler then
                return original_handler(cid, uid)
            end
            return { ok = true, result = { status = 'member', user = { id = uid } } }
        end
    end

    -- Handler stubs (overwritten by router.run() in production)
    api.on_message = function() end
    api.on_edited_message = function() end
    api.on_callback_query = function() end
    api.on_inline_query = function() end
    api.on_chat_join_request = function() end
    api.on_chat_member = function() end
    api.on_my_chat_member = function() end
    api.on_message_reaction = function() end
    api.on_message_reaction_count = function() end
    api.on_chat_boost = function() end
    api.on_removed_chat_boost = function() end
    api.on_poll = function() end
    api.on_poll_answer = function() end

    -- Async stubs (telegram-bot-lua async system)
    api.async = {
        run = function() end,
        stop = function() end,
        all = function(fns) return {} end,
        spawn = function(fn) if fn then fn() end end,
        sleep = function() end,
        is_running = function() return false end,
    }

    -- api.run stub — no-op (prevents tests from entering copas.loop)
    function api.run(opts)
        record('run', opts)
    end

    -- process_update stub
    function api.process_update(update)
        record('process_update', update)
    end

    function api.reset()
        api.calls = {}
        custom_handlers = {}
    end

    function api.get_call(method)
        for _, call in ipairs(api.calls) do
            if call.method == method then return call end
        end
        return nil
    end

    function api.get_calls(method)
        local results = {}
        for _, call in ipairs(api.calls) do
            if call.method == method then
                table.insert(results, call)
            end
        end
        return results
    end

    function api.count_calls(method)
        local count = 0
        for _, call in ipairs(api.calls) do
            if call.method == method then count = count + 1 end
        end
        return count
    end

    return api
end

return mock_api
