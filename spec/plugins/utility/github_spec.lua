describe('plugins.utility.github', function()
    local github_plugin
    local test_helper = require('spec.helpers.test_helper')
    local json = require('dkjson')
    local env, ctx, message

    -- Mock state (shared across before_each via upvalues)
    local http_responses, http_calls
    local test_config

    -- Sample API responses
    local SAMPLE_USER = {
        login = 'octocat', id = 1, name = 'The Octocat', bio = 'GitHub mascot',
        public_repos = 8, followers = 1000, following = 10,
        company = '@github', location = 'San Francisco',
        html_url = 'https://github.com/octocat', avatar_url = 'https://avatars.githubusercontent.com/u/1',
    }

    local SAMPLE_REPO = {
        full_name = 'octocat/Hello-World', description = 'My first repo',
        language = 'Ruby', stargazers_count = 80, forks_count = 9,
        open_issues_count = 2, license = { spdx_id = 'MIT' },
        created_at = '2011-01-26T19:01:12Z', private = false,
        html_url = 'https://github.com/octocat/Hello-World',
    }

    local SAMPLE_REPOS = {
        { full_name = 'octocat/Hello-World', description = 'My first repo',
          stargazers_count = 80, language = 'Ruby', private = false,
          html_url = 'https://github.com/octocat/Hello-World' },
    }

    local SAMPLE_ISSUE = {
        number = 1, title = 'Found a bug', state = 'open',
        user = { login = 'octocat' },
        labels = { { name = 'bug', color = 'fc2929' } },
        assignees = { { login = 'octocat' } },
        body = 'Description of the bug...',
        html_url = 'https://github.com/octocat/Hello-World/issues/1',
        created_at = '2011-04-22T13:33:48Z', comments = 3,
    }

    local SAMPLE_ISSUES = {
        { number = 1, title = 'Found a bug', state = 'open',
          user = { login = 'octocat' },
          labels = { { name = 'bug' } },
          html_url = 'https://github.com/octocat/Hello-World/issues/1',
          created_at = '2011-04-22T13:33:48Z' },
    }

    local SAMPLE_STARRED = {
        { full_name = 'octocat/Hello-World', description = 'My first repo',
          stargazers_count = 80, html_url = 'https://github.com/octocat/Hello-World' },
    }

    local SAMPLE_NOTIFICATIONS = {
        { id = '1', reason = 'mention', unread = true,
          subject = { title = 'Issue title', type = 'Issue' },
          repository = { full_name = 'octocat/Hello-World' },
          updated_at = '2014-11-07T22:01:45Z' },
    }

    local SAMPLE_DEVICE_CODE = {
        device_code = '3584d83530557fdd1f46af8289938c8ef79f9dc5',
        user_code = 'WDJB-MJHT', verification_uri = 'https://github.com/login/device',
        expires_in = 900, interval = 5,
    }

    local SAMPLE_ACCESS_TOKEN = {
        access_token = 'gho_16C7e42F292c6912E7710c838347Ae178B4a',
        token_type = 'bearer', scope = 'repo,notifications,user',
    }

    before_each(function()
        http_responses = {}
        http_calls = {}
        test_config = {
            GITHUB_CLIENT_ID = 'test_client_id',
            GITHUB_CLIENT_SECRET = 'test_client_secret',
        }

        package.loaded['src.plugins.utility.github'] = nil
        package.loaded['src.core.http'] = {
            get = function(url, headers)
                table.insert(http_calls, { method = 'GET', url = url, headers = headers })
                local r = http_responses['GET:' .. url]
                if r then return r.body or '', r.code or 200 end
                return '', 404
            end,
            post = function(url, body, content_type, headers)
                table.insert(http_calls, { method = 'POST', url = url, body = body, content_type = content_type, headers = headers })
                local r = http_responses['POST:' .. url]
                if r then return r.body or '', r.code or 200 end
                return '', 404
            end,
            request = function(opts)
                local m = opts.method or 'GET'
                table.insert(http_calls, { method = m, url = opts.url, headers = opts.headers })
                local r = http_responses[m .. ':' .. opts.url]
                if r then return r.body or '', r.code or 200 end
                return '', 404
            end,
        }
        package.loaded['src.core.config'] = {
            get = function(key, default)
                if test_config[key] ~= nil then return test_config[key] end
                return default
            end,
        }
        package.loaded['src.core.logger'] = {
            debug = function() end, info = function() end,
            warn = function() end, error = function() end,
        }
        package.loaded['telegram-bot-lua.tools'] = {
            escape_html = function(text)
                if not text then return '' end
                return tostring(text):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
            end,
        }

        github_plugin = require('src.plugins.utility.github')
        env = test_helper.setup()
        ctx = test_helper.make_ctx(env)
    end)

    after_each(function()
        test_helper.teardown(env)
    end)

    -- Helper to set mock HTTP responses
    local function mock_get(url, data, code)
        http_responses['GET:' .. url] = { body = json.encode(data), code = code or 200 }
    end
    local function mock_get_raw(url, body, code)
        http_responses['GET:' .. url] = { body = body, code = code or 200 }
    end
    local function mock_post(url, data, code)
        http_responses['POST:' .. url] = { body = json.encode(data), code = code or 200 }
    end
    local function mock_put(url, body, code)
        http_responses['PUT:' .. url] = { body = body or '', code = code or 204 }
    end
    local function mock_delete(url, body, code)
        http_responses['DELETE:' .. url] = { body = body or '', code = code or 204 }
    end

    -- Helper: store a token in redis for the test user
    local function store_token(user_id)
        user_id = user_id or 111111
        env.redis.set('github:token:' .. user_id, 'test_token_123')
    end

    -- Helper: set up pending device flow
    local function store_pending_device(user_id, overrides)
        user_id = user_id or 111111
        local uid = tostring(user_id)
        local dk = 'github:device:' .. uid
        local defaults = {
            device_code = 'test_device_code',
            user_code = 'TEST-CODE',
            verification_uri = 'https://github.com/login/device',
            interval = '5',
            expires_at = tostring(os.time() + 600),
            chat_id = tostring(user_id),
            last_poll = '0',
        }
        if overrides then
            for k, v in pairs(overrides) do defaults[k] = v end
        end
        for k, v in pairs(defaults) do
            env.redis.hset(dk, k, v)
        end
        env.redis.sadd('github:pending_devices', uid)
    end

    -- ================================================================
    -- 1. Plugin metadata
    -- ================================================================
    describe('plugin metadata', function()
        it('should have correct name', function()
            assert.are.equal('github', github_plugin.name)
        end)

        it('should have correct category', function()
            assert.are.equal('utility', github_plugin.category)
        end)

        it('should have commands table with github and gh', function()
            assert.is_table(github_plugin.commands)
            assert.is_true(#github_plugin.commands >= 2)
        end)

        it('should have a help string', function()
            assert.is_string(github_plugin.help)
            assert.is_true(#github_plugin.help > 0)
        end)

        it('should have a description', function()
            assert.is_string(github_plugin.description)
        end)
    end)

    -- ================================================================
    -- 2. Dispatch
    -- ================================================================
    describe('dispatch', function()
        it('should show help with HTML parse mode when no args', function()
            message = test_helper.make_message({ text = '/gh', command = 'gh', args = '' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_api_called(env.api, 'send_message')
            local call = env.api.get_call('send_message')
            assert.are.equal(message.chat.id, call.args[1])
            assert.is_truthy(call.args[2]:match('login'))
            assert.are.equal('html', call.args[3].parse_mode)
        end)

        it('should show help for unknown subcommand', function()
            message = test_helper.make_message({ text = '/gh foobar', command = 'gh', args = 'foobar' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Unknown command')
        end)

        it('should route owner/repo to repo handler', function()
            mock_get('https://api.github.com/repos/octocat/Hello-World', SAMPLE_REPO)
            message = test_helper.make_message({ text = '/gh octocat/Hello-World', command = 'gh', args = 'octocat/Hello-World' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'octocat/Hello%-World')
        end)
    end)

    -- ================================================================
    -- 3. /gh login
    -- ================================================================
    describe('/gh login', function()
        it('should refuse in group chat', function()
            message = test_helper.make_message({ text = '/gh login', command = 'gh', args = 'login' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'private chat')
        end)

        it('should refuse if already connected', function()
            message = test_helper.make_private_message({ text = '/gh login', command = 'gh', args = 'login' })
            store_token(message.from.id)
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'already connected')
        end)

        it('should refuse if already pending', function()
            message = test_helper.make_private_message({ text = '/gh login', command = 'gh', args = 'login' })
            store_pending_device(message.from.id)
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'pending login')
        end)

        it('should refuse if config is missing', function()
            test_config.GITHUB_CLIENT_ID = nil
            -- Re-require with new config
            package.loaded['src.plugins.utility.github'] = nil
            github_plugin = require('src.plugins.utility.github')
            message = test_helper.make_private_message({ text = '/gh login', command = 'gh', args = 'login' })
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'not configured')
        end)

        it('should start device flow on success', function()
            mock_post('https://github.com/login/device/code', SAMPLE_DEVICE_CODE)
            message = test_helper.make_private_message({ text = '/gh login', command = 'gh', args = 'login' })
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            -- Should store device flow in redis
            local dk = 'github:device:' .. message.from.id
            assert.are.equal(SAMPLE_DEVICE_CODE.device_code, env.redis.hget(dk, 'device_code'))
            assert.are.equal(SAMPLE_DEVICE_CODE.user_code, env.redis.hget(dk, 'user_code'))
            -- Should send verification message
            test_helper.assert_sent_message_matches(env.api, 'WDJB%-MJHT')
        end)

        it('should handle GitHub API failure', function()
            http_responses['POST:https://github.com/login/device/code'] = { body = '', code = 500 }
            message = test_helper.make_private_message({ text = '/gh login', command = 'gh', args = 'login' })
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Failed to start')
        end)

        it('should set correct TTL on device key', function()
            mock_post('https://github.com/login/device/code', SAMPLE_DEVICE_CODE)
            message = test_helper.make_private_message({ text = '/gh login', command = 'gh', args = 'login' })
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            local dk = 'github:device:' .. message.from.id
            assert.are.equal(900, env.redis.ttls[dk])
        end)

        it('should add user to pending set', function()
            mock_post('https://github.com/login/device/code', SAMPLE_DEVICE_CODE)
            message = test_helper.make_private_message({ text = '/gh login', command = 'gh', args = 'login' })
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            assert.are.equal(1, env.redis.sismember('github:pending_devices', tostring(message.from.id)))
        end)

        it('should send properly formatted verification message', function()
            mock_post('https://github.com/login/device/code', SAMPLE_DEVICE_CODE)
            message = test_helper.make_private_message({ text = '/gh login', command = 'gh', args = 'login' })
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.is_truthy(call.args[2]:match('GitHub Login'))
            assert.is_truthy(call.args[2]:match('github.com/login/device'))
            assert.is_truthy(call.args[2]:match('15 minutes'))
            assert.are.equal('html', call.args[3].parse_mode)
        end)
    end)

    -- ================================================================
    -- 4. /gh logout
    -- ================================================================
    describe('/gh logout', function()
        it('should refuse in group chat', function()
            message = test_helper.make_message({ text = '/gh logout', command = 'gh', args = 'logout' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'private chat')
        end)

        it('should refuse if not connected', function()
            message = test_helper.make_private_message({ text = '/gh logout', command = 'gh', args = 'logout' })
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'not connected')
        end)

        it('should delete token from redis', function()
            message = test_helper.make_private_message({ text = '/gh logout', command = 'gh', args = 'logout' })
            store_token(message.from.id)
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            assert.is_nil(env.redis.get('github:token:' .. message.from.id))
            test_helper.assert_sent_message_matches(env.api, 'disconnected')
        end)

        it('should attempt token revocation', function()
            message = test_helper.make_private_message({ text = '/gh logout', command = 'gh', args = 'logout' })
            store_token(message.from.id)
            mock_delete('https://api.github.com/applications/test_client_id/token', '', 204)
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            -- Should have attempted the DELETE request
            local found = false
            for _, c in ipairs(http_calls) do
                if c.method == 'DELETE' and c.url:match('applications') then
                    found = true
                    break
                end
            end
            assert.is_true(found)
        end)

        it('should handle revocation failure gracefully', function()
            message = test_helper.make_private_message({ text = '/gh logout', command = 'gh', args = 'logout' })
            store_token(message.from.id)
            -- Don't set up a mock response — will 404/error
            ctx.is_private = true
            github_plugin.on_message(env.api, message, ctx)
            -- Should still delete token and send success
            assert.is_nil(env.redis.get('github:token:' .. message.from.id))
            test_helper.assert_sent_message_matches(env.api, 'disconnected')
        end)
    end)

    -- ================================================================
    -- 5. /gh me
    -- ================================================================
    describe('/gh me', function()
        it('should show error when no token', function()
            message = test_helper.make_message({ text = '/gh me', command = 'gh', args = 'me' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'connect your GitHub')
        end)

        it('should format user profile', function()
            message = test_helper.make_message({ text = '/gh me', command = 'gh', args = 'me' })
            store_token(message.from.id)
            mock_get('https://api.github.com/user', SAMPLE_USER)
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            local text = call.args[2]
            assert.is_truthy(text:match('octocat'))
            assert.is_truthy(text:match('The Octocat'))
            assert.is_truthy(text:match('GitHub mascot'))
            assert.is_truthy(text:match('@github'))
            assert.is_truthy(text:match('San Francisco'))
            assert.is_truthy(text:match('1000'))
        end)

        it('should handle API failure', function()
            message = test_helper.make_message({ text = '/gh me', command = 'gh', args = 'me' })
            store_token(message.from.id)
            mock_get_raw('https://api.github.com/user', '', 500)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Failed to reach')
        end)

        it('should clear token on 401', function()
            message = test_helper.make_message({ text = '/gh me', command = 'gh', args = 'me' })
            store_token(message.from.id)
            mock_get_raw('https://api.github.com/user', '', 401)
            github_plugin.on_message(env.api, message, ctx)
            assert.is_nil(env.redis.get('github:token:' .. message.from.id))
            test_helper.assert_sent_message_matches(env.api, 'expired')
        end)

        it('should send with HTML parse mode', function()
            message = test_helper.make_message({ text = '/gh me', command = 'gh', args = 'me' })
            store_token(message.from.id)
            mock_get('https://api.github.com/user', SAMPLE_USER)
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.are.equal('html', call.args[3].parse_mode)
        end)
    end)

    -- ================================================================
    -- 6. /gh repos
    -- ================================================================
    describe('/gh repos', function()
        it('should list own repos', function()
            message = test_helper.make_message({ text = '/gh repos', command = 'gh', args = 'repos' })
            store_token(message.from.id)
            mock_get('https://api.github.com/user/repos?per_page=5&sort=updated&page=1', SAMPLE_REPOS)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Your Repositories')
            test_helper.assert_sent_message_matches(env.api, 'Hello%-World')
        end)

        it('should list specified user repos', function()
            message = test_helper.make_message({ text = '/gh repos octocat', command = 'gh', args = 'repos octocat' })
            store_token(message.from.id)
            mock_get('https://api.github.com/users/octocat/repos?per_page=5&sort=updated&page=1', SAMPLE_REPOS)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'octocat')
        end)

        it('should handle empty list', function()
            message = test_helper.make_message({ text = '/gh repos', command = 'gh', args = 'repos' })
            store_token(message.from.id)
            mock_get('https://api.github.com/user/repos?per_page=5&sort=updated&page=1', {})
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'No repositories')
        end)

        it('should show pagination keyboard when has more', function()
            -- Return exactly PER_PAGE items to trigger has_more
            local repos = {}
            for i = 1, 5 do
                table.insert(repos, { full_name = 'user/repo-' .. i, stargazers_count = i })
            end
            message = test_helper.make_message({ text = '/gh repos', command = 'gh', args = 'repos' })
            store_token(message.from.id)
            mock_get('https://api.github.com/user/repos?per_page=5&sort=updated&page=1', repos)
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.is_not_nil(call.args[3].reply_markup)
        end)

        it('should handle API failure', function()
            message = test_helper.make_message({ text = '/gh repos', command = 'gh', args = 'repos' })
            store_token(message.from.id)
            mock_get_raw('https://api.github.com/user/repos?per_page=5&sort=updated&page=1', '', 500)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Failed to reach')
        end)
    end)

    -- ================================================================
    -- 7. /gh owner/repo
    -- ================================================================
    describe('/gh owner/repo', function()
        it('should format repo info', function()
            mock_get('https://api.github.com/repos/octocat/Hello-World', SAMPLE_REPO)
            message = test_helper.make_message({ text = '/gh octocat/Hello-World', command = 'gh', args = 'octocat/Hello-World' })
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            local text = call.args[2]
            assert.is_truthy(text:match('octocat/Hello%-World'))
            assert.is_truthy(text:match('My first repo'))
            assert.is_truthy(text:match('Ruby'))
            assert.is_truthy(text:match('80'))
            assert.is_truthy(text:match('MIT'))
        end)

        it('should use token if available', function()
            store_token(111111)
            mock_get('https://api.github.com/repos/octocat/Hello-World', SAMPLE_REPO)
            message = test_helper.make_message({ text = '/gh octocat/Hello-World', command = 'gh', args = 'octocat/Hello-World' })
            github_plugin.on_message(env.api, message, ctx)
            -- Check that auth header was set
            local found_auth = false
            for _, c in ipairs(http_calls) do
                if c.headers and c.headers['Authorization'] then
                    found_auth = true
                    break
                end
            end
            assert.is_true(found_auth)
        end)

        it('should work without token', function()
            mock_get('https://api.github.com/repos/octocat/Hello-World', SAMPLE_REPO)
            message = test_helper.make_message({ text = '/gh octocat/Hello-World', command = 'gh', args = 'octocat/Hello-World' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'octocat/Hello%-World')
        end)

        it('should handle not found', function()
            mock_get_raw('https://api.github.com/repos/octocat/nope', '', 404)
            message = test_helper.make_message({ text = '/gh octocat/nope', command = 'gh', args = 'octocat/nope' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Not found')
        end)

        it('should accept GitHub URL format', function()
            mock_get('https://api.github.com/repos/octocat/Hello-World', SAMPLE_REPO)
            message = test_helper.make_message({
                text = '/gh https://github.com/octocat/Hello-World',
                command = 'gh', args = 'https://github.com/octocat/Hello-World',
            })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'octocat/Hello%-World')
        end)
    end)

    -- ================================================================
    -- 8. /gh issues
    -- ================================================================
    describe('/gh issues', function()
        it('should list open issues', function()
            message = test_helper.make_message({ text = '/gh issues octocat/Hello-World', command = 'gh', args = 'issues octocat/Hello-World' })
            mock_get('https://api.github.com/repos/octocat/Hello-World/issues?per_page=5&state=open&page=1', SAMPLE_ISSUES)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Found a bug')
        end)

        it('should handle empty issues list', function()
            message = test_helper.make_message({ text = '/gh issues octocat/Hello-World', command = 'gh', args = 'issues octocat/Hello-World' })
            mock_get('https://api.github.com/repos/octocat/Hello-World/issues?per_page=5&state=open&page=1', {})
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'No open issues')
        end)

        it('should show pagination keyboard when has more', function()
            local issues = {}
            for i = 1, 5 do
                table.insert(issues, { number = i, title = 'Issue ' .. i, state = 'open',
                    user = { login = 'test' }, labels = {}, created_at = '2024-01-01T00:00:00Z' })
            end
            message = test_helper.make_message({ text = '/gh issues octocat/Hello-World', command = 'gh', args = 'issues octocat/Hello-World' })
            mock_get('https://api.github.com/repos/octocat/Hello-World/issues?per_page=5&state=open&page=1', issues)
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.is_not_nil(call.args[3].reply_markup)
        end)

        it('should require owner/repo argument', function()
            message = test_helper.make_message({ text = '/gh issues', command = 'gh', args = 'issues' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Usage')
        end)
    end)

    -- ================================================================
    -- 9. /gh issue
    -- ================================================================
    describe('/gh issue', function()
        it('should show issue details', function()
            message = test_helper.make_message({ text = '/gh issue octocat/Hello-World#1', command = 'gh', args = 'issue octocat/Hello-World#1' })
            mock_get('https://api.github.com/repos/octocat/Hello-World/issues/1', SAMPLE_ISSUE)
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            local text = call.args[2]
            assert.is_truthy(text:match('Found a bug'))
            assert.is_truthy(text:match('open'))
            assert.is_truthy(text:match('octocat'))
        end)

        it('should truncate long body', function()
            local long_issue = {
                number = 1, title = 'Bug', state = 'open',
                user = { login = 'test' }, labels = {}, assignees = {},
                body = string.rep('x', 300),
                html_url = 'https://github.com/test/test/issues/1',
                created_at = '2024-01-01T00:00:00Z', comments = 0,
            }
            message = test_helper.make_message({ text = '/gh issue test/test#1', command = 'gh', args = 'issue test/test#1' })
            mock_get('https://api.github.com/repos/test/test/issues/1', long_issue)
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.is_truthy(call.args[2]:match('%.%.%.'))
        end)

        it('should handle not found', function()
            message = test_helper.make_message({ text = '/gh issue octocat/Hello-World#999', command = 'gh', args = 'issue octocat/Hello-World#999' })
            mock_get_raw('https://api.github.com/repos/octocat/Hello-World/issues/999', '', 404)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Not found')
        end)

        it('should show labels and state', function()
            message = test_helper.make_message({ text = '/gh issue octocat/Hello-World#1', command = 'gh', args = 'issue octocat/Hello-World#1' })
            mock_get('https://api.github.com/repos/octocat/Hello-World/issues/1', SAMPLE_ISSUE)
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            local text = call.args[2]
            assert.is_truthy(text:match('bug'))
            assert.is_truthy(text:match('open'))
        end)
    end)

    -- ================================================================
    -- 10. /gh starred
    -- ================================================================
    describe('/gh starred', function()
        it('should list starred repos', function()
            message = test_helper.make_message({ text = '/gh starred', command = 'gh', args = 'starred' })
            store_token(message.from.id)
            mock_get('https://api.github.com/user/starred?per_page=5&page=1', SAMPLE_STARRED)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Starred Repositories')
            test_helper.assert_sent_message_matches(env.api, 'Hello%-World')
        end)

        it('should handle empty starred list', function()
            message = test_helper.make_message({ text = '/gh starred', command = 'gh', args = 'starred' })
            store_token(message.from.id)
            mock_get('https://api.github.com/user/starred?per_page=5&page=1', {})
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'No starred')
        end)

        it('should show pagination when has more', function()
            local repos = {}
            for i = 1, 5 do
                table.insert(repos, { full_name = 'user/repo-' .. i, stargazers_count = i })
            end
            message = test_helper.make_message({ text = '/gh starred', command = 'gh', args = 'starred' })
            store_token(message.from.id)
            mock_get('https://api.github.com/user/starred?per_page=5&page=1', repos)
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.is_not_nil(call.args[3].reply_markup)
        end)
    end)

    -- ================================================================
    -- 11. /gh star + /gh unstar
    -- ================================================================
    describe('/gh star and /gh unstar', function()
        it('should star a repo with PUT and confirm', function()
            message = test_helper.make_message({ text = '/gh star octocat/Hello-World', command = 'gh', args = 'star octocat/Hello-World' })
            store_token(message.from.id)
            mock_put('https://api.github.com/user/starred/octocat/Hello-World', '', 204)
            github_plugin.on_message(env.api, message, ctx)
            -- Check PUT was made
            local found_put = false
            for _, c in ipairs(http_calls) do
                if c.method == 'PUT' and c.url:match('starred/octocat') then found_put = true end
            end
            assert.is_true(found_put)
            test_helper.assert_sent_message_matches(env.api, 'Starred')
        end)

        it('should unstar a repo with DELETE and confirm', function()
            message = test_helper.make_message({ text = '/gh unstar octocat/Hello-World', command = 'gh', args = 'unstar octocat/Hello-World' })
            store_token(message.from.id)
            mock_delete('https://api.github.com/user/starred/octocat/Hello-World', '', 204)
            github_plugin.on_message(env.api, message, ctx)
            local found_delete = false
            for _, c in ipairs(http_calls) do
                if c.method == 'DELETE' and c.url:match('starred/octocat') then found_delete = true end
            end
            assert.is_true(found_delete)
            test_helper.assert_sent_message_matches(env.api, 'Unstarred')
        end)

        it('should require auth for star and unstar', function()
            message = test_helper.make_message({ text = '/gh star octocat/Hello-World', command = 'gh', args = 'star octocat/Hello-World' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'connect your GitHub')
            env.api.reset()
            message = test_helper.make_message({ text = '/gh unstar octocat/Hello-World', command = 'gh', args = 'unstar octocat/Hello-World' })
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'connect your GitHub')
        end)

        it('should require owner/repo argument', function()
            message = test_helper.make_message({ text = '/gh star', command = 'gh', args = 'star' })
            store_token(message.from.id)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Usage')
        end)
    end)

    -- ================================================================
    -- 12. /gh notifications
    -- ================================================================
    describe('/gh notifications', function()
        it('should list unread notifications', function()
            message = test_helper.make_message({ text = '/gh notifications', command = 'gh', args = 'notifications' })
            store_token(message.from.id)
            mock_get('https://api.github.com/notifications?per_page=5&page=1', SAMPLE_NOTIFICATIONS)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Issue title')
            test_helper.assert_sent_message_matches(env.api, 'mention')
        end)

        it('should handle empty notifications', function()
            message = test_helper.make_message({ text = '/gh notifications', command = 'gh', args = 'notifications' })
            store_token(message.from.id)
            mock_get('https://api.github.com/notifications?per_page=5&page=1', {})
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'No unread')
        end)

        it('should show pagination when has more', function()
            local notifs = {}
            for i = 1, 5 do
                table.insert(notifs, {
                    id = tostring(i), reason = 'mention', unread = true,
                    subject = { title = 'Notif ' .. i, type = 'Issue' },
                    repository = { full_name = 'user/repo' },
                    updated_at = '2024-01-01T00:00:00Z',
                })
            end
            message = test_helper.make_message({ text = '/gh notifications', command = 'gh', args = 'notifications' })
            store_token(message.from.id)
            mock_get('https://api.github.com/notifications?per_page=5&page=1', notifs)
            github_plugin.on_message(env.api, message, ctx)
            local call = env.api.get_call('send_message')
            assert.is_not_nil(call.args[3].reply_markup)
        end)
    end)

    -- ================================================================
    -- 13. Cron polling
    -- ================================================================
    describe('cron', function()
        it('should skip when no pending devices', function()
            github_plugin.cron(env.api, ctx)
            assert.are.equal(0, #http_calls)
        end)

        it('should skip when config is missing', function()
            test_config.GITHUB_CLIENT_ID = nil
            package.loaded['src.plugins.utility.github'] = nil
            github_plugin = require('src.plugins.utility.github')
            store_pending_device(111111)
            github_plugin.cron(env.api, ctx)
            assert.are.equal(0, #http_calls)
        end)

        it('should continue on authorization_pending', function()
            store_pending_device(111111, { last_poll = '0' })
            mock_post('https://github.com/login/oauth/access_token', {
                error = 'authorization_pending',
                error_description = 'The authorization request is still pending.',
            })
            github_plugin.cron(env.api, ctx)
            -- Should still be pending
            assert.are.equal(1, env.redis.sismember('github:pending_devices', '111111'))
            -- Device key should still exist
            assert.is_truthy(env.redis.hget('github:device:111111', 'device_code'))
        end)

        it('should store token and notify on access_token', function()
            store_pending_device(111111, { last_poll = '0', chat_id = '111111' })
            mock_post('https://github.com/login/oauth/access_token', SAMPLE_ACCESS_TOKEN)
            github_plugin.cron(env.api, ctx)
            -- Token should be stored
            assert.are.equal(SAMPLE_ACCESS_TOKEN.access_token, env.redis.get('github:token:111111'))
            -- Device should be cleaned up
            assert.are.equal(0, env.redis.sismember('github:pending_devices', '111111'))
            -- User should be notified
            test_helper.assert_sent_message_matches(env.api, 'connected successfully')
        end)

        it('should increase interval on slow_down', function()
            store_pending_device(111111, { last_poll = '0', interval = '5' })
            mock_post('https://github.com/login/oauth/access_token', {
                error = 'slow_down',
                error_description = 'Too many requests.',
            })
            github_plugin.cron(env.api, ctx)
            assert.are.equal('10', env.redis.hget('github:device:111111', 'interval'))
        end)

        it('should clean up on expired_token', function()
            store_pending_device(111111, { last_poll = '0', chat_id = '111111' })
            mock_post('https://github.com/login/oauth/access_token', {
                error = 'expired_token',
                error_description = 'The device code has expired.',
            })
            github_plugin.cron(env.api, ctx)
            assert.are.equal(0, env.redis.sismember('github:pending_devices', '111111'))
            test_helper.assert_sent_message_matches(env.api, 'expired')
        end)

        it('should clean up on access_denied', function()
            store_pending_device(111111, { last_poll = '0', chat_id = '111111' })
            mock_post('https://github.com/login/oauth/access_token', {
                error = 'access_denied',
                error_description = 'The user denied the request.',
            })
            github_plugin.cron(env.api, ctx)
            assert.are.equal(0, env.redis.sismember('github:pending_devices', '111111'))
            test_helper.assert_sent_message_matches(env.api, 'denied')
        end)

        it('should respect interval between polls', function()
            local now = os.time()
            store_pending_device(111111, { last_poll = tostring(now), interval = '60' })
            github_plugin.cron(env.api, ctx)
            -- Should not have made any HTTP calls since last_poll is now and interval is 60s
            assert.are.equal(0, #http_calls)
        end)

        it('should remove expired flows', function()
            store_pending_device(111111, {
                last_poll = '0',
                expires_at = tostring(os.time() - 100), -- already expired
                chat_id = '111111',
            })
            github_plugin.cron(env.api, ctx)
            assert.are.equal(0, env.redis.sismember('github:pending_devices', '111111'))
            test_helper.assert_sent_message_matches(env.api, 'expired')
        end)
    end)

    -- ================================================================
    -- 14. Callback queries
    -- ================================================================
    describe('callback queries', function()
        it('should handle repos pagination', function()
            store_token(111111)
            mock_get('https://api.github.com/user/repos?per_page=5&sort=updated&page=2', SAMPLE_REPOS)
            local cb = test_helper.make_callback_query({ data = 'r:_:2' })
            github_plugin.on_callback_query(env.api, cb, cb.message, ctx)
            test_helper.assert_api_called(env.api, 'edit_message_text')
            test_helper.assert_api_called(env.api, 'answer_callback_query')
        end)

        it('should handle issues pagination', function()
            mock_get('https://api.github.com/repos/octocat/Hello-World/issues?per_page=5&state=open&page=2', SAMPLE_ISSUES)
            local cb = test_helper.make_callback_query({ data = 'i:octocat/Hello-World:2' })
            github_plugin.on_callback_query(env.api, cb, cb.message, ctx)
            test_helper.assert_api_called(env.api, 'edit_message_text')
        end)

        it('should handle noop', function()
            local cb = test_helper.make_callback_query({ data = 'noop' })
            github_plugin.on_callback_query(env.api, cb, cb.message, ctx)
            test_helper.assert_api_called(env.api, 'answer_callback_query')
            test_helper.assert_api_not_called(env.api, 'edit_message_text')
        end)

        it('should always answer callback query', function()
            mock_get('https://api.github.com/user/starred?per_page=5&page=2', SAMPLE_STARRED)
            store_token(111111)
            local cb = test_helper.make_callback_query({ data = 's:2' })
            github_plugin.on_callback_query(env.api, cb, cb.message, ctx)
            test_helper.assert_api_called(env.api, 'answer_callback_query')
        end)

        it('should edit message with updated content', function()
            mock_get('https://api.github.com/notifications?per_page=5&page=2', SAMPLE_NOTIFICATIONS)
            store_token(111111)
            local cb = test_helper.make_callback_query({ data = 'n:2' })
            github_plugin.on_callback_query(env.api, cb, cb.message, ctx)
            local call = env.api.get_call('edit_message_text')
            assert.is_not_nil(call)
            assert.is_truthy(call.args[3]:match('Issue title'))
            assert.are.equal('html', call.args[4].parse_mode)
        end)
    end)

    -- ================================================================
    -- 15. Error handling
    -- ================================================================
    describe('error handling', function()
        it('should clear token on 401 response', function()
            message = test_helper.make_message({ text = '/gh repos', command = 'gh', args = 'repos' })
            store_token(message.from.id)
            mock_get_raw('https://api.github.com/user/repos?per_page=5&sort=updated&page=1', '', 401)
            github_plugin.on_message(env.api, message, ctx)
            assert.is_nil(env.redis.get('github:token:' .. message.from.id))
            test_helper.assert_sent_message_matches(env.api, 'expired')
        end)

        it('should show rate limit message on 403', function()
            message = test_helper.make_message({ text = '/gh repos', command = 'gh', args = 'repos' })
            store_token(message.from.id)
            mock_get_raw('https://api.github.com/user/repos?per_page=5&sort=updated&page=1', '', 403)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'rate limit')
        end)

        it('should show not found on 404', function()
            message = test_helper.make_message({ text = '/gh octocat/nonexistent', command = 'gh', args = 'octocat/nonexistent' })
            mock_get_raw('https://api.github.com/repos/octocat/nonexistent', '', 404)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Not found')
        end)

        it('should show generic error on network failure', function()
            message = test_helper.make_message({ text = '/gh repos', command = 'gh', args = 'repos' })
            store_token(message.from.id)
            mock_get_raw('https://api.github.com/user/repos?per_page=5&sort=updated&page=1', '', 0)
            github_plugin.on_message(env.api, message, ctx)
            test_helper.assert_sent_message_matches(env.api, 'Failed to reach')
        end)
    end)
end)
