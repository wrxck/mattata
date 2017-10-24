local utils = {}
local redis = require('mattata-redis')
local configuration = require('configuration')

local mattata = {}
local api = {}
local tools = {}

function utils:init(configuration, token)
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

function utils.service_message(message)
    if message.new_chat_member then
        return true, 'new_chat_member'
    elseif message.left_chat_member then
        return true, 'left_chat_member'
    elseif message.new_chat_title then
        return true, 'new_chat_title'
    elseif message.new_chat_photo then
        return true, 'new_chat_photo'
    elseif message.delete_chat_photo then
        return true, 'delete_chat_photo'
    elseif message.group_chat_created then
        return true, 'group_chat_created'
    elseif message.supergroup_chat_created then
        return true, 'supergroup_chat_created'
    elseif message.channel_chat_created then
        return true, 'channel_chat_created'
    elseif message.migrate_to_chat_id then
        return true, 'migrate_to_chat_id'
    elseif message.migrate_from_chat_id then
        return true, 'migrate_from_chat_id'
    elseif message.pinned_message then
        return true, 'pinned_message'
    elseif message.successful_payment then
        return true, 'successful_payment'
    end
    return false
end

function utils.is_media(message)
    if message.audio or message.document or message.game or message.photo or message.sticker or message.video or message.voice or message.video_note or message.contact or message.location or message.venue or message.invoice then
        return true
    end
    return false
end

function utils.media_type(message)
    if message.audio then
        return 'audio'
    elseif message.document then
        return 'document'
    elseif message.game then
        return 'game'
    elseif message.photo then
        return 'photo'
    elseif message.sticker then
        return 'sticker'
    elseif message.video then
        return 'video'
    elseif message.voice then
        return 'voice'
    elseif message.video_note then
        return 'video note'
    elseif message.contact then
        return 'contact'
    elseif message.location then
        return 'location'
    elseif message.venue then
        return 'venue'
    elseif message.invoice then
        return 'invoice'
    elseif message.forward_from or message.forward_from_chat then
        return 'forwarded'
    elseif message.text then
        return message.text:match('[\216-\219][\128-\191]') and 'rtl' or 'text'
    end
    return ''
end

function utils.file_id(message)
    if message.audio then
        return message.audio.file_id
    elseif message.document then
        return message.document.file_id
    elseif message.sticker then
        return message.sticker.file_id
    elseif message.video then
        return message.video.file_id
    elseif message.voice then
        return message.voice.file_id
    elseif message.video_note then
        return message.video_note.file_id
    end
    return ''
end

function utils.get_user_count()
    return #redis:keys('user:*:info')
end

function utils.get_group_count()
    return #redis:keys('chat:*:info')
end

function utils.clear_broadcast_memory()
    local broadcasts = redis:keys('broadcasted:*')
    for k, v in pairs(broadcasts) do
        if redis:get(v) then
            redis:del(v)
        end
    end
end

function utils.get_user_language(user_id)
    return redis:hget('chat:' .. user_id .. ':settings', 'language') or 'en_gb'
end

function utils.get_log_chat(chat_id)
    return redis:hget('chat:' .. chat_id .. ':settings', 'log chat') or configuration.log_channel or false
end

function utils.get_missing_languages(delimiter)
    local missing_languages = redis:smembers('mattata:missing_languages')
    if not missing_languages then
        return false
    end
    local output = {}
    for k, v in pairs(missing_languages) do
        table.insert(output, v)
    end
    local delimiter = delimiter or ', '
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
        for k, v in pairs(all) do
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
    table.sort(mattata.plugin_list)
    for k, v in pairs(mattata.plugin_list) do
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

function utils.send_reply(message, text, parse_mode, disable_web_page_preview, reply_markup, token)
    reply_markup = reply_markup or {
        ['remove_keyboard'] = true
    }
    parse_mode = tostring(parse_mode):lower()
    if parse_mode ~= 'markdown' and parse_mode ~= 'html' then
        parse_mode = nil
    end
    return mattata.api.send_message(message, text, parse_mode, disable_web_page_preview, false, message.message_id, reply_markup, token)
end

function utils.toggle_user_setting(chat_id, user_id, setting)
    if not chat_id or not user_id or not setting then
        return false
    elseif not redis:hexists('user:' .. user_id .. ':' .. chat_id .. ':settings', tostring(setting)) then
        local success = false
        if setting == 'restrict messages' then
            success = mattata.api.restrict_chat_member(chat_id, user_id, os.time(), false)
        elseif setting == 'restrict media messages' then
            success = mattata.api.restrict_chat_member(chat_id, user_id, os.time(), nil, false)
        elseif setting == 'restrict other messages' then
            success = mattata.api.restrict_chat_member(chat_id, user_id, os.time(), nil, nil, false)
        elseif setting == 'restrict web page previews' then
            success = mattata.api.restrict_chat_member(chat_id, user_id, os.time(), nil, nil, nil, false)
        end
        if success then
            if setting == 'restrict messages' then
                redis:hset('user:' .. user_id .. ':' .. chat_id .. ':settings', 'restrict media messages', true)
                redis:hset('user:' .. user_id .. ':' .. chat_id .. ':settings', 'restrict other messages', true)
                redis:hset('user:' .. user_id .. ':' .. chat_id .. ':settings', 'restrict web page previews', true)
            end
            redis:hset('user:' .. user_id .. ':' .. chat_id .. ':settings', tostring(setting), true)
        end
        return success
    end
    local success = false
    if setting == 'restrict messages' then
        success = mattata.api.restrict_chat_member(chat_id, user_id, os.time(), true)
    elseif setting == 'restrict media messages' then
        success = mattata.api.restrict_chat_member(chat_id, user_id, os.time(), nil, true)
    elseif setting == 'restrict other messages' then
        success = mattata.api.restrict_chat_member(chat_id, user_id, os.time(), nil, nil, true)
    elseif setting == 'restrict web page previews' then
        success = mattata.api.restrict_chat_member(chat_id, user_id, os.time(), nil, nil, nil, true)
    end
    if success then
        if setting == 'restrict messages' then
            redis:hdel('user:' .. user_id .. ':' .. chat_id .. ':settings', 'restrict media messages')
            redis:hdel('user:' .. user_id .. ':' .. chat_id .. ':settings', 'restrict other messages')
            redis:hdel('user:' .. user_id .. ':' .. chat_id .. ':settings', 'restrict web page previews')
        end
        return redis:hdel('user:' .. user_id .. ':' .. chat_id .. ':settings', tostring(setting))
    end
    return success
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

function utils.get_user_message_statistics(user_id, chat_id)
    return {
        ['messages'] = tonumber(redis:get('messages:' .. user_id .. ':' .. chat_id)) or 0,
        ['name'] = redis:hget('user:' .. user_id .. ':info', 'first_name'),
        ['id'] = user_id
    }
end

function utils.reset_message_statistics(chat_id)
    if not chat_id or tonumber(chat_id) == nil then
        return false
    end
    local messages = redis:keys('messages:*:' .. chat_id)
    if not next(messages) then
        return false
    end
    for k, v in pairs(messages) do
        redis:del(v)
    end
    return true
end

function utils.input(s)
    local mentioned_user = false
    if not s then
        return false
    elseif type(s) == 'table' then
        if s.entities and #s.entities >= 2 and s.entities[2].type == 'text_mention' then
            mentioned_user = s.entities[2].user.id
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
    return redis:hget('chat:' .. chat_id .. ':values', tostring(value))
end

function utils.log_error(error_message)
    error_message = tostring(error_message):gsub('%%', '%%%%')
    local output = string.format('%s[31m[Error] %s%s[0m', string.char(27), error_message, string.char(27))
    print(output)
end

function utils.write_file(file_path, content)
    file_path = tostring(file_path)
    content = tostring(content)
    local file = io.open(file_path, 'w+')
    file:write(content)
    file:close()
    return file
end

_G.table.contains = function(tab, match)
    for _, val in pairs(tab) do
        if val == match then
            return true
        end
    end
    return false
end

_G.table.random = function(tab, seed)
    if seed and tonumber(seed) ~= nil then
        math.randomseed(seed)
    end
    tab = type(tab) == 'table' and tab or { tostring(tab) }
    local total = 0
    for key, chance in pairs(tab) do
        total = total + chance
    end
    local choice = math.random() * total
    for key, chance in pairs(tab) do
        choice = choice - chance
        if choice < 0 then
            return key
        end
    end
end

return utils