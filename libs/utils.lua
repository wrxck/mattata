local utils = {}
local redis = require('libs.redis')
local configuration = require('configuration')

local mattata = {}
local api = {}
local tools = {}

function utils:init()
    mattata = self
    api = self.api
    tools = self.tools
    return utils
end

function utils.is_trusted_user(chat_id, user_id)
    if redis:sismember('administration:' .. chat_id .. ':trusted', user_id) then
        return true
    end
    return false
end

function utils.get_user_count()
    return #redis:keys('user:*:info')
end

function utils.get_group_count()
    return #redis:keys('chat:*:info')
end

function utils.get_user_language(user_id)
    return redis:hget('chat:' .. user_id .. ':settings', 'language') or 'en_gb'
end

function utils.get_log_chat(chat_id)
    local chat = redis:hget('chat:' .. chat_id .. ':settings', 'log chat')
    if chat ~= false and chat ~= nil then
        return chat
    end
    return configuration.log_channel or false
end

function utils.set_captcha(chat_id, user_id, text, id, timeout)
    local hash = string.format('chat:%s:captcha:%s', tostring(chat_id), tostring(user_id))
    redis:hset(hash, 'id', id)
    redis:hset(hash, 'text', text)
    redis:set('captcha:' .. chat_id .. ':' .. user_id, true)
    redis:expire('captcha:' .. chat_id .. ':' .. user_id, timeout)
    return true
end

function utils.get_captcha_id(chat_id, user_id)
    return redis:hget('chat:' .. chat_id .. ':captcha:' .. user_id, 'id') or false
end

function utils.get_captcha_text(chat_id, user_id)
    return redis:hget('chat:' .. chat_id .. ':captcha:' .. user_id, 'text') or false
end

function utils.delete_redis_hash(hash, field)
    return redis:hdel(hash, field)
end

function utils.wipe_redis_captcha(chat_id, user_id)
    local hash = string.format('chat:%s:captcha:%s', tostring(chat_id), tostring(user_id))
    redis:hdel(hash, 'id')
    redis:hdel(hash, 'text')
    return true
end

function utils.get_missing_languages(delimiter)
    local missing_languages = redis:smembers('mattata:missing_languages')
    if not missing_languages then
        return false
    end
    local output = {}
    for _, v in pairs(missing_languages) do
        table.insert(output, v)
    end
    delimiter = delimiter or ', '
    return table.concat(output, delimiter)
end

function utils.purge_user(user)
    if type(user) ~= 'table' then
        return false
    end
    user = user.from or user
    redis:hdel('user:' .. user.id .. ':info', 'id')
    if user.username or redis:hget('user:' .. user.id .. ':info', 'username') then
        redis:hdel('user:' .. user.id .. ':info', 'username')
        local all = redis:smembers('user:' .. user.id .. ':usernames')
        for _, v in pairs(all) do
            redis:srem('user:' .. user.id .. ':usernames', v)
        end
        redis:del('username:' .. user.id)
    end
    redis:hdel('user:' .. user.id .. ':info', 'first_name')
    if user.name or redis:hget('user:' .. user.id .. ':info', 'name') then
        redis:hdel('user:' .. user.id .. ':info', 'name')
    end
    if user.last_name or redis:hget('user:' .. user.id .. ':info', 'last_name') then
        redis:hdel('user:' .. user.id .. ':info', 'last_name')
    end
    if user.language_code or redis:hget('user:' .. user.id .. ':info', 'language_code') then
        redis:hdel('user:' .. user.id .. ':info', 'language_code')
    end
    return true
end

function utils.get_list(name)
    name = tostring(name)
    local length = redis:llen(name)
    return redis:lrange(name, 0, tonumber(length) - 1)
end

function utils.get_inline_help(input, offset)
    offset = offset and tonumber(offset) or 0
    local inline_help = {}
    local count = offset + 1
    local plugin_list = mattata.plugin_list
    for _, plugin in pairs(mattata.administrative_plugin_list) do
        if not tools.table_contains(plugin_list, plugin) then
            table.insert(plugin_list, plugin)
        end
    end
    table.sort(plugin_list)
    for k, v in pairs(plugin_list) do
        -- The bot API only accepts a maximum of 50 results, hence we need the offset.
        if k > offset and k < offset + 50 then
            v = v:gsub('\n', ' ')
            if v:match('^/.- %- .-$') and v:lower():match(input) then
                table.insert(inline_help,
                {
                    ['type'] = 'article',
                    ['id'] = tostring(count),
                    ['title'] = v:match('^(/.-) %- .-$'),
                    ['description'] = v:match('^/.- %- (.-)$'),
                    ['input_message_content'] = {
                        ['message_text'] = utf8.char(8226) .. ' ' .. v:match('^(/.-) %- .-$') .. ' - ' .. v:match('^/.- %- (.-)$')
                    }
                })
                count = count + 1
            end
        end
    end
    return inline_help
end

function utils.string_to_time(str, is_temp_ban)
    if not str then
        return false
    end
    str = tostring(str):gsub('%s', '')
    local base_date = {
        ['year'] = 1970,
        ['month'] = 1,
        ['day'] = 1,
        ['hour'] = 0,
        ['min'] = 0,
        ['sec'] = 0
    }
    local units = {
        ['y'] = 'year',
        ['year'] = 'year',
        ['years'] = 'year',
        ['mo'] = 'month',
        ['month'] = 'month',
        ['months'] = 'month',
        ['w'] = '7day',
        ['week'] = '7day',
        ['weeks'] = '7day',
        ['d'] = 'day',
        ['day'] = 'day',
        ['days'] = 'day',
        ['h'] = 'hour',
        ['hour'] = 'hour',
        ['hours'] = 'hour',
        ['m'] = 'min',
        ['min'] = 'min',
        ['mins'] = 'min',
        ['minute'] = 'min',
        ['minutes'] = 'min',
        ['s'] = 'sec',
        ['sec'] = 'sec',
        ['secs'] = 'sec',
        ['second'] = 'sec',
        ['seconds'] = 'sec'
    }
    for number, unit in str:gmatch('(%d+)(%a+)') do
        local amount, field = units[unit]:match('^(%d*)(%a+)$')
        base_date[field] = base_date[field] + tonumber(number) * (tonumber(amount) or 1)
    end
    local final_length = os.time(base_date)
    if is_temp_ban and final_length <= 59 then
        return false
    end
    return final_length
end

function utils.get_user_setting(chat_id, user_id, setting)
    if not chat_id or not user_id or not setting then
        return false
    elseif not redis:hexists('user:' .. user_id .. ':' .. chat_id .. ':settings', tostring(setting)) then
        return false
    end
    return true
end

function utils.is_group(message)
    if not message or not message.chat or not message.chat.type or message.chat.type == 'private' then
        return false
    end
    return true
end

function utils.input(s)
    local mentioned_user = false
    if not s then
        return false
    elseif type(s) == 'table' then
        if s.entities and #s.entities >= 2 and s.entities[2].type == 'text_mention' then
            mentioned_user = tostring(s.entities[2].user.id)
        end
        s = s.text
    end
    if s:lower():match('^mattata search %a+ for .-$') then
        return s:lower():match('^mattata search %a+ for (.-)$')
    elseif not s:lower():match('^[%%/%%!%%$%%^%%?%%&%%%%]') then
        return s
    end
    local input = s:find(' ')
    if not input then
        return false
    end
    s = s:sub(input + 1)
    input = s:find(' ')
    if mentioned_user then
        s = input and mentioned_user .. ' ' .. s:sub(input + 1) or mentioned_user
    end
    return s
end

function utils.get_input(message, has_reason)
    local input = utils.input(message)
    if message.reply then
        if not message.reply.from or message.reply.forward_from then
            return false
        elseif has_reason and input then
            return message.reply.from.id, input
        end
        return message.reply.from.id
    elseif not input then
        return false
    elseif has_reason and input:find(' ') then
        return input:match('^(.-) '), input:match(' (.-)$')
    end
    return input
end

function utils.get_chat_id(chat)
    if not chat then
        return false
    end
    local success = api.get_chat(chat)
    if not success or not success.result then
        return false
    end
    return success.result.id
end

function utils.get_setting(chat_id, setting)
    if not chat_id or not setting then
        return false
    end
    return redis:hget('chat:' .. chat_id .. ':settings', tostring(setting))
end

function utils.get_value(chat_id, value)
    if not chat_id or not value then
        return false
    end
    return redis:hget('chat:' .. chat_id .. ':info', tostring(value))
end

function utils.set_value(chat_id, key, value)
    if not chat_id or not key or not value then
        return false
    end
    return redis:hset('chat:' .. chat_id .. ':info', tostring(key), tostring(value))
end

function utils.log_error(error_message)
    error_message = tostring(error_message):gsub('%%', '%%%%')
    local output = string.format('%s[31m[Error] %s%s[0m', string.char(27), error_message, string.char(27))
    print(output)
end

function utils.set_command_action(chat_id, message_id, command)
    local hash = string.format('action:%s:%s', chat_id, message_id)
    return redis:set(hash, command)
end

function utils.increase_administrative_action(chat_id, user_id, action, increase_by)
    if not increase_by or tonumber(increase_by) == nil then
        increase_by = 1
    end
    local hash = string.format('chat:%s:%s', chat_id, user_id)
    return redis:hincrby(hash, action, increase_by)
end

function utils.is_allowlisted_link(link, chat_id)
    if link == 'username' or link == 'isiswatch' or link == 'mattata' or link == 'telegram' then
        return true
    elseif chat_id and redis:get('allowlisted_links:' .. chat_id .. ':' .. link:lower()) then
        return true
    end
    return false
end

function utils.is_valid(message, offset) -- Performs basic checks on the message object to see if it's fit
-- for its purpose. If it's valid, this function will return `true` - otherwise it will return `false`.
    if not message then -- If the `message` object is nil, then we'll ignore it.
        return false, 'No `message` object exists!'
    elseif message.date < os.time() - (offset or 10) then -- We don't want to process old messages, so anything
    -- older than the current system time (giving it a leeway of 10 seconds, unless otherwise specified).
        return false, 'This `message` object is too old!'
    elseif not message.from then -- If the `message.from` object doesn't exist, this will likely
    -- break some more code further down the line!
        return false, 'No `message.from` object exists!'
    end
    return true
end

function utils.get_chat_members(chat_id)
    return redis:smembers('chat:' .. chat_id .. ':users')
end

function utils.is_privacy_enabled(user_id)
    return redis:exists('user:' .. user_id .. ':opt_out')
end

function utils.uses_administration(chat_id)
    return utils.get_setting(chat_id, 'use administration')
end

function utils.is_plugin_allowed(plugin, is_blocklisted)
    if not is_blocklisted then
        return true
    end
    for _, p in pairs(configuration.blocklist_plugin_exceptions) do
        if p == plugin then
            return true
        end
    end
    return false
end

function utils.command_action(chat_id, message_id)
    if not chat_id or not message_id then
        return false
    end
    return string.format('action:%s:%s', chat_id, message_id)
end

function utils.is_fed_admin(fed_id, user_id)
    if not fed_id or not user_id then
        return false
    end
    return redis:sismember('fedadmins:' .. fed_id, user_id)
end

function utils.is_fed_creator(fed_id, user_id)
    if not fed_id or not user_id then
        return false
    end
    local creator = redis:hget('fed:' .. fed_id, 'creator')
    return tonumber(user_id) == tonumber(creator) and true or false
end

function utils.is_user_fedbanned(chat_id, user_id)
    if not chat_id or not user_id then
        return false
    end
    local feds = redis:smembers('chat:' .. chat_id .. ':feds')
    if #feds == 0 then
        return false
    end
    for _, fed in pairs(feds) do
        if redis:sismember('fedbans:' .. fed, user_id) then
            return true
        end
    end
    return false
end

function utils.has_fed(user_id, fed_id)
    if not user_id then
        return false
    end
    local feds = redis:smembers('feds:' .. user_id)
    if #feds > 0 then
        if fed_id then
            for _, fed in pairs(feds) do
                if fed_id == fed then
                    return true, fed
                end
            end
            return false
        end
        return true, feds[1], true
    end
    return false
end

function utils.fed_ban_chat_member(chat_id, user_id, fed_list)
    if not chat_id or not user_id then
        return false
    end
    fed_list = type(fed_list) == 'table' and fed_list or { fed_list }
    api.ban_chat_member(chat_id, user_id)
    local success
    for _, fed in pairs(fed_list) do
        success = redis:sadd('fedbans:' .. fed, user_id)
    end
    return success
end

function utils.fed_unban_chat_member(chat_id, user_id, fed_list)
    if not chat_id or not user_id then
        return false
    end
    fed_list = type(fed_list) == 'table' and fed_list or { fed_list }
    local success
    api.unban_chat_member(chat_id, user_id)
    for _, fed in pairs(fed_list) do
        success = redis:srem('fedbans:' .. fed, user_id)
    end
    return success
end

function utils.is_fed_banned(fed_id, user_id)
    if not fed_id or not user_id then
        return false
    end
    return redis:sismember('fedbans:' .. fed_id, user_id) and true or false
end

function utils.get_feds(chat_id)
    if not chat_id then
        return false
    end
    return redis:smembers('chat:' .. chat_id .. ':feds')
end

function utils.get_fed_bans(fed_id)
    if not fed_id then
        return false
    end
    return #redis:smembers('fedbans:' .. fed_id)
end

function utils.fed_allowlist(chat_id, user_id)
    if not chat_id or not user_id then
        return false
    end
    return redis:sadd('fedallowlist:' .. chat_id, user_id)
end

function utils.is_user_fed_allowlisted(chat_id, user_id)
    if not chat_id or not user_id then
        return false
    end
    return redis:sismember('fedallowlist:' .. chat_id, user_id) and true or false
end

return utils