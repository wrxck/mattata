--[[
                       _   _        _
       _ __ ___   __ _| |_| |_ __ _| |_ __ _
      | '_ ` _ \ / _` | __| __/ _` | __/ _` |
      | | | | | | (_| | |_| || (_| | || (_| |
      |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|

      v1.2

      Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
      See LICENSE for details

]]

local mattata = {}
local https = require('ssl.https')
local ltn12 = require('ltn12')
local json = require('dkjson')
local redis = dofile('libs/redis.lua')
local configuration = require('configuration')
local api = require('telegram-bot-lua.core').configure(configuration.bot_token)
local tools = require('telegram-bot-lua.tools')
local socket = require('socket')
local utils = dofile('libs/utils.lua')
local html = require('htmlEntities')

local plugin_list = {}
local administrative_plugin_list = {}
local inline_plugin_list = {}

function mattata:init()
    self.info = api.info -- Set the bot's information to the object fetched from the Telegram bot API.
    mattata.info = api.info
    self.plugins = {} -- Make a table for the bot's plugins.
    self.api = api
    self.tools = tools
    self.configuration = configuration
    self.beta_plugins = {}
    for k, v in ipairs(configuration.plugins) do -- Iterate over all of the configured plugins.
        local true_path = v
        for _, p in pairs(configuration.administrative_plugins) do
            if v == p then
                true_path = 'administration.' .. v
            end
        end
        for _, p in pairs(configuration.beta_plugins) do
            if v == p then
                table.insert(self.beta_plugins, v)
            end
        end
        local plugin = require('plugins.' .. true_path) -- Load each plugin.
        if not plugin then
            error('Invalid plugin: ' .. true_path)
        elseif mattata.is_duplicate(configuration.plugins, v) then
            error('Duplicate plugin: ' .. v)
        end
        plugin.is_administrative = true_path:match('^administration%.') and true or false
        self.plugins[k] = plugin
        self.plugins[k].name = v
        if self.beta_plugins[v] then
            plugin.is_beta_plugin = true
        end
        if plugin.init then -- If the plugin has an `init` function, run it.
            plugin.init(self, configuration)
        end
        plugin.is_administrative = (self.plugins[k].name == 'administration' or true_path:match('^administration%.')) and true or false
        -- By default, a plugin doesn't have inline functionality; but, if it does, set it to `true` appropriately.
        plugin.is_inline = plugin.on_inline_query and true or false
        plugin.commands = plugin.commands or {} -- If the plugin hasn't got any commands configured, then set a blank
        -- table, so when it comes to iterating over the commands later on, the bot won't encounter any problems.
        if plugin.help and not plugin.is_beta_plugin then -- If the plugin has help documentation, then insert it into other tables (where necessary).
            if plugin.is_administrative then
                table.insert(administrative_plugin_list, plugin.help)
            else
                table.insert(plugin_list, plugin.help)
                if plugin.is_inline then -- If the plugin is inline and has documentation, then insert the documentation into
                -- the `inline_plugin_list` table.
                    table.insert(inline_plugin_list, plugin.help)
                end
            end
            plugin.help = 'Usage:\n' .. plugin.help:gsub('%. (Alias)', '.\n%1') -- Make the plugin's documentation style all nicely unified, for consistency.
        end
        self.plugin_list = plugin_list
        self.inline_plugin_list = inline_plugin_list
        self.administrative_plugin_list = administrative_plugin_list
    end
    print(configuration.connected_message)
    local info_message = '\tUsername: @' .. self.info.username .. '\n\tName: ' .. self.info.name .. '\n\tID: ' .. self.info.id
    print('\n' .. info_message .. '\n')
    if redis:get('mattata:version') ~= configuration.version then
        local success = dofile('migrate.lua')
        print(success)
    end
    self.version = configuration.version
    -- Make necessary database changes if the version has changed.
    if not redis:get('mattata:version') or redis:get('mattata:version') ~= self.version then
        redis:set('mattata:version', self.version)
    end
    self.last_update = self.last_update or 0 -- If there is no last update known, make it 0 so the bot doesn't encounter any problems when it tries to add the necessary increment.
    self.last_backup = self.last_backup or os.date('%V')
    self.last_cron = self.last_cron or os.date('%M')
    local init_message = '<pre>' .. configuration.connected_message .. '\n\n' .. mattata.escape_html(info_message) .. '\n\n\tPlugins loaded: ' .. #configuration.plugins - #configuration.administrative_plugins .. '\n\tAdministrative plugins loaded: ' .. #configuration.administrative_plugins .. '</pre>'
    mattata.send_message(configuration.log_chat, init_message:gsub('\t', ''), 'html')
    for _, admin in pairs(configuration.admins) do
        mattata.send_message(admin, init_message:gsub('\t', ''), 'html')
    end
    local shutdown = redis:get('mattata:shutdown')
    if shutdown then
        local chat_id, message_id = shutdown:match('^(%-?%d+):(%d*)$')
        mattata.edit_message_text(chat_id, message_id, 'Successfully rebooted!')
        redis:del('mattata:shutdown')
    end
    return true
end

-- Set a bunch of function aliases, for consistency & compatibility.
for i, v in pairs(api) do
    mattata[i] = v
end
for i, v in pairs(tools) do
    mattata[i] = v
end
for i, v in pairs(utils) do
    if i ~= 'init' then
        mattata[i] = v
    end
end

function mattata:run(_, token)
-- mattata's main long-polling function which repeatedly checks the Telegram bot API for updates.
-- The objects received in the updates are then further processed through object-specific functions.
    token = token or configuration.bot_token
    assert(token, 'You need to enter your Telegram bot API token in configuration.lua, or pass it as the second argument when using the mattata:run() function!')
    mattata.is_running = mattata.init(self) -- Initialise the bot.
    utils.init(self, configuration)
    while mattata.is_running do -- Perform the main loop whilst the bot is running.
        local success = api.get_updates( -- Check the Telegram bot API for updates.
            configuration.updates.timeout,
            self.last_update + 1,
            configuration.updates.limit,
            json.encode(
                {
                    'message',
                    'edited_message',
                    'inline_query',
                    'callback_query'
                }
            ),
            configuration.use_beta_endpoint or false
        )
        if success and success.result then
            for _, v in ipairs(success.result) do
                self.last_update = v.update_id
                self.execution_time = socket.gettime()
                if v.message or v.edited_message then
                    if v.edited_message then
                        v.message = v.edited_message
                        v.edited_message = nil
                        v.message.old_date = v.message.date
                        v.message.date = v.message.edit_date
                        v.message.edit_date = nil
                        v.message.is_edited = true
                    else
                        v.message.is_edited = false
                    end
                    if v.message.reply_to_message then
                        v.message.reply = v.message.reply_to_message -- Make the `update.message.reply_to_message`
                        -- object `update.message.reply` to make any future handling easier.
                        v.message.reply_to_message = nil -- Delete the old value by setting its value to nil.
                    end
                    mattata.on_message(self, v.message)
                    if configuration.debug then
                        print(
                            string.format(
                                '%s[36m[Update #%s] Message%s from %s to %s: %s%s[0m',
                                string.char(27),
                                v.update_id,
                                v.message.is_edited and ' edit' or '',
                                v.message.from.id,
                                v.message.chat.id,
                                v.message.text,
                                string.char(27)
                            )
                        )
                    end
                elseif v.inline_query then
                    mattata.on_inline_query(self, v.inline_query)
                    if configuration.debug then
                        print(
                            string.format(
                                '%s[35m[Update #%s] Inline query from %s%s[0m',
                                string.char(27),
                                v.update_id,
                                v.inline_query.from.id,
                                string.char(27)
                            )
                        )
                    end
                elseif v.callback_query then
                    if v.callback_query.message and v.callback_query.message.reply_to_message then
                        v.callback_query.message.reply = v.callback_query.message.reply_to_message
                        v.callback_query.message.reply_to_message = nil
                    end
                    mattata.on_callback_query(self, v.callback_query.message, v.callback_query)
                    if configuration.debug then
                        print(
                            string.format(
                                '%s[33m[Update #%s] Callback query from %s%s[0m',
                                string.char(27),
                                v.update_id,
                                v.callback_query.from.id,
                                string.char(27)
                            )
                        )
                    end
                end
                self.result_time = socket.gettime() - self.execution_time
                if configuration.debug then
                    print('Update #' .. v.update_id .. ' took ' .. self.result_time .. ' seconds to process.')
                end
            end
        else
            mattata.log_error('There was an error retrieving updates from the Telegram bot API!')
        end
        if self.last_backup ~= os.date('%V') then -- If it's been a week since the last backup, perform another backup.
            self.last_backup = os.date('%V') -- Set the last backup time to now, since we're
            -- now performing one!
            print(io.popen('./backup.sh'):read('*all'))
        end
        if self.last_cron ~= os.date('%M') then -- Perform minutely CRON jobs.
            self.last_cron = os.date('%M')
            for i = 1, #self.plugins do
                local plugin = self.plugins[i]
                if plugin and plugin.cron then
                    local cron_success, res = pcall(function()
                        plugin.cron(self, configuration)
                    end)
                    if not cron_success then
                        mattata.exception(self, res, 'CRON: ' .. i, configuration.log_chat)
                    end
                end
            end
        end
    end
    print(self.info.first_name .. ' is shutting down...')
end

function mattata:on_message(message)

    -- If the message is old or is missing necessary fields/values, then we'll stop and allow the bot to start processing the next update(s).
    -- If the message was sent from a blacklisted chat, then we'll stop because we don't want the bot to respond there.
    if not mattata.is_valid(message) then
        return false
    elseif redis:get('blacklisted_chats:' .. message.chat.id) then
        return mattata.leave_chat(message.chat.id)
    end
    message = mattata.sort_message(message) -- Process the message.
    self.is_user_blacklisted, self.is_globally_blacklisted, self.is_globally_banned = mattata.is_user_blacklisted(message)
    -- We only want this functionality if the bot owner has been granted API permission to SpamWatch!
    self.is_spamwatch_blacklisted = configuration.keys.spamwatch ~= '' and mattata.is_spamwatch_blacklisted(message) or false

    if self.is_globally_banned and message.chat.type ~= 'private' then -- Only for the worst of the worst
        mattata.ban_chat_member(message.chat.id, message.from.id)
    end
    local language = require('languages.' .. mattata.get_user_language(message.from.id))
    if mattata.is_group(message) and mattata.get_setting(message.chat.id, 'force group language') then
        language = require('languages.' .. (mattata.get_value(message.chat.id, 'group language') or 'en_gb'))
    end
    self.language = language
    if mattata.process_spam(message, configuration) then
        return false
    end

    -- Perform the following actions if the user isn't blacklisted.
    if not self.is_user_blacklisted then
        mattata.process_afk(message)
        mattata.process_language(self, message)
        if message.text then
            message = mattata.process_natural_language(self, message)
        end
        message = mattata.process_stickers(message)
        message = mattata.check_links(message, false, true, false, true)
        message = mattata.process_deeplinks(message)
        -- If the user isn't current AFK, and they say they're going to be right back, we can
        -- assume that they are now going to be AFK, so we'll help them out and set them that
        -- way by making the message text the /afk command, which will later trigger the plugin.
        if (message.text:lower():match('^i?\'?l?l? ?[bg][rt][bg].?$') and not redis:hget('afk:' .. message.from.id, 'since')) then
            message.text = '/afk'
        end
        -- A boolean value to decide later on, whether the message is intended for the current plugin from the iterated table.
    end
    self.is_command = false
    self.is_command_done = false
    self.is_allowed_beta_access = false
    self.is_telegram = false

    -- If the message is one of those pesky Telegram channel pins, it won't send a service message. We'll trick it.
    if message.from.id == 777000 and message.forward_from_chat and message.forward_from_chat.type == 'channel' then
        self.is_telegram = true
        message.is_service_message = true
        message.service_message = 'pinned_message'
        message.pinned_message = {
            ['text'] = message.text,
            ['date'] = message.date,
            ['chat'] = message.chat,
            ['from'] = message.from,
            ['message_id'] = message.message_id,
            ['entities'] = message.entities,
            ['forward_from_message_id'] = message.forward_from_message_id,
            ['forward_from_chat'] = message.forward_from_chat,
            ['forward_date'] = message.forward_date
        }
    end

    -- This is the main loop which iterates over configured plugins and runs the appropriate functions.
    for _, plugin in ipairs(self.plugins) do
        if plugin.is_beta_plugin and mattata.is_global_admin(message.from.id) then
            self.is_allowed_beta_access = true
        end
        if not plugin.is_beta_plugin or (plugin.is_beta_plugin and self.is_allowed_beta_access) then
            local commands = #plugin.commands or {}
            for i = 1, commands do
                if message.text:match(plugin.commands[i]) and mattata.is_plugin_allowed(plugin.name, self.is_user_blacklisted, configuration) and not self.is_command_done and not self.is_telegram and (not message.is_edited or mattata.is_global_admin(message.from.id)) then
                    self.is_command = true
                    message.command = plugin.commands[i]:match('([%w_%-]+)')
                    if plugin.on_message and not mattata.is_plugin_disabled(plugin.name, message) then
                        local success, result = pcall(function()
                            return plugin.on_message(self, message, configuration, language)
                        end)
                        if not success then
                            mattata.exception(self, result, string.format('%s: %s', message.from.id, message.text), configuration.log_chat)
                        end
                        if mattata.get_setting(message.chat.id, 'delete commands') and self.is_command and not redis:sismember('chat:' .. message.chat.id .. ':no_delete', tostring(plugin.name)) and not message.is_natural_language then
                            mattata.delete_message(message.chat.id, message.message_id)
                        end
                        self.is_command_done = true
                    end
                end
            end
        end

        -- Allow plugins to handle new chat participants.
        if message.new_chat_members and plugin.on_member_join and not mattata.is_plugin_disabled(plugin.name, message) then
            local success, result = pcall(function()
                return plugin.on_member_join(self, message, configuration, language)
            end)
            if not success then
                mattata.exception(self, result, string.format('%s: %s', message.from.id, message.text),
                configuration.log_chat)
            end
        end

        -- Allow plugins to handle every new message (handy for anti-spam).
        if (message.text or message.is_media) and plugin.on_new_message and not mattata.is_plugin_disabled(plugin.name, message) then
            local success, result = pcall(function()
                return plugin.on_new_message(self, message, configuration, language)
            end)
            if not success then
                mattata.exception(self, result, string.format('%s: %s', message.from.id, message.text or tostring(message.media_type),
                configuration.log_chat))
            end
        end

        -- Allow plugins to handle service messages, and pass the type of service message before the message object.
        if message.is_service_message and plugin.on_service_message and not mattata.is_plugin_disabled(plugin.name, message) then
            local success, result = pcall(function()
                return plugin.on_service_message(self, message.service_message:gsub('_', ' '), message, configuration, language)
            end)
            if not success then
                mattata.exception(self, result, string.format('%s: %s', message.from.id, message.text or tostring(message.media_type),
                configuration.log_chat))
            end
        end
    end
    mattata.process_message(self, message, language)
    self.is_done = true
    self.is_ai = false
    return
end

function mattata:on_inline_query(inline_query)
    if not inline_query.from then
        return false, 'No `inline_query.from` object was found!'
    elseif redis:get('global_blacklist:' .. inline_query.from.id) then
        return false, 'This user is globally blacklisted!'
    end
    local language = require('languages.' .. mattata.get_user_language(inline_query.from.id))
    inline_query.offset = inline_query.offset and tonumber(inline_query.offset) or 0
    for _, plugin in ipairs(self.plugins) do
        local plugins = plugin.commands or {}
        for i = 1, #plugins do
            local command = plugin.commands[i]
            if not inline_query then
                return false, 'No `inline_query` object was found!'
            end
            if inline_query.query:match(command)
            and plugin.on_inline_query
            then
                local success, result = pcall(
                    function()
                        return plugin.on_inline_query(self, inline_query, configuration, language)
                    end
                )
                if not success then
                    local exception = string.format('%s: %s', inline_query.from.id, inline_query.query)
                    mattata.exception(self, result, exception, configuration.log_chat)
                    return false, result
                elseif not result then
                    return api.answer_inline_query(
                        inline_query.id,
                        api.inline_result()
                        :id()
                        :type('article')
                        :title(configuration.errors.results)
                        :description(plugin.help)
                        :input_message_content(api.input_text_message_content(plugin.help))
                    )
                end
            end
        end
    end
    if not inline_query.query or inline_query.query:gsub('%s', '') == '' then
        local offset = inline_query.offset and tonumber(inline_query.offset) or 0
        local list = mattata.get_inline_list(self.info.username, offset)
        if #list == 0 then
            local title = 'No more results found!'
            local description = 'There were no more inline features found. Use @' .. self.info.username .. ' <query> to search for more information about commands matching the given search query.'
            return mattata.send_inline_article(inline_query.id, title, description)
        end
        return mattata.answer_inline_query(inline_query.id, json.encode(list), 0, false, tostring(offset + 50))
    end
    local help = require('plugins.help')
    return help.on_inline_query(self, inline_query, configuration, language)
end

function mattata:on_callback_query(message, callback_query)
    if not callback_query.from then return false end
    if not callback_query.message or not callback_query.message.chat then
        message = {
            ['chat'] = {},
            ['message_id'] = callback_query.inline_message_id,
            ['from'] = callback_query.from
        }
    else
        message = callback_query.message
        message.exists = true
    end
    local language = require('languages.' .. mattata.get_user_language(callback_query.from.id))
    if message.chat.id and mattata.is_group(message) and mattata.get_setting(message.chat.id, 'force group language') then
        language = require('languages.' .. (mattata.get_value(message.chat.id, 'group language') or 'en_gb'))
    end
    self.language = language
    if redis:get('global_blacklist:' .. callback_query.from.id) and not callback_query.data:match('^join_captcha') and not mattata.is_global_admin(callback_query.from.id) then
        return false, 'This user is globally blacklisted!'
    elseif message and message.exists then
        if message.reply and message.chat.type ~= 'channel' and callback_query.from.id ~= message.reply.from.id and not callback_query.data:match('^game:') and not mattata.is_global_admin(callback_query.from.id) then
            local output = 'Only ' .. message.reply.from.first_name .. ' can use this!'
            return mattata.answer_callback_query(callback_query.id, output)
        end
    end
    for _, plugin in ipairs(self.plugins) do
        if not callback_query.data or not callback_query.from then
            return false
        elseif plugin.name == callback_query.data:match('^(.-):.-$') and plugin.on_callback_query then
            callback_query.data = callback_query.data:match('^[%a_]+:(.-)$')
            if not callback_query.data then
                plugin = callback_query.data
                callback_query = ''
            end
            local success, result = pcall(
                function()
                    return plugin.on_callback_query(self, callback_query, message or false, configuration, language)
                end
            )
            if not success then
                mattata.send_message(configuration.admins[1], json.encode(callback_query, {indent=true}))
                -- mattata.answer_callback_query(callback_query.id, language['errors']['generic'])
                local exception = string.format('%s: %s', callback_query.from.id, callback_query.data)
                mattata.exception(self, result, exception, configuration.log_chat)
                return false, result
            end
        end
    end
    return true
end

mattata.send_message = api.send_message


-- A variant of mattata.send_message(), optimised for sending a message as a reply that forces a
-- reply back from the user.
function mattata.send_force_reply(message, text, parse_mode, disable_web_page_preview, token)
    local success = api.send_message(
        message,
        text,
        parse_mode,
        disable_web_page_preview,
        false,
        message.message_id,
        '{"force_reply":true,"selective":true}',
        token
    )
    return success
end

function mattata.get_chat(chat_id, only_api, token)
    local success = api.get_chat(chat_id, token)
    if only_api then -- stops antispam using usernames stored in the database
        return success
    elseif success and success.result and success.result.type and success.result.type == 'private' then
        mattata.process_user(success.result)
    elseif success and success.result then
        mattata.process_chat(success.result)
    end
    return success
end

function mattata.is_plugin_disabled(plugin, message, is_administrative)
    if not plugin or not message then
        return false
    elseif type(message) == 'table' and message.chat.type == 'supergroup' and mattata.is_group_admin(message.chat.id, message.from.id) and mattata.get_setting(message.chat.id, 'enable plugins for admins') then
        return false
    end
    is_administrative = is_administrative or false
    plugin = plugin:lower():gsub('^administration/', '')
    if type(message) == 'table' and message.chat then
        message = message.chat.id
    end
    if mattata.table_contains(configuration.permanent_plugins, plugin) then
        return false
    end
    if is_administrative and not mattata.get_setting(message, 'use administration') and plugin ~= 'administration' then
        return true
    end
    local exists = redis:sismember('disabled_plugins:' .. message, plugin)
    return exists and true or false
end

function mattata:exception(err, message, log_chat)
    local output = string.format(
        '[%s]\n%s: %s\n%s\n',
        os.date('%X'),
        self.info.username,
        mattata.escape_html(err) or '',
        mattata.escape_html(message)
    )
    if log_chat then
        return mattata.send_message(
            log_chat,
            string.format('<pre>%s</pre>', output),
            'html'
        )
    end
    return output
end

function mattata.is_group_admin(chat_id, user_id, is_real_admin)
    if not chat_id or not user_id then
        return false
    elseif mattata.is_global_admin(chat_id) or mattata.is_global_admin(user_id) then
        return true
    elseif not is_real_admin and mattata.is_group_mod(chat_id, user_id) then
        return true
    end
    local user, res = mattata.get_chat_member(chat_id, user_id)
    if not user or not user.result then
        return false, res
    elseif user.result.status == 'creator' or user.result.status == 'administrator' then
        return true, res
    end
    return false, user.result.status
end

function mattata.is_group_mod(chat_id, user_id)
    if not chat_id or not user_id then
        return false
    elseif redis:sismember('administration:' .. chat_id .. ':mods', user_id) then
        return true
    end
    return false
end

function mattata.process_chat(chat)
    chat.id_str = tostring(chat.id)
    if chat.type == 'private' then
        return mattata.process_user(chat)
    end
    if not redis:hexists('chat:' .. chat.id .. ':info', 'id') then
        print(
            string.format(
                '%s[34m[+] Added the chat %s to the database!%s[0m',
                string.char(27),
                chat.username and '@' .. chat.username or chat.id,
                string.char(27)
            )
        )
    end
    redis:hset('chat:' .. chat.id .. ':info', 'title', chat.title)
    redis:hset('chat:' .. chat.id .. ':info', 'type', chat.type)
    if chat.username then
        chat.username = chat.username:lower()
        redis:hset('chat:' .. chat.id .. ':info', 'username', chat.username)
        redis:set('username:' .. chat.username, chat.id)
        if not redis:sismember('chat:' .. chat.id .. ':usernames', chat.username) then
            redis:sadd('chat:' .. chat.id .. ':usernames', chat.username)
        end
    end
    redis:hset('chat:' .. chat.id .. ':info', 'id', chat.id)
    return chat
end

function mattata.process_user(user)
    if not user then return user end
    if not user.id or not user.first_name then return false end
    redis:hset('user:' .. user.id .. ':info', 'id', user.id)
    local new = false
    user.name = user.first_name
    if user.last_name then
        user.name = user.name .. ' ' .. user.last_name
    end
    if not redis:hget('user:' .. user.id .. ':info', 'id') and configuration.debug then
        print(
            string.format(
                '%s[34m[+] Added the user %s to the database!%s%s[0m',
                string.char(27),
                user.username and '@' .. user.username or user.id,
                user.language_code and ' Language: ' .. user.language_code or '',
                string.char(27)
            )
        )
        new = true
    elseif configuration.debug then
        print(
            string.format(
                '%s[34m[+] Updated information about the user %s in the database!%s%s[0m',
                string.char(27),
                user.username and '@' .. user.username or user.id,
                user.language_code and ' Language: ' .. user.language_code or '',
                string.char(27)
            )
        )
    end
    redis:hset('user:' .. user.id .. ':info', 'type', 'private')
    redis:hset('user:' .. user.id .. ':info', 'name', user.name)
    redis:hset('user:' .. user.id .. ':info', 'first_name', user.first_name)
    if user.last_name then
        redis:hset('user:' .. user.id .. ':info', 'last_name', user.last_name)
    else
        redis:hdel('user:' .. user.id .. ':info', 'last_name')
    end
    if user.username then
        user.username = user.username:lower()
        redis:hset('user:' .. user.id .. ':info', 'username', user.username)
        redis:set('username:' .. user.username, user.id)
        if not redis:sismember('user:' .. user.id .. ':usernames', user.username) then
            redis:sadd('user:' .. user.id .. ':usernames', user.username)
        end
    else
        redis:hdel('user:' .. user.id .. ':info', 'username')
    end
    if user.language_code then
        if mattata.does_language_exist(user.language_code) and not redis:hget('chat:' .. user.id .. ':settings', 'language') then
        -- If a translation exists for the user's language code, and they haven't selected
        -- a language already, then set it as their primary language!
            redis:hset('chat:' .. user.id .. ':settings', 'language', user.language_code)
        end
        redis:hset('user:' .. user.id .. ':info', 'language_code', user.language_code)
    else
        redis:hdel('user:' .. user.id .. ':info', 'language_code')
    end
    redis:hset('user:' .. user.id .. ':info', 'is_bot', tostring(user.is_bot))
    if new then
        redis:hset('user:' .. user.id .. ':info', 'id', user.id)
    end
    if redis:get('nick:' .. user.id) then
        user.first_name = redis:get('nick:' .. user.id)
        user.name = user.first_name
        user.last_name = nil
    end
    return user, new
end

function mattata.sort_message(message)
    message.is_natural_language = false
    message.text = message.text or message.caption or '' -- Ensure there is always a value assigned to message.text.
    message.text = message.text:gsub('^/(%a+)%_', '/%1 ')
    if message.text:match('^[/!#]start .-$') then -- Allow deep-linking through the /start command.
        message.text = '/' .. message.text:match('^[/!#]start (.-)$')
    end
    message.is_media = mattata.is_media(message)
    message.media_type = mattata.media_type(message)
    message.file_id = mattata.file_id(message)
    message.is_service_message, message.service_message = mattata.service_message(message)
    if message.caption_entities then
        message.entities = message.caption_entities
        message.caption_entities = nil
    end
    if message.from.language_code then
        message.from.language_code = message.from.language_code:lower():gsub('%-', '_') -- make it fit with the names of our language files
        if message.from.language_code:len() == 2 and message.from.language_code ~= 'en' then
            message.from.language_code = message.from.language_code .. '_' .. message.from.language_code
        elseif message.from.language_code:len() == 2 or message.from.language_code == 'root' then -- not sure why but some english users were having `root` return as their language
            message.from.language_code = 'en_us'
        end
    end
    message.reply = message.reply and mattata.sort_message(message.reply) or nil
    if message.from then
        message.from = mattata.process_user(message.from)
    end
    if message.reply then
        message.reply.from = mattata.process_user(message.reply.from)
    end
    if message.forward_from then
        message.forward_from = mattata.process_user(message.forward_from)
    end
    if message.chat and message.chat.type ~= 'private' then
        -- Add the user to the set of users in the current chat.
        if configuration.administration.store_chat_members and message.from then
            if not redis:sismember('chat:' .. message.chat.id .. ':users', message.from.id) then
                redis:sadd('chat:' .. message.chat.id .. ':users', message.from.id)
            end
        end
        if message.new_chat_members then
            message.chat = mattata.process_chat(message.chat)
            for i = 1, #message.new_chat_members do
                if configuration.administration.store_chat_users then
                    redis:sadd('chat:' .. message.chat.id .. ':users', message.new_chat_members[i].id) -- add users to the chat's set in the database
                end
                message.new_chat_members[i] = mattata.process_user(message.new_chat_members[i])
            end
        elseif message.left_chat_member then -- if they've left the chat then there's no need for them to be in the set anymore
            message.chat = mattata.process_chat(message.chat)
            message.left_chat_member = mattata.process_user(message.left_chat_member)
            if configuration.administration.store_chat_users then
                redis:srem('chat:' .. message.chat.id .. ':users', message.left_chat_member.id)
            end
        end
    end
    if message.text and message.chat and message.reply and message.reply.from and message.reply.from.id == api.info.id then
        local action = redis:get('action:' .. message.chat.id .. ':' .. message.reply.message_id)
        -- If an action was saved for the replied-to message (as part of a multiple step command), then
        -- we'll get information about the action.
        if action then
            message.text = action .. ' ' .. message.text -- Concatenate the saved action's command
            -- with the new `message.text`.
            message.reply = nil -- This caused some issues with administrative commands which would
            -- prioritise replied-to users over users given by arguments.
            redis:del(action) -- Delete the action for this message, since we've done what we needed to do
            -- with it now.
        end
    end
    if message.entities then
        for n, entities in pairs(message.entities) do
            if entities.type == 'text_mention' then
                message.text = message.text:gsub(message.entities[n].user.first_name, message.entities[n].user.id)
            end
        end
    end
    return message
end

function mattata.is_global_admin(id)
    for _, v in pairs(configuration.admins) do
        if id == v then
            return true
        end
    end
    return false
end

function mattata.get_user(input, force_api, is_id_plugin, cache_only)
    if tonumber(input) == nil and input then -- check it's not an ID
        input = input:match('^%@?(.-)$')
        input = redis:get('username:' .. input:lower())
    end
    if not input or tonumber(input) == nil then -- if it's still not an ID then we'll give up
        return false
    end
    local user = redis:hgetall('user:' .. tostring(input) .. ':info')
    if is_id_plugin and user.id then
        local success = mattata.get_chat(user.id) -- Try and get latest info about the user for the ID plugin
        if success then
            return success
        end
    end
    if user.username and not cache_only then
        local scrape, scrape_res = https.request('https://t.me/' .. user.username)
        if scrape_res == 200 then
            local bio = scrape:match('%<div class="tgme_page_description "%>(.-)%</div%>')
            if bio then
                bio = bio:gsub('%b<>', '')
                bio = html.decode(bio)
                user.bio = bio
            end
        end
    end
    if user.id then
        return {
            ['result'] = {
                ['id'] = tonumber(user.id),
                ['type'] = user.type,
                ['name'] = user.name,
                ['first_name'] = user.first_name,
                ['last_name'] = user.last_name,
                ['username'] = user.username,
                ['is_bot'] = user.is_bot,
                ['bio'] = user.bio
            }
        }
    end
    if force_api then
        return mattata.get_chat(input)
    end
    return false
end

function mattata.get_inline_list(username, offset)
    offset = offset and tonumber(offset) or 0
    local inline_list = {}
    table.sort(inline_plugin_list)
    for k, v in pairs(inline_plugin_list) do
        if k > offset and k < offset + 50 then -- The bot API only accepts a maximum of 50 results, hence we need the offset.
            v = v:gsub('\n', ' ')
            table.insert(
                inline_list,
                mattata.inline_result()
                :type('article')
                :id(tostring(k))
                :title(v:match('^(/.-) %- .-$'))
                :description(v:match('^/.- %- (.-)$'))
                :input_message_content(
                    mattata.input_text_message_content(
                        string.format(
                            '• %s - %s\n\nTo use this command inline, you must use the syntax:\n@%s %s',
                            v:match('^(/.-) %- .-$'),
                            v:match('^/.- %- (.-)$'),
                            username,
                            v:match('^(/.-) %- .-$')
                        )
                    )
                )
                :reply_markup(
                    mattata.inline_keyboard():row(
                        mattata.row():switch_inline_query_button('Show me how!', v:match('^(/.-) '))
                    )
                )
            )
        end
    end
    return inline_list
end

function mattata.get_help(is_administrative, chat_id)
    local list_to_use = is_administrative == true and administrative_plugin_list or plugin_list
    local help = {}
    local count = 1
    table.sort(list_to_use)
    for _, v in pairs(list_to_use) do
        if v:match('^/.- %- .-$') then
            -- Do some replacement for plugins that have different primary commands to their plugin name.
            local to_match = v:gsub('/np', '/lastfm'):gsub('/r/', '/reddit '):gsub('/s/', '/sed '):gsub('(/cat)', '%1s')
            local plugin = to_match:match('^/([%w_]+) .-$')
            if not chat_id or not mattata.is_plugin_disabled(plugin, chat_id) then
                local command, description = v:match('^(.-) %- (.-)$')
                local parameters = ' '
                if not command then mattata.send_message(configuration.admins[1], v) end
                if command:match(' [%[<]') then
                    command, parameters = command:match('^(.-)( .-)$')
                    parameters = '<code>' .. mattata.escape_html(parameters) .. '</code> '
                end
                local output = command .. parameters .. '- <em>' .. mattata.escape_html(description) .. '</em>'
                table.insert(help, utf8.char(8226) .. ' ' .. output)
                count = count + 1
            end
        end
    end
    return help
end

function mattata.format_time(seconds)
    if not seconds or tonumber(seconds) == nil then
        return false
    end
    seconds = tonumber(seconds) -- Make sure we're handling a numerical value
    local minutes = math.floor(seconds / 60)
    if minutes == 0 then
        return seconds ~= 1 and seconds .. ' seconds' or seconds .. ' second'
    elseif minutes < 60 then
        return minutes ~= 1 and minutes .. ' minutes' or minutes .. ' minute'
    end
    local hours = math.floor(seconds / 3600)
    if hours == 0 then
        return minutes ~= 1 and minutes .. ' minutes' or minutes .. ' minute'
    elseif hours < 24 then
        return hours ~= 1 and hours .. ' hours' or hours .. ' hour'
    end
    local days = math.floor(seconds / 86400)
    if days == 0 then
        return hours ~= 1 and hours .. ' hours' or hours .. ' hour'
    elseif days < 7 then
        return days ~= 1 and days .. ' days' or days .. ' day'
    end
    local weeks = math.floor(seconds / 604800)
    if weeks == 0 then
        return days ~= 1 and days .. ' days' or days .. ' day'
    else
        return weeks ~= 1 and weeks .. ' weeks' or weeks .. ' week'
    end
end

function mattata.does_language_exist(language)
    return pcall( -- nice and simple, perform a pcall to require the language, and if it errors then it doesn't exist
        function()
            return require('languages.' .. language)
        end
    )
end

function mattata.save_to_file(content, file_path)
    if not content then
        return false
    end
    file_path = file_path or ('/tmp/temp_' .. os.time() .. '.txt')
    local file = io.open(file_path, 'w+')
    file:write(tostring(content))
    file:close()
    return true
end

function mattata.insert_keyboard_row(keyboard, first_text, first_callback, second_text, second_callback, third_text, third_callback)
-- todo: get rid of this function as it's dirty, who only allows 3 buttons in a row??
    table.insert(
        keyboard['inline_keyboard'],
        {
            {
                ['text'] = first_text,
                ['callback_data'] = first_callback
            },
            {
                ['text'] = second_text,
                ['callback_data'] = second_callback
            },
            {
                ['text'] = third_text,
                ['callback_data'] = third_callback
            }
        }
    )
    return keyboard
end

function mattata.is_user_blacklisted(message)
    if not message or not message.from or not message.chat then
        return false, false, false
    elseif mattata.is_global_admin(message.from.id) then
        return false, false, false
    end
    local gbanned = redis:get('global_ban:' .. message.from.id) -- Check if the user is globally
    -- blacklisted from using the bot.
    local group = redis:get('group_blacklist:' .. message.chat.id .. ':' .. message.from.id) -- Check
    -- if the user is blacklisted from using the bot in the current group.
    local gblacklisted = redis:get('global_blacklist:' .. message.from.id)
    return group, gblacklisted, gbanned
end

function mattata.is_spamwatch_blacklisted(message, force_check)
    if tonumber(message) ~= nil then -- Add support for passing just the user ID too!
        message = {
            ['from'] = {
                ['id'] = tonumber(message)
            }
        }
    elseif not message or not message.from then
        return false, nil, 'No valid message object was passed! It needs to have a message.from as well!', 404
    end
    local is_cached = redis:get('not_blacklisted:' .. message.from.id)
    if is_cached and not force_check then -- We don't want to perform an HTTPS call every time the bot sees a chat!
        return false, nil, 'That user is cached as not blacklisted!', 404
    end
    local response = {}
    local _ = https.request(
        {
            ['url'] = 'https://api.spamwat.ch/banlist/' .. message.from.id,
            ['method'] = 'GET',
            ['headers'] = {
                ['Authorization'] = 'Bearer ' .. configuration.keys.spamwatch
            },
            ['sink'] = ltn12.sink.table(response)
        }
    )
    response = table.concat(response)
    local jdat = json.decode(response)
    if not jdat then
        return false, nil, 'The server appears to be offline', 521
    elseif jdat.error then
        if jdat.code == 404 then -- The API returns a 404 code when the user isn't in the SpamWatch database
            redis:set('not_blacklisted:' .. message.from.id, true)
            redis:expire('not_blacklisted:' .. message.from.id, 604800) -- Let the key last a week!
        end
        return false, jdat, jdat.error, jdat.code
    elseif jdat.id then
        return true, jdat, 'Success', 200
    end
    return false, jdat, 'Error!', jdat.code or 404
end

function mattata.process_afk(message) -- Checks if the message references an AFK user and tells the
-- person mentioning them that they are marked AFK. If a user speaks and is currently marked as AFK,
-- then the bot will announce their return along with how long they were gone for.
    if message.from.username
    and redis:hget('afk:' .. message.from.id, 'since')
    and not mattata.is_plugin_disabled('afk', message)
    and not message.text:match('^[/!#]afk')
    and not message.text:lower():match('^i?\'?l?l? ?[bg][rt][bg].?$')
    then
        local since = os.time() - tonumber(redis:hget('afk:' .. message.from.id, 'since'))
        redis:hdel('afk:' .. message.from.id, 'since')
        redis:hdel('afk:' .. message.from.id, 'note')
        local keys = redis:keys('afk:' .. message.from.id .. ':replied:*')
        if #keys > 0 then
            for _, key in pairs(keys) do
                redis:del(key)
            end
        end
        local output = message.from.first_name .. ' has returned, after being /AFK for ' .. mattata.format_time(since) .. '.'
        mattata.send_message(message.chat.id, output)
    elseif (message.text:match('@[%w_]+') -- If a user gets mentioned, check to see if they're AFK.
    or message.reply) and not redis:get('afk:' .. message.from.id .. ':replied:' .. message.chat.id) then
        local username = message.reply and message.reply.from.id or message.text:match('@([%w_]+)')
        local success = mattata.get_user(username)
        if not success or not success.result or not success.result.id then
            return false
        end
        local exists = redis:hexists('afk:' .. success.result.id, 'since')
        if success and success.result and exists then -- If all the checks are positive, the mentioned user is AFK, so we'll tell the person mentioning them that this is the case!
            if message.reply then
                redis:set('afk:' .. message.from.id .. ':replied:' .. message.chat.id, true)
            end
            mattata.send_reply(message, success.result.first_name .. ' is currently AFK!')
        end
    end
end

function mattata.process_stickers(message)
    if message.chat.type == 'supergroup' and message.sticker then
        -- Process each sticker to see if they are one of the configured, command-performing stickers.
        for _, v in pairs(configuration.stickers.ban) do
            if message.sticker.file_unique_id == v then
                message.text = '/ban'
            end
        end
        for _, v in pairs(configuration.stickers.warn) do
            if message.sticker.file_unique_id == v then
                message.text = '/warn'
            end
        end
        for _, v in pairs(configuration.stickers.kick) do
            if message.sticker.file_unique_id == v then
                message.text = '/kick'
            end
        end
    end
    return message
end

function mattata:process_natural_language(message)
    local text = message.text:lower()
    local name = self.info.first_name:lower()
    if text:match(name .. '.- ban @?[%w_-]+ ?') then
        message.text = '/ban ' .. text:match(name .. '.- ban (@?[%w_-]+) ?')
    elseif text:match(name .. '.- warn @?[%w_-]+ ?') then
        message.text = '/warn ' .. text:match(name .. '.- warn (@?[%w_-]+) ?')
    elseif text:match(name .. '.- kick @?[%w_-]+ ?') then
        message.text = '/kick ' .. text:match(name .. '.- kick (@?[%w_-]+) ?')
    elseif text:match(name .. '.- unban @?[%w_-]+ ?') then
        message.text = '/unban ' .. text:match(name .. '.- unban (@?[%w_-]+) ?')
    elseif text:match(name .. '.- resume my music') then
        local myspotify = require('plugins.myspotify')
        local success = myspotify.reauthorise_account(message.from.id, configuration)
        local output = success and myspotify.play(message.from.id) or 'An error occured whilst trying to connect to your Spotify account, are you sure you\'ve connected me to it?'
        mattata.send_message(message.chat.id, output)
    end
    message.is_natural_language = true
    return message
end

function mattata.process_spam(message)
    if message.forward_from then return false end
    local msg_count = tonumber(
        redis:get('antispam:' .. message.chat.id .. ':' .. message.from.id) -- Check to see if the user
        -- has already sent 1 or more messages to the current chat, in the past 5 seconds.
    )
    or 1 -- If this is the first time the user has posted in the past 5 seconds, we'll make it 1 accordingly.
    redis:setex(
        'antispam:' .. message.chat.id .. ':' .. message.from.id,
        configuration.administration.global_antispam.ttl, -- set the TTL
        msg_count + 1 -- Increase the current message count by 1.
    )
    if msg_count == configuration.administration.global_antispam.message_warning_amount -- If the user has sent x messages in the past y seconds, send them a warning.
    -- and not mattata.is_global_admin(message.from.id)
    and message.chat.type == 'private' then
    -- Don't run the antispam plugin if the user is configured as a global admin in `configuration.lua`.
        mattata.send_reply( -- Send a warning message to the user who is at risk of being blacklisted for sending
        -- too many messages.
            message,
            string.format(
                'Hey %s, please don\'t send that many messages, or you\'ll be forbidden to use me for 24 hours!',
                message.from.username and '@' .. message.from.username or message.from.name
            )
        )
    elseif msg_count == configuration.administration.global_antispam.message_blacklist_amount -- If the user has sent x messages in the past y seconds, blacklist them globally from
    -- using the bot for 24 hours.
    -- and not mattata.is_global_admin(message.from.id) -- Don't blacklist the user if they are configured as a global
    -- admin in `configuration.lua`.
    then
        redis:set('global_blacklist:' .. message.from.id, true)
        if configuration.administration.global_antispam.blacklist_length ~= -1 and configuration.administration.global_antispam.blacklist_length ~= 'forever' then
            redis:expire('global_blacklist:' .. message.from.id, configuration.administration.global_antispam.blacklist_length)
        end
        return mattata.send_reply(
            message,
            string.format(
                'Sorry, %s, but you have been blacklisted from using me for the next 24 hours because you have been spamming!',
                message.from.username and '@' .. message.from.username or message.from.name
            )
        )
    end
    return false
end

function mattata:process_language(message)
    if message.from.language_code then
        if not mattata.does_language_exist(message.from.language_code) then
            if not redis:sismember('mattata:missing_languages', message.from.language_code) then -- If we haven't stored the missing language file, add it into the database.
                redis:sadd('mattata:missing_languages', message.from.language_code)
            end
            if (message.text == '/start' or message.text == '/start@' .. self.info.username) and message.chat.type == 'private' then
                mattata.send_message(
                    message.chat.id,
                    'It appears that I haven\'t got a translation in your language (' .. message.from.language_code .. ') yet. If you would like to voluntarily translate me into your language, please join <a href="https://t.me/mattataDev">my official development group</a>. Thanks!',
                    'html'
                )
            end
        elseif redis:sismember('mattata:missing_languages', message.from.language_code) then
        -- If the language file is found, yet it's recorded as missing in the database, it's probably
        -- new, so it is deleted from the database to prevent confusion when processing this list!
            redis:srem('mattata:missing_languages', message.from.language_code)
        end
    end
end

function mattata.process_deeplinks(message)
    if message.text:match('^/[%a_]+_%-%d+$') and message.chat.type == 'private' then
        message.text = message.text:gsub('^(/[%a_]+)_(.-)$', '%1 %2')
    end
    return message
end

function mattata.toggle_setting(chat_id, setting, value)
    value = (type(value) ~= 'string' and tostring(value) ~= 'nil') and value or true
    if not chat_id or not setting then
        return false
    elseif not redis:hexists('chat:' .. chat_id .. ':settings', tostring(setting)) then
        return redis:hset('chat:' .. chat_id .. ':settings', tostring(setting), value)
    end
    return redis:hdel('chat:' .. chat_id .. ':settings', tostring(setting))
end

function mattata.get_usernames(user_id)
    if not user_id then
        return false
    elseif tonumber(user_id) == nil then
        user_id = tostring(user_id):match('^@(.-)$') or tostring(user_id)
        user_id = redis:get('username:' .. user_id:lower())
        if not user_id then
            return false
        end
    end
    return redis:smembers('user:' .. user_id .. ':usernames')
end

function mattata.check_links(message, get_links, only_valid, whitelist, return_message, delete)
    message.is_invite_link = false
    local links = {}
    if message.entities then
        for i = 1, #message.entities do
            if message.entities[i].type == 'text_link' then
                message.text = message.text .. ' ' .. message.entities[i].url
            end
        end
    end
    for n in message.text:gmatch('%@[%w_]+') do
        table.insert(links, n:match('^%@([%w_]+)$'))
    end
    for n in message.text:gmatch('[Tt]%.[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/[%w_]+') do
        table.insert(links, n:match('/([Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/[%w_]+)$'))
    end
    for n in message.text:gmatch('[Tt]%.[Mm][Ee]/[%w_]+') do
        if not n:match('/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]$') then
            table.insert(links, n:match('/([%w_]+)$'))
        end
    end
    for n in message.text:gmatch('[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Mm][Ee]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/[%w_]+') do
        table.insert(links, n:match('/([Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/[%w_]+)$'))
    end
    for n in message.text:gmatch('[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Mm][Ee]/[%w_]+') do
        if not n:match('/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]$') then
            table.insert(links, n:match('/([%w_]+)$'))
        end
    end
    for n in message.text:gmatch('[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Dd][Oo][Gg]/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/[%w_]+') do
        table.insert(links, n:match('/([Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/[%w_]+)$'))
    end
    for n in message.text:gmatch('[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm]%.[Dd][Oo][Gg]/[%w_]+') do
        if not n:match('/[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]$') then
            table.insert(links, n:match('/([%w_]+)$'))
        end
    end
    for n in message.text:gmatch('[Tt][Gg]://[Jj][Oo][Ii][Nn]%?[Ii][Nn][Vv][Ii][Tt][Ee]=[%w_]+') do
        table.insert(links, '[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/' .. n:match('=([%w_]+)$'))
    end
    for n in message.text:gmatch('[Tt][Gg]://[Rr][Ee][Ss][Oo][Ll][Vv][Ee]%?[Dd][Oo][Mm][Aa][Ii][Nn]=[%w_]+') do
        table.insert(links, n:match('=([%w_]+)$'))
    end
    if whitelist then
        local count = 0
        for _, v in pairs(links) do
            v = v:match('^[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]') and v or v:lower()
            if delete then
                redis:del('whitelisted_links:' .. message.chat.id .. ':' .. v)
            else
                redis:set('whitelisted_links:' .. message.chat.id .. ':' .. v, true)
            end
            count = count + 1
        end
        return string.format(
            '%s link%s ha%s been %s in this chat!',
            count,
            count == 1 and '' or 's',
            count == 1 and 's' or 've',
            delete and 'blacklisted' or 'whitelisted'
        )
    end
    local checked = {}
    local valid = {}
    for _, v in pairs(links) do
        if not redis:get('whitelisted_links:' .. message.chat.id .. ':' .. v:lower()) and not mattata.is_whitelisted_link(v:lower()) then
            if v:match('^[Jj][Oo][Ii][Nn][Cc][Hh][Aa][Tt]/') then
                message.is_invite_link = true
                if only_valid then
                    local str, res = https.request('https://t.me/' .. v)
                    if res == 200 and str and str:match('tgme_page_title') then
                        table.insert(valid, v)
                    end
                end
                if not get_links then
                    return return_message and message or true
                end
            elseif not mattata.table_contains(checked, v:lower()) then
                if not mattata.get_user(v:lower()) then
                    local success = mattata.get_chat('@' .. v:lower(), true)
                    if success and success.result and success.result.type ~= 'private' and success.result.id ~= message.chat.id then
                        message.is_invite_link = true
                        if not get_links then
                            return return_message and message or true
                        end
                        table.insert(valid, v:lower())
                    end
                    table.insert(checked, v:lower())
                end
            end
        end
    end
    if get_links then
        if only_valid then
            return valid
        end
        return checked
    end
    return return_message and message or false
end

function mattata:process_message(message, language)
    local break_cycle = false
    if not message.chat then
        return true
    elseif self.is_command and not mattata.is_plugin_disabled('commandstats', message.chat.id) and not self.is_blacklisted then
        local command = message.text:match('^([!/#][%w_]+)')
        if command then
            redis:incr('commandstats:' .. message.chat.id .. ':' .. command)
            if not redis:sismember('chat:' .. message.chat.id .. ':commands', command) then
                redis:sadd('chat:' .. message.chat.id .. ':commands', command)
            end
        end
    end
    if message.chat and message.chat.type ~= 'private' and not mattata.service_message(message) and not mattata.is_plugin_disabled('statistics', message) and not mattata.is_privacy_enabled(message.from.id) and not self.is_blacklisted then
        redis:incr('messages:' .. message.from.id .. ':' .. message.chat.id)
    end
    if message.new_chat_members and mattata.get_setting(message.chat.id, 'use administration') and mattata.get_setting(message.chat.id, 'antibot') and not mattata.is_group_admin(message.chat.id, message.from.id) and not mattata.is_global_admin(message.from.id) then
        local kicked = {}
        local usernames = {}
        for _, v in pairs(message.new_chat_members) do
            if v.username and v.username:lower():match('bot$') and v.id ~= message.from.id and v.id ~= self.info.id and tostring(v.is_bot) == 'true' then
                local success = mattata.kick_chat_member(message.chat.id, v.id)
                if success then
                    table.insert(kicked, mattata.escape_html(v.first_name) .. ' [' .. v.id .. ']')
                    table.insert(usernames, '@' .. v.username)
                end
            end
        end
        if #kicked > 0 and #usernames > 0 and #kicked == #usernames then
            local log_chat = mattata.get_log_chat(message.chat.id)
            mattata.send_message(log_chat, string.format('<pre>%s [%s] has kicked %s from %s [%s] because anti-bot is enabled.</pre>', mattata.escape_html(self.info.first_name), self.info.id, table.concat(kicked, ', '), mattata.escape_html(message.chat.title), message.chat.id), 'html')
            return mattata.send_message(message, string.format('Kicked %s because anti-bot is enabled.', table.concat(usernames, ', ')))
        end
    end
    if message.chat.type == 'supergroup' and mattata.get_setting(message.chat.id, 'use administration') and mattata.get_setting(message.chat.id, 'word filter') and not mattata.is_group_admin(message.chat.id, message.from.id) and not mattata.is_global_admin(message.from.id) then
        local words = redis:smembers('word_filter:' .. message.chat.id)
        if words and #words > 0 then
            for _, v in pairs(words) do
                local text = message.text:lower()
                if text:match('^' .. v:lower() .. '$') or text:match('^' .. v:lower() .. ' ') or text:match(' ' .. v:lower() .. ' ') or text:match(' ' .. v:lower() .. '$') then
                    mattata.delete_message(message.chat.id, message.message_id)
                    local action = mattata.get_setting(message.chat.id, 'ban not kick') and mattata.ban_chat_member or mattata.kick_chat_member
                    local success = action(message.chat.id, message.from.id)
                    if success then
                        if mattata.get_setting(message.chat.id, 'log administrative actions') then
                            local log_chat = mattata.get_log_chat(message.chat.id)
                            mattata.send_message(log_chat, string.format('<pre>%s [%s] has kicked %s [%s] from %s [%s] for sending one or more prohibited words.</pre>', mattata.escape_html(self.info.first_name), self.info.id, mattata.escape_html(message.from.first_name), message.from.id, mattata.escape_html(message.chat.title), message.chat.id), 'html')
                        end
                        mattata.send_message(message.chat.id, string.format('Kicked %s for sending one or more prohibited words.', message.from.username and '@' .. message.from.username or message.from.first_name))
                        break_cycle = true
                    end
                end
            end
            if break_cycle then return true end
        end
    end
    if message.new_chat_members and message.chat.type ~= 'private' and mattata.get_setting(message.chat.id, 'use administration') and mattata.get_setting(message.chat.id, 'welcome message') and not mattata.get_setting(message.chat.id, 'require captcha') then
        if message.new_chat_members[1].id == self.info.id or (message.new_chat_members[1].username and message.new_chat_members[1].username:match('[Bb][Oo][Tt]$')) then
            return false -- we don't want to send a welcome message if it's us or another bot (we're going to assume normal users don't have a username ending in bot...)
        end
        local chat_member = mattata.get_chat_member(message.chat.id, message.new_chat_members[1].id)
        if chat_member.result.can_send_messages == false then
            return mattata.delete_message(message.chat.id, message.message_id)
        end
        local name = message.new_chat_members[1].first_name
        local first_name = mattata.escape_markdown(name)
        if message.new_chat_members[1].last_name then
            name = name .. ' ' .. message.new_chat_members[1].last_name
        end
        name = name:gsub('%%', '%%%%')
        name = mattata.escape_markdown(name)
        local title = message.chat.title:gsub('%%', '%%%%')
        title = mattata.escape_markdown(title)
        local username = message.new_chat_members[1].username and '@' .. message.new_chat_members[1].username or name
        local welcome_message = mattata.get_value(message.chat.id, 'welcome message') or configuration.join_messages
        if type(welcome_message) == 'table' then -- if it's a configured selection of welcome messages we'll just pick a random one
            welcome_message = welcome_message[math.random(#welcome_message)]:gsub('NAME', name)
        end
        welcome_message = welcome_message:gsub('%$user_id', message.new_chat_member.id):gsub('%$chat_id', message.chat.id):gsub('%$first_name', first_name):gsub('%$name', name):gsub('%$title', title):gsub('%$username', username)
        local keyboard = nil
        if mattata.get_setting(message.chat.id, 'send rules on join') then
            keyboard = mattata.inline_keyboard():row(mattata.row():url_button(utf8.char(128218) .. ' ' .. language['welcome']['1'], 'https://t.me/' .. self.info.username .. '?start=' .. message.chat.id .. '_rules'))
        end
        return mattata.send_message(message, welcome_message, 'markdown', true, false, nil, keyboard)
    end
    return false
end

return mattata