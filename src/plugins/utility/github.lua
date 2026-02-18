--[[
    mattata v2.0 - GitHub Plugin
    Full GitHub integration with OAuth Device Flow authentication,
    multiple subcommands, pagination, and cron-based auth polling.
]]

local plugin = {}
plugin.name = 'github'
plugin.category = 'utility'
plugin.description = 'GitHub integration with OAuth authentication'
plugin.commands = { 'github', 'gh' }
plugin.help = table.concat({
    '/gh login - Connect your GitHub account (PM only)',
    '/gh logout - Disconnect your GitHub account (PM only)',
    '/gh me - View your GitHub profile',
    '/gh repos [user] - List repositories',
    '/gh &lt;owner/repo&gt; - View repository info',
    '/gh issues &lt;owner/repo&gt; - List open issues',
    '/gh issue &lt;owner/repo#123&gt; - View specific issue',
    '/gh starred - List your starred repos',
    '/gh star &lt;owner/repo&gt; - Star a repository',
    '/gh unstar &lt;owner/repo&gt; - Unstar a repository',
    '/gh notifications - View unread notifications',
}, '\n')

local http = require('src.core.http')
local config = require('src.core.config')
local json = require('dkjson')
local tools = require('telegram-bot-lua.tools')
local logger = require('src.core.logger')

-- Constants
local GITHUB_API = 'https://api.github.com'
local DEVICE_CODE_URL = 'https://github.com/login/device/code'
local ACCESS_TOKEN_URL = 'https://github.com/login/oauth/access_token'
local PER_PAGE = 5
local TOKEN_TTL = 31536000 -- 1 year
local DEVICE_TTL = 900 -- 15 minutes
local CRON_MAX_POLLS = 10

-- Redis key helpers
local function token_key(user_id)
    return 'github:token:' .. tostring(user_id)
end

local function device_key(user_id)
    return 'github:device:' .. tostring(user_id)
end

local PENDING_KEY = 'github:pending_devices'

-- Generic GitHub API caller
local function gh_api(path, token, method, body)
    local url = path:match('^https?://') and path or (GITHUB_API .. path)
    local headers = { ['Accept'] = 'application/vnd.github.v3+json' }
    if token then
        headers['Authorization'] = 'Bearer ' .. token
    end
    method = method or 'GET'
    if method == 'GET' then
        local resp, code = http.get(url, headers)
        if code ~= 200 then return nil, code end
        if not resp or resp == '' then return nil, code end
        return json.decode(resp), code
    elseif method == 'POST' then
        local req_body = body or ''
        if type(body) == 'table' then req_body = json.encode(body) end
        local resp, code = http.post(url, req_body, 'application/json', headers)
        if code ~= 200 and code ~= 201 then return nil, code end
        if not resp or resp == '' then return nil, code end
        return json.decode(resp), code
    else
        -- PUT, DELETE (no body needed for our use cases)
        headers['Content-Length'] = '0'
        local resp, code = http.request({
            url = url,
            method = method,
            headers = headers,
        })
        if code == 204 then return true, code end
        if code ~= 200 then return nil, code end
        if not resp or resp == '' then return true, code end
        return json.decode(resp), code
    end
end

-- Retrieve stored token
local function get_token(redis, user_id)
    return redis.get(token_key(user_id))
end

-- Get token or send error message
local function require_token(api, redis, message)
    local token = get_token(redis, message.from.id)
    if not token then
        api.send_message(message.chat.id, 'You need to connect your GitHub account first. Use /gh login in a private chat.')
        return nil
    end
    return token
end

-- Authed API call with error handling
local function gh_api_authed(api, redis, message, path, method, body)
    local token = get_token(redis, message.from.id)
    local data, code = gh_api(path, token, method, body)
    if code == 401 then
        if token then redis.del(token_key(message.from.id)) end
        api.send_message(message.chat.id, 'Your GitHub token has expired. Please /gh login again.')
        return nil, code
    elseif code == 403 then
        api.send_message(message.chat.id, 'GitHub API rate limit exceeded or insufficient permissions.')
        return nil, code
    elseif code == 404 then
        api.send_message(message.chat.id, 'Not found on GitHub.')
        return nil, code
    elseif not data then
        api.send_message(message.chat.id, 'Failed to reach the GitHub API. Please try again later.')
        return nil, code or 0
    end
    return data, code
end

-- Format full repo info as HTML lines
local function format_repo(data)
    local lines = {
        string.format('<b>%s</b>', tools.escape_html(data.full_name or '')),
    }
    if data.description and data.description ~= '' then
        table.insert(lines, (tools.escape_html(data.description)))
    end
    table.insert(lines, '')
    if data.private then
        table.insert(lines, 'Visibility: <code>private</code>')
    end
    if data.language then
        table.insert(lines, 'Language: <code>' .. tools.escape_html(data.language) .. '</code>')
    end
    table.insert(lines, string.format('Stars: <code>%s</code>', data.stargazers_count or 0))
    table.insert(lines, string.format('Forks: <code>%s</code>', data.forks_count or 0))
    table.insert(lines, string.format('Open issues: <code>%s</code>', data.open_issues_count or 0))
    if data.license and data.license.spdx_id then
        table.insert(lines, 'License: <code>' .. tools.escape_html(data.license.spdx_id) .. '</code>')
    end
    if data.created_at then
        table.insert(lines, 'Created: <code>' .. data.created_at:sub(1, 10) .. '</code>')
    end
    return lines
end

-- Build pagination keyboard with prev/next buttons
local function pagination_keyboard(api, prefix, page, has_more)
    if page == 1 and not has_more then return nil end
    local keyboard = api.inline_keyboard()
    local row = api.row()
    if page > 1 then
        row:callback_data_button('< Prev', string.format('github:%s:%d', prefix, page - 1))
    end
    row:callback_data_button('Page ' .. page, 'github:noop')
    if has_more then
        row:callback_data_button('Next >', string.format('github:%s:%d', prefix, page + 1))
    end
    keyboard:row(row)
    return keyboard
end

-- Format repos list
local function format_repos_list(repos, page, user)
    local title = user and user ~= '_'
        and string.format('<b>%s\'s Repositories</b>', tools.escape_html(user))
        or '<b>Your Repositories</b>'
    local lines = { title .. ' (Page ' .. page .. ')' }
    if #repos == 0 then
        table.insert(lines, '\nNo repositories found.')
        return table.concat(lines, '\n')
    end
    for _, r in ipairs(repos) do
        table.insert(lines, '')
        local name = '<b>' .. tools.escape_html(r.full_name or '') .. '</b>'
        if r.private then name = name .. ' [private]' end
        table.insert(lines, name)
        if r.description and r.description ~= '' then
            local desc = r.description
            if #desc > 80 then desc = desc:sub(1, 77) .. '...' end
            table.insert(lines, (tools.escape_html(desc)))
        end
        local meta = {}
        if r.language then table.insert(meta, r.language) end
        table.insert(meta, tostring(r.stargazers_count or 0) .. ' stars')
        table.insert(lines, table.concat(meta, ' | '))
    end
    return table.concat(lines, '\n')
end

-- Format issues list
local function format_issues_list(issues, page, owner_repo)
    local lines = { string.format('<b>Open Issues — %s</b> (Page %d)', tools.escape_html(owner_repo), page) }
    if #issues == 0 then
        table.insert(lines, '\nNo open issues found.')
        return table.concat(lines, '\n')
    end
    for _, issue in ipairs(issues) do
        table.insert(lines, '')
        local labels_str = ''
        if issue.labels and #issue.labels > 0 then
            local names = {}
            for _, l in ipairs(issue.labels) do table.insert(names, l.name) end
            labels_str = ' [' .. table.concat(names, ', ') .. ']'
        end
        table.insert(lines, string.format(
            '#%d <b>%s</b>%s',
            issue.number,
            tools.escape_html(issue.title or ''),
            tools.escape_html(labels_str)
        ))
        table.insert(lines, string.format('by %s — %s',
            tools.escape_html(issue.user and issue.user.login or 'unknown'),
            (issue.created_at or ''):sub(1, 10)
        ))
    end
    return table.concat(lines, '\n')
end

-- Format starred repos list
local function format_starred_list(repos, page)
    local lines = { '<b>Starred Repositories</b> (Page ' .. page .. ')' }
    if #repos == 0 then
        table.insert(lines, '\nNo starred repositories.')
        return table.concat(lines, '\n')
    end
    for _, r in ipairs(repos) do
        table.insert(lines, '')
        table.insert(lines, '<b>' .. tools.escape_html(r.full_name or '') .. '</b>')
        if r.description and r.description ~= '' then
            local desc = r.description
            if #desc > 80 then desc = desc:sub(1, 77) .. '...' end
            table.insert(lines, (tools.escape_html(desc)))
        end
        table.insert(lines, tostring(r.stargazers_count or 0) .. ' stars')
    end
    return table.concat(lines, '\n')
end

-- Format notifications list
local function format_notifications_list(notifications, page)
    local lines = { '<b>Unread Notifications</b> (Page ' .. page .. ')' }
    if #notifications == 0 then
        table.insert(lines, '\nNo unread notifications.')
        return table.concat(lines, '\n')
    end
    for _, n in ipairs(notifications) do
        table.insert(lines, '')
        table.insert(lines, string.format(
            '<b>[%s]</b> %s',
            tools.escape_html(n.subject and n.subject.type or 'Unknown'),
            tools.escape_html(n.subject and n.subject.title or '')
        ))
        table.insert(lines, string.format(
            '%s — %s',
            tools.escape_html(n.repository and n.repository.full_name or ''),
            tools.escape_html(n.reason or '')
        ))
    end
    return table.concat(lines, '\n')
end

-- Parse owner/repo from argument
local function parse_owner_repo(arg)
    if not arg then return nil end
    local owner, repo = arg:match('^([%w%.%-_]+)/([%w%.%-_]+)$')
    if not owner then
        owner, repo = arg:match('github%.com/([%w%.%-_]+)/([%w%.%-_]+)')
    end
    if owner and repo then
        return owner .. '/' .. repo
    end
    return nil
end

-- Truncate slug for callback data (64 byte limit)
local function cb_slug(slug)
    if #slug > 48 then return slug:sub(1, 48) end
    return slug
end

-- Handler dispatch table
local handlers = {}

handlers.login = function(api, message, ctx)
    if message.chat.type ~= 'private' then
        return api.send_message(message.chat.id, 'Please use /gh login in a private chat for security.')
    end
    local redis = ctx.redis
    local user_id = message.from.id
    if get_token(redis, user_id) then
        return api.send_message(message.chat.id, 'You are already connected to GitHub. Use /gh logout first to reconnect.')
    end
    if redis.sismember(PENDING_KEY, tostring(user_id)) == 1 then
        return api.send_message(message.chat.id, 'You already have a pending login. Please complete the current flow or wait for it to expire.')
    end
    local client_id = config.get('GITHUB_CLIENT_ID')
    if not client_id or client_id == '' then
        return api.send_message(message.chat.id, 'GitHub integration is not configured.')
    end
    local body = 'client_id=' .. client_id .. '&scope=repo,notifications,user'
    local resp_body, code = http.post(DEVICE_CODE_URL, body, 'application/x-www-form-urlencoded', {
        ['Accept'] = 'application/json',
    })
    if code ~= 200 or not resp_body or resp_body == '' then
        return api.send_message(message.chat.id, 'Failed to start GitHub login. Please try again later.')
    end
    local data = json.decode(resp_body)
    if not data or not data.device_code then
        return api.send_message(message.chat.id, 'Failed to start GitHub login. Please try again later.')
    end
    local now = os.time()
    local dk = device_key(user_id)
    redis.hset(dk, 'device_code', data.device_code)
    redis.hset(dk, 'user_code', data.user_code)
    redis.hset(dk, 'verification_uri', data.verification_uri)
    redis.hset(dk, 'interval', tostring(data.interval or 5))
    redis.hset(dk, 'expires_at', tostring(now + (data.expires_in or 900)))
    redis.hset(dk, 'chat_id', tostring(message.chat.id))
    redis.hset(dk, 'last_poll', '0')
    redis.expire(dk, data.expires_in or DEVICE_TTL)
    redis.sadd(PENDING_KEY, tostring(user_id))
    local text = string.format(
        '<b>GitHub Login</b>\n\n'
        .. '1. Open: %s\n'
        .. '2. Enter code: <code>%s</code>\n\n'
        .. 'The code expires in %d minutes.',
        tools.escape_html(data.verification_uri),
        tools.escape_html(data.user_code),
        math.floor((data.expires_in or 900) / 60)
    )
    return api.send_message(message.chat.id, text, {
        parse_mode = 'html',
        link_preview_options = { is_disabled = true },
    })
end

handlers.logout = function(api, message, ctx)
    if message.chat.type ~= 'private' then
        return api.send_message(message.chat.id, 'Please use /gh logout in a private chat.')
    end
    local redis = ctx.redis
    local user_id = message.from.id
    local token = get_token(redis, user_id)
    if not token then
        return api.send_message(message.chat.id, 'You are not connected to GitHub.')
    end
    local client_id = config.get('GITHUB_CLIENT_ID')
    local client_secret = config.get('GITHUB_CLIENT_SECRET')
    if client_id and client_secret and client_id ~= '' and client_secret ~= '' then
        pcall(function()
            local revoke_body = json.encode({ access_token = token })
            http.request({
                url = GITHUB_API .. '/applications/' .. client_id .. '/token',
                method = 'DELETE',
                headers = {
                    ['Accept'] = 'application/vnd.github.v3+json',
                    ['Content-Type'] = 'application/json',
                    ['Content-Length'] = tostring(#revoke_body),
                },
            })
        end)
    end
    redis.del(token_key(user_id))
    return api.send_message(message.chat.id, 'Your GitHub account has been disconnected.')
end

handlers.me = function(api, message, ctx)
    local redis = ctx.redis
    if not require_token(api, redis, message) then return end
    local data = gh_api_authed(api, redis, message, '/user')
    if not data then return end
    local lines = {
        string.format('<b>%s</b>', tools.escape_html(data.login or '')),
    }
    if data.name and data.name ~= '' then
        table.insert(lines, (tools.escape_html(data.name)))
    end
    if data.bio and data.bio ~= '' then
        table.insert(lines, '<i>' .. tools.escape_html(data.bio) .. '</i>')
    end
    table.insert(lines, '')
    if data.company and data.company ~= '' then
        table.insert(lines, 'Company: ' .. tools.escape_html(data.company))
    end
    if data.location and data.location ~= '' then
        table.insert(lines, 'Location: ' .. tools.escape_html(data.location))
    end
    table.insert(lines, string.format('Public repos: <code>%d</code>', data.public_repos or 0))
    table.insert(lines, string.format('Followers: <code>%d</code>', data.followers or 0))
    table.insert(lines, string.format('Following: <code>%d</code>', data.following or 0))
    local keyboard = api.inline_keyboard():row(
        api.row():url_button('View on GitHub', data.html_url or ('https://github.com/' .. (data.login or '')))
    )
    return api.send_message(message.chat.id, table.concat(lines, '\n'), {
        parse_mode = 'html',
        link_preview_options = { is_disabled = true },
        reply_markup = keyboard,
    })
end

handlers.repos = function(api, message, ctx, arg)
    local redis = ctx.redis
    if not require_token(api, redis, message) then return end
    local path
    if arg and arg ~= '' then
        path = string.format('/users/%s/repos?per_page=%d&sort=updated&page=1', arg, PER_PAGE)
    else
        path = string.format('/user/repos?per_page=%d&sort=updated&page=1', PER_PAGE)
    end
    local data = gh_api_authed(api, redis, message, path)
    if not data then return end
    local user = arg or '_'
    local text = format_repos_list(data, 1, user)
    local has_more = #data == PER_PAGE
    local keyboard = pagination_keyboard(api, 'r:' .. cb_slug(user), 1, has_more)
    return api.send_message(message.chat.id, text, {
        parse_mode = 'html',
        link_preview_options = { is_disabled = true },
        reply_markup = keyboard,
    })
end

handlers.repo = function(api, message, ctx, arg)
    local owner_repo = parse_owner_repo(arg)
    if not owner_repo then
        return api.send_message(message.chat.id, 'Invalid repository format. Use: /gh owner/repo')
    end
    local redis = ctx.redis
    local data = gh_api_authed(api, redis, message, '/repos/' .. owner_repo)
    if not data then return end
    local lines = format_repo(data)
    local keyboard = api.inline_keyboard():row(
        api.row():url_button('View on GitHub', data.html_url or ('https://github.com/' .. owner_repo))
    )
    return api.send_message(message.chat.id, table.concat(lines, '\n'), {
        parse_mode = 'html',
        link_preview_options = { is_disabled = true },
        reply_markup = keyboard,
    })
end

handlers.issues = function(api, message, ctx, arg)
    local owner_repo = parse_owner_repo(arg)
    if not owner_repo then
        return api.send_message(message.chat.id, 'Usage: /gh issues owner/repo')
    end
    local redis = ctx.redis
    local path = string.format('/repos/%s/issues?per_page=%d&state=open&page=1', owner_repo, PER_PAGE)
    local data = gh_api_authed(api, redis, message, path)
    if not data then return end
    local text = format_issues_list(data, 1, owner_repo)
    local has_more = #data == PER_PAGE
    local keyboard = pagination_keyboard(api, 'i:' .. cb_slug(owner_repo), 1, has_more)
    return api.send_message(message.chat.id, text, {
        parse_mode = 'html',
        link_preview_options = { is_disabled = true },
        reply_markup = keyboard,
    })
end

handlers.issue = function(api, message, ctx, arg)
    if not arg then
        return api.send_message(message.chat.id, 'Usage: /gh issue owner/repo#123')
    end
    local owner_repo, number = arg:match('^([%w%.%-_]+/[%w%.%-_]+)#(%d+)$')
    if not owner_repo or not number then
        return api.send_message(message.chat.id, 'Invalid format. Use: /gh issue owner/repo#123')
    end
    local redis = ctx.redis
    local path = string.format('/repos/%s/issues/%s', owner_repo, number)
    local data = gh_api_authed(api, redis, message, path)
    if not data then return end
    local lines = {
        string.format('<b>%s#%d</b>', tools.escape_html(owner_repo), data.number),
        string.format('<b>%s</b>', tools.escape_html(data.title or '')),
    }
    table.insert(lines, '')
    table.insert(lines, 'State: <code>' .. (data.state or 'unknown') .. '</code>')
    table.insert(lines, 'Author: <code>' .. tools.escape_html(data.user and data.user.login or 'unknown') .. '</code>')
    if data.labels and #data.labels > 0 then
        local label_names = {}
        for _, l in ipairs(data.labels) do table.insert(label_names, l.name) end
        table.insert(lines, 'Labels: <code>' .. tools.escape_html(table.concat(label_names, ', ')) .. '</code>')
    end
    if data.assignees and #data.assignees > 0 then
        local names = {}
        for _, a in ipairs(data.assignees) do table.insert(names, a.login) end
        table.insert(lines, 'Assignees: <code>' .. tools.escape_html(table.concat(names, ', ')) .. '</code>')
    end
    if data.comments and data.comments > 0 then
        table.insert(lines, string.format('Comments: <code>%d</code>', data.comments))
    end
    if data.body and data.body ~= '' then
        local body_text = data.body
        if #body_text > 200 then body_text = body_text:sub(1, 197) .. '...' end
        table.insert(lines, '')
        table.insert(lines, (tools.escape_html(body_text)))
    end
    local keyboard = api.inline_keyboard():row(
        api.row():url_button('View on GitHub', data.html_url or ('https://github.com/' .. owner_repo .. '/issues/' .. number))
    )
    return api.send_message(message.chat.id, table.concat(lines, '\n'), {
        parse_mode = 'html',
        link_preview_options = { is_disabled = true },
        reply_markup = keyboard,
    })
end

handlers.starred = function(api, message, ctx)
    local redis = ctx.redis
    if not require_token(api, redis, message) then return end
    local path = string.format('/user/starred?per_page=%d&page=1', PER_PAGE)
    local data = gh_api_authed(api, redis, message, path)
    if not data then return end
    local text = format_starred_list(data, 1)
    local has_more = #data == PER_PAGE
    local keyboard = pagination_keyboard(api, 's', 1, has_more)
    return api.send_message(message.chat.id, text, {
        parse_mode = 'html',
        link_preview_options = { is_disabled = true },
        reply_markup = keyboard,
    })
end

handlers.star = function(api, message, ctx, arg)
    local redis = ctx.redis
    if not require_token(api, redis, message) then return end
    local owner_repo = parse_owner_repo(arg)
    if not owner_repo then
        return api.send_message(message.chat.id, 'Usage: /gh star owner/repo')
    end
    local data, code = gh_api_authed(api, redis, message, '/user/starred/' .. owner_repo, 'PUT')
    if not data then return end
    return api.send_message(message.chat.id,
        string.format('Starred <b>%s</b>.', tools.escape_html(owner_repo)),
        { parse_mode = 'html' }
    )
end

handlers.unstar = function(api, message, ctx, arg)
    local redis = ctx.redis
    if not require_token(api, redis, message) then return end
    local owner_repo = parse_owner_repo(arg)
    if not owner_repo then
        return api.send_message(message.chat.id, 'Usage: /gh unstar owner/repo')
    end
    local data, code = gh_api_authed(api, redis, message, '/user/starred/' .. owner_repo, 'DELETE')
    if not data then return end
    return api.send_message(message.chat.id,
        string.format('Unstarred <b>%s</b>.', tools.escape_html(owner_repo)),
        { parse_mode = 'html' }
    )
end

handlers.notifications = function(api, message, ctx)
    local redis = ctx.redis
    if not require_token(api, redis, message) then return end
    local path = string.format('/notifications?per_page=%d&page=1', PER_PAGE)
    local data = gh_api_authed(api, redis, message, path)
    if not data then return end
    local text = format_notifications_list(data, 1)
    local has_more = #data == PER_PAGE
    local keyboard = pagination_keyboard(api, 'n', 1, has_more)
    return api.send_message(message.chat.id, text, {
        parse_mode = 'html',
        link_preview_options = { is_disabled = true },
        reply_markup = keyboard,
    })
end

-- Command dispatcher
function plugin.on_message(api, message, ctx)
    local input = message.args
    if not input or input == '' then
        return api.send_message(message.chat.id, plugin.help, { parse_mode = 'html' })
    end
    local parts = {}
    for word in input:gmatch('%S+') do
        table.insert(parts, word)
    end
    local subcommand = parts[1]:lower()
    local arg = parts[2]
    if handlers[subcommand] then
        return handlers[subcommand](api, message, ctx, arg)
    end
    -- Try owner/repo format
    local owner_repo = parse_owner_repo(input)
    if owner_repo then
        return handlers.repo(api, message, ctx, input)
    end
    return api.send_message(message.chat.id, 'Unknown command. Use /gh for help.')
end

-- Callback query handler for pagination
function plugin.on_callback_query(api, callback_query, message, ctx)
    local data = callback_query.data
    if data == 'noop' then
        return api.answer_callback_query(callback_query.id)
    end
    local redis = ctx.redis
    local token = get_token(redis, callback_query.from.id)
    -- Parse callback data: type:params:page or type:page
    local cb_parts = {}
    for part in data:gmatch('[^:]+') do
        table.insert(cb_parts, part)
    end
    local cb_type = cb_parts[1]
    if cb_type == 'r' then
        -- Repos: r:user:page
        local user = cb_parts[2]
        local page = tonumber(cb_parts[3]) or 1
        local path
        if user == '_' then
            path = string.format('/user/repos?per_page=%d&sort=updated&page=%d', PER_PAGE, page)
        else
            path = string.format('/users/%s/repos?per_page=%d&sort=updated&page=%d', user, PER_PAGE, page)
        end
        local repos, code = gh_api(path, token)
        if not repos then
            return api.answer_callback_query(callback_query.id, { text = 'Failed to fetch repositories.' })
        end
        local text = format_repos_list(repos, page, user)
        local has_more = #repos == PER_PAGE
        local keyboard = pagination_keyboard(api, 'r:' .. cb_slug(user), page, has_more)
        api.answer_callback_query(callback_query.id)
        return api.edit_message_text(message.chat.id, message.message_id, text, {
            parse_mode = 'html',
            link_preview_options = { is_disabled = true },
            reply_markup = keyboard,
        })
    elseif cb_type == 'i' then
        -- Issues: i:owner/repo:page (owner/repo may contain /)
        local page = tonumber(cb_parts[#cb_parts]) or 1
        -- Reconstruct owner/repo from middle parts
        local owner_repo = table.concat(cb_parts, ':', 2, #cb_parts - 1)
        local path = string.format('/repos/%s/issues?per_page=%d&state=open&page=%d', owner_repo, PER_PAGE, page)
        local issues, code = gh_api(path, token)
        if not issues then
            return api.answer_callback_query(callback_query.id, { text = 'Failed to fetch issues.' })
        end
        local text = format_issues_list(issues, page, owner_repo)
        local has_more = #issues == PER_PAGE
        local keyboard = pagination_keyboard(api, 'i:' .. cb_slug(owner_repo), page, has_more)
        api.answer_callback_query(callback_query.id)
        return api.edit_message_text(message.chat.id, message.message_id, text, {
            parse_mode = 'html',
            link_preview_options = { is_disabled = true },
            reply_markup = keyboard,
        })
    elseif cb_type == 's' then
        -- Starred: s:page
        local page = tonumber(cb_parts[2]) or 1
        local path = string.format('/user/starred?per_page=%d&page=%d', PER_PAGE, page)
        local repos, code = gh_api(path, token)
        if not repos then
            return api.answer_callback_query(callback_query.id, { text = 'Failed to fetch starred repos.' })
        end
        local text = format_starred_list(repos, page)
        local has_more = #repos == PER_PAGE
        local keyboard = pagination_keyboard(api, 's', page, has_more)
        api.answer_callback_query(callback_query.id)
        return api.edit_message_text(message.chat.id, message.message_id, text, {
            parse_mode = 'html',
            link_preview_options = { is_disabled = true },
            reply_markup = keyboard,
        })
    elseif cb_type == 'n' then
        -- Notifications: n:page
        local page = tonumber(cb_parts[2]) or 1
        local path = string.format('/notifications?per_page=%d&page=%d', PER_PAGE, page)
        local notifications, code = gh_api(path, token)
        if not notifications then
            return api.answer_callback_query(callback_query.id, { text = 'Failed to fetch notifications.' })
        end
        local text = format_notifications_list(notifications, page)
        local has_more = #notifications == PER_PAGE
        local keyboard = pagination_keyboard(api, 'n', page, has_more)
        api.answer_callback_query(callback_query.id)
        return api.edit_message_text(message.chat.id, message.message_id, text, {
            parse_mode = 'html',
            link_preview_options = { is_disabled = true },
            reply_markup = keyboard,
        })
    end
    return api.answer_callback_query(callback_query.id)
end

-- Cron: poll GitHub for pending device flows
function plugin.cron(api, ctx)
    local redis = ctx.redis
    local client_id = config.get('GITHUB_CLIENT_ID')
    if not client_id or client_id == '' then return end
    local pending = redis.smembers(PENDING_KEY)
    if not pending or #pending == 0 then return end
    local now = os.time()
    local polls = 0
    for _, uid_str in ipairs(pending) do
        if polls >= CRON_MAX_POLLS then break end
        local device = redis.hgetall(device_key(uid_str))
        if not device or not device.device_code then
            redis.srem(PENDING_KEY, uid_str)
        else
            local expires_at = tonumber(device.expires_at) or 0
            if now > expires_at then
                redis.del(device_key(uid_str))
                redis.srem(PENDING_KEY, uid_str)
                if device.chat_id then
                    pcall(function()
                        api.send_message(tonumber(device.chat_id), 'Your GitHub login has expired. Please try /gh login again.')
                    end)
                end
            else
                local interval = tonumber(device.interval) or 5
                local last_poll = tonumber(device.last_poll) or 0
                if now - last_poll >= interval then
                    polls = polls + 1
                    redis.hset(device_key(uid_str), 'last_poll', tostring(now))
                    local body = string.format(
                        'client_id=%s&device_code=%s&grant_type=urn:ietf:params:oauth:grant-type:device_code',
                        client_id, device.device_code
                    )
                    local resp_body, code = http.post(ACCESS_TOKEN_URL, body, 'application/x-www-form-urlencoded', {
                        ['Accept'] = 'application/json',
                    })
                    if resp_body and resp_body ~= '' then
                        local resp_data = json.decode(resp_body)
                        if resp_data then
                            if resp_data.access_token then
                                redis.setex(token_key(uid_str), TOKEN_TTL, resp_data.access_token)
                                redis.del(device_key(uid_str))
                                redis.srem(PENDING_KEY, uid_str)
                                if device.chat_id then
                                    pcall(function()
                                        api.send_message(tonumber(device.chat_id), 'GitHub account connected successfully! Use /gh me to see your profile.')
                                    end)
                                end
                            elseif resp_data.error == 'slow_down' then
                                local new_interval = interval + 5
                                redis.hset(device_key(uid_str), 'interval', tostring(new_interval))
                            elseif resp_data.error == 'access_denied' then
                                redis.del(device_key(uid_str))
                                redis.srem(PENDING_KEY, uid_str)
                                if device.chat_id then
                                    pcall(function()
                                        api.send_message(tonumber(device.chat_id), 'GitHub login was denied.')
                                    end)
                                end
                            elseif resp_data.error == 'expired_token' then
                                redis.del(device_key(uid_str))
                                redis.srem(PENDING_KEY, uid_str)
                                if device.chat_id then
                                    pcall(function()
                                        api.send_message(tonumber(device.chat_id), 'Your GitHub login code has expired. Please try /gh login again.')
                                    end)
                                end
                            end
                            -- authorization_pending: do nothing, wait for next poll
                        end
                    end
                end
            end
        end
    end
end

return plugin
