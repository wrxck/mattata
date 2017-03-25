--[[
                       _   _        _
       _ __ ___   __ _| |_| |_ __ _| |_ __ _
      | '_ ` _ \ / _` | __| __/ _` | __/ _` |
      | | | | | | (_| | |_| || (_| | || (_| |
      |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|


        Copyright (c) 2017 Matthew Hesketh
        See './LICENSE' for details

        Current version: v19

]]

local mattata = {}

local http = require('socket.http')
local https = require('ssl.https')
local url = require('socket.url')
local ltn12 = require('ltn12')
local multipart = require('multipart-post')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')
local api = require('telegram-bot-lua.core').configure(configuration.bot_token)
local tools = require('telegram-bot-lua.tools')
local plugin_list = {}
local inline_plugin_list = {}

function mattata:init()
    self.info = api.info -- Set the bot's information to the object fetched from the Telegram bot API.
    self.plugins = {} -- Make a table for the bot's plugins.
    for k, v in ipairs(configuration.plugins) do -- Iterate over all of the configured plugins.
        local plugin = require('plugins.' .. v) -- Load each plugin.
        self.plugins[k] = plugin
        self.plugins[k].name = v
        if plugin.init then
            plugin.init(
                self,
                configuration
            )
        end
        plugin.is_inline = false -- By default, a plugin doesn't have inline functionality.
        if plugin.on_inline_query then -- If the plugin has got a function for handling an inline query then set its is_inline value to true.
            plugin.is_inline = true
        end
        if not plugin.commands then -- If the plugin hasn't got any commands configured, then set a blank table so when it comes to iterating over the commands later on, it won't crash.
            plugin.commands = {}
        end
        if plugin.help then -- If the plugin has help documentation, then insert it into other tables (where necessary) and make sure the format is consistent.
            table.insert(
                plugin_list,
                plugin.help
            )
            if plugin.is_inline then -- If the plugin is inline and has documentation, then insert the documentation into the inline_plugin_list table.
                table.insert(
                    inline_plugin_list,
                    plugin.help
                )
            end
            plugin.help = 'Usage:\n' .. plugin.help:gsub('%. (Alias)', '.\n%1') -- Make the plugin's documentation style all nice and unified.
        end
    end
    print('Connected to the Telegram bot API!')
    print(
        string.format(
            '\n\tUsername: @%s\n\tName: %s\n\tID: %s\n',
            self.info.username,
            self.info.name,
            self.info.id
        )
    )
    self.version = 'v19'
    if not redis:get('mattata:version') or redis:get('mattata:version') ~= self.version then -- Make necessary database changes if the version has changed.
        redis:set(
            'mattata:version',
            self.version
        )
    end
    self.last_update = self.last_update or 0 -- If there is no last update known, make it 0 so the bot doesn't crash when it tries to increase it.
    self.last_backup = self.last_backup or os.date('%V')
    self.last_cron = self.last_cron or os.date('%H')
    self.last_m_cron = self.last_m_cron or os.date('%M')
    return true
end

mattata.request = api.request

--[[

    mattata's main long-polling function which repeatedly checks
    the Telegram bot API for updates.
    The objects received in the updates are then further processed
    through object-specific functions.

]]

function mattata:run(configuration, token)
    token = token or configuration.bot_token
    assert(
        token,
        'You need to enter your Telegram bot API token in configuration.lua, or pass it as the first argument when using the mattata.init() function!'
    )
    local init = mattata.init(self) -- Initialise the bot.
    while init do -- Perform the main loop.
        local res = api.get_updates(
            1, -- Timeout
            self.last_update + 1, -- Offset
            nil, -- Limit
            '["message", "channel_post", "inline_query", "callback_query"]' -- Array of allowed updates
        )
        if res then
            for _, update in ipairs(res.result) do
                self.last_update = update.update_id
                if update.message then
                    if update.message.reply_to_message then
                        update.message.reply = update.message.reply_to_message
                        update.message.reply_to_message = nil
                    end
                    mattata.on_message(
                        self,
                        update.message,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '%s[36m[Update #%s] Message from %s to %s%s[0m',
                                string.char(27),
                                update.update_id,
                                update.message.from.id,
                                update.message.chat.id,
                                string.char(27)
                            )
                        )
                    end
                --[[
                elseif update.edited_message then
                    if update.edited_message.reply_to_message then
                        update.edited_message.reply = update.edited_message.reply_to_message
                        update.edited_message.reply_to_message = nil
                    end
                    mattata.on_edited_message(
                        self,
                        update.edited_message,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '[Update #%s] Edited message from %s to %s',
                                update.update_id,
                                update.edited_message.from.id,
                                update.edited_message.chat.id
                            )
                        )
                    end
                ]]
                elseif update.channel_post then
                    if update.channel_post.reply_to_message then
                        update.channel_post.reply = update.channel_post.reply_to_message
                        update.channel_post.reply_to_message = nil
                    end
                    mattata.on_message(
                        self,
                        update.channel_post,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '%s[37m[Update #%s] Channel post from %s%s[0m',
                                string.char(27),
                                update.update_id,
                                update.channel_post.chat.id,
                                string.char(27)
                            )
                        )
                    end
                --[[
                elseif update.edited_channel_post then
                    if update.edited_channel_post.reply_to_message then
                        update.edited_channel_post.reply = update.edited_channel_post.reply_to_message
                        update.edited_channel_post.reply_to_message = nil
                    end
                    mattata.on_edited_message(
                        self,
                        update.edited_channel_post,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '[Update #%s] Edited channel post from %s',
                                update.update_id,
                                update.edited_channel_post.chat.id
                            )
                        )
                    end
                ]]
                elseif update.inline_query then
                    mattata.on_inline_query(
                        self,
                        update.inline_query,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '%s[35m[Update #%s] Inline query from %s%s[0m',
                                string.char(27),
                                update.update_id,
                                update.inline_query.from.id,
                                string.char(27)
                            )
                        )
                    end
                elseif update.callback_query then
                    if update.callback_query.message and update.callback_query.message.reply_to_message then
                        update.callback_query.message.reply = update.callback_query.message.reply_to_message
                        update.callback_query.message.reply_to_message = nil
                    end
                    mattata.on_callback_query(
                        self,
                        update.callback_query,
                        update.callback_query.message or false,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '%s[33m[Update #%s] Callback query from %s%s[0m',
                                string.char(27),
                                update.update_id,
                                update.callback_query.from.id,
                                string.char(27)
                            )
                        )
                    end
                else
                    print(
                        json.encode(
                            update,
                            {
                                ['indent'] = true
                            }
                        )
                    )
                end
            end
            update = nil
        else
            print(
                string.format(
                    '%s[31m[Error] There was an error retrieving updates from the Telegram bot API!%s[0m',
                    string.char(27),
                    string.char(27)
                )
            )
        end
        res = nil
        if self.last_backup ~= os.date('%V') then -- If it's been a week since the last backup, perform another backup.
            self.last_backup = os.date('%V') -- Set the last backup time to now, since we're now performing one!
            print(
                io.popen('./backup.sh'):read('*all')
            )
        end
        if self.last_cron ~= os.date('%H') then -- Perform hourly CRON jobs.
            self.last_cron = os.date('%H')
            for i = 1, #self.plugins do
                local plugin = self.plugins[i]
                if plugin.cron then
                    local success, res = pcall(
                        function()
                            plugin.cron(
                                self,
                                configuration
                            )
                        end
                    )
                    if not success then
                        mattata.exception(
                            self,
                            res,
                            'CRON: ' .. i,
                            configuration.log_chat
                        )
                    end
                end
            end
            for p, _ in pairs(package.loaded) do
                if p:match('^plugins%.') then
                    package.loaded[p] = nil
                end
            end
            package.loaded['mattata'] = nil
            package.loaded['configuration'] = nil
            for k, v in pairs(configuration) do
                configuration[k] = v
            end
            print('mattata is reloading...')
            mattata.init(
                self,
                configuration,
                token
            )
        end
        if self.last_m_cron ~= os.date('%M') then -- Perform minutely CRON jobs.
            self.last_m_cron = os.date('%M')
            for i = 1, #self.plugins do
                local plugin = self.plugins[i]
                if plugin.m_cron then
                    local success, res = pcall(
                        function()
                            plugin.m_cron(
                                self,
                                configuration
                            )
                        end
                    )
                    if not success then
                        mattata.exception(
                            self,
                            res,
                            'CRON: ' .. i,
                            configuration.log_chat
                        )
                    end
                end
            end
        end
    end
    print('mattata is shutting down...')
end

--[[

    Functions to run when the Telegram bot API (successfully) returns an object.
    Each object has a designated function within each plugin.

]]

function mattata:on_message(message, configuration)
    if not message or message.date < os.time() - 5 then -- Don't iterate over old messages.
        return
    end
    message.text = message.text or message.caption or ''
    if not message.from and message.text:match('^/') then
        return mattata.send_reply(
            message,
            'To be able to use me in this channel, you need to enable the "Sign Messages" option in your channel\'s settings.'
        )
    elseif not message.from or redis:get('global_blacklist:' .. message.from.id) or redis:get('group_blacklist:' .. message.chat.id .. ':' .. message.from.id) then -- Ignore messages from a user if they're speaking in a channel that doesn't have the sign messages setting enabled, or if they're blacklisted (whether that'd be globally or just in the group).
        return
    elseif redis:get('blacklisted_chats:' .. message.chat.id) then
        return mattata.leave_chat(message.chat.id)
    end
    self.info.name = redis:get('chat:' .. message.chat.id .. ':name') or self.info.name -- If the chat doesn't have a custom name for the bot to respond by, we'll stick with the default one that was set through BotFather.
    message = mattata.process_message(message) -- Process the message.
    if message.reply then
        message.reply = mattata.process_message(message.reply)
    end
    if redis:get('nick:' .. message.from.id) then
        message.from.first_name = redis:get('nick:' .. message.from.id)
        message.from.last_name = nil
        message.from.name = message.from.first_name
    end
    message.text = message.text:match('^/start (.-)$') or message.text -- Allow deep-linking through the /start command.
    if message.forward_from or message.forward_from_chat then
        return -- Don't process forwarded messages, since there's not much chance they'll be intended for the bot to handle.
    end
    if message.text and message.reply and message.reply.from.id == self.info.id and redis:get('action:' .. message.chat.id .. ':' .. message.reply.message_id) then -- If an action was saved for the replied-to message (as part of a multiple step command), then we'll get information about the action.
        local action = 'action:' .. message.chat.id .. ':' .. message.reply.message_id
        message.text = redis:get(action) .. ' ' .. message.text -- Concatenate the new message with the action's relevant command.
        redis:del(action) -- Delete the action for this message, since we've done what we needed to do with it now.
    end
    message.chat.title = message.chat.title or message.from.name -- If the chat type is private then there won't be a title value in the message.chat object, so we'll use the name of the message sender instead.
    local messages = tonumber(
        redis:get('antispam:' .. message.from.id)
    ) or 1
    if redis:hget(
        'chat:' .. message.chat.id .. ':settings',
        'use administration'
    ) then
        redis:setex(
            'antispam:' .. message.from.id,
            5,
            messages + 1
        )
    end
    if messages == 7 and not mattata.is_global_admin(message.from.id) then -- Override the message count if the user is configured as a global admin in configuration.lua.
        mattata.send_reply( -- Send a warning message to the user who is at risk of being blacklisted for sending too many messages.
            message,
            'Please don\'t spam messages, or you will be forbidden to use me for 24 hours!'
        )
    elseif messages == 15 and not mattata.is_global_admin(message.from.id) then
        redis:setex( -- Blacklist the user for 24 hours.
            'global_blacklist:' .. message.from.id,
            86400,
            true
        )
        return mattata.send_reply(
            message,
            'You have been blacklisted from using me for 24 hours.'
        )
    elseif message.chat.type == 'supergroup' and message.sticker then -- Process each sticker to see if they are one of the configured, command-bound stickers.
        for k, v in pairs(configuration.stickers.ban) do
            if message.file_id == v then
                message.text = '/ban'
            end
        end
        for k, v in pairs(configuration.stickers.warn) do
            if message.file_id == v then
                message.text = '/warn'
            end
        end
        for k, v in pairs(configuration.stickers.kick) do
            if message.file_id == v then
                message.text = '/kick'
            end
        end
    end
    if message.chat.type ~= 'private' and mattata.get_setting(message.chat.id, 'use administration') and mattata.get_setting(message.chat.id, 'remove inactive users') and mattata.get_chat_members(message.chat.username or message.chat.id) then
        for k, v in pairs( -- Iterate over all of the known members in the chat.
            json.decode(
                mattata.get_chat_members(message.chat.username or message.chat.id)
            )
        ) do
            if v.last_spoken and tonumber(v.last_spoken) ~= nil and v.last_spoken <= (
                os.time() - 604800
            ) and mattata.is_group_admin( -- Make sure the bot is an admin first, before we try and kick anybody.
                message.chat.id,
                self.info.id,
                true
            ) and mattata.get_chat_member( -- Make sure the user is still in the chat, although this is just a precautionary measure since the bot should have removed them from the members object if they were kicked or if they left.
                message.chat.id,
                v.id
            ) and not mattata.is_group_admin( -- Make sure the user isn't an administrator or moderator of the chat.
                message.chat.id,
                v.id
            ) then
                local success = mattata.kick_chat_member(
                    message.chat.id,
                    v.id
                )
                if success then
                    mattata.send_message(
                        message.chat.id,
                        string.format(
                            'I have kicked %s%s because they haven\'t spoken in a week!',
                            v.username and '@' or '',
                            v.username or v.first_name .. ' [' .. v.id .. ']'
                        )
                    )
                    members[v.id] = nil -- Remove the kicked user from the members object.
                    redis:hset( -- Update the database accordingly.
                        string.format(
                            'chat:%s:info',
                            message.chat.username or message.chat.id
                        ),
                        'members',
                        json.encode(members)
                    )
                    print(
                        string.format(
                            '[-] Removed %s%s from the members list for %s%s because they left the chat!',
                            v.username and '@' or '',
                            v.username or v.id,
                            message.chat.username and '@' or '',
                            message.chat.username or message.chat.id
                        )
                    )
                end
            end
        end
    end
    if not mattata.is_plugin_disabled(
        'github',
        message
    ) and message.text:match('h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/[A-Z%-%_a-z]+/[A-Z%-%_a-z]+') and message.entities then
        for k, v in pairs(message.entities) do
            if v.type == 'url' and message.text:match('(h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/[A-Z%-%_a-z]+/[A-Z%-%_a-z]+)'):len() == v.length and not https.request(
                message.text:match('(h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/[A-Z%-%_a-z]+/[A-Z%-%_a-z]+)')
            ):lower():match('%<title%>page not found') then
                message.text = string.format(
                    '/github %s %s',
                    message.text:match('h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/([A-Z%-%_a-z]+)/[A-Z%-%_a-z]+'),
                    message.text:match('h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/[A-Z%-%_a-z]+/([A-Z%-%_a-z]+)')
                )
            end
        end
    end
    local natural_language_gif = message.text:lower():match('%*insert a?n? ?(.-) gif[ %*]')
    message.text = natural_language_gif and '/gif ' .. natural_language_gif or message.text
    if message.text == '/exec' and message.reply and message.reply.text then
        message.text = '/exec ' .. message.reply.text
    end
    if mattata.is_global_admin(message.from.id) and message.text:match(' %-%-switch%-chat$') then
        message.text = message.text:match('^(.-) %-%-switch%-chat$')
        local old_id = message.from.id
        message.from.id = message.chat.id
        message.chat.id = old_id
    end
    if message.text:match('^%-%d+%_%a+$') and message.chat.type == 'private' then
        local chat_id, action = message.text:match('^(%-%d+)%_(%a+)$')
        if action == 'rules' and redis:hget(
            string.format(
                'chat:%s:settings',
                chat_id
            ),
            'use administration'
        ) then
            local administration = require('plugins.administration')
            return mattata.send_message(
                message.chat.id,
                administration.get_rules(chat_id),
                'markdown'
            )
        end
    end
    if message.new_chat_member then
        if message.new_chat_member.id == self.info.id then
            return mattata.send_message(
                message.chat.id,
                string.format(
                    'My name is %s and I\'m here to help. If you\'re an administrator, use /plugins to choose which features you want to enable in this group and use /administration to set up my administrative functionality. For more information, use /help.',
                    self.info.name
                )
            )
        end
        local administration = require('plugins.administration')
        administration.on_new_chat_member(
            self,
            message
        )
    end
    if message.chat.type == 'supergroup' and redis:hget(
        string.format(
            'chat:%s:settings',
            message.chat.id
        ),
        'use administration'
    ) then
        local administration = require('plugins.administration')
        administration.process_message(
            self,
            message
        )
    end
    if mattata.is_global_admin(message.from.id) and message.text:match('^/addresp .-\n.-$') then
        local response = message.text:lower():match('^/addresp .-\n(.-)$')
        local conversation = json.encode(
            {
                ['message'] = message.text:lower():match('^/addresp (.-)\n.-$'),
                ['responses'] = {
                    response
                }
            }
        )
        if redis:hget(
            'ai',
            message.text:lower():match('^/addresp (.-)\n.-$')
        ) then
            conversation = json.decode(
                redis:hget(
                    'ai',
                    message.text:lower():match('^/addresp (.-)\n.-$')
                )
            )
            local is_known = false
            local count = 1
            for k, v in pairs(conversation.responses) do
                if count > 19 then
                    is_known = true -- Prevent too many responses being cached!
                end
                if v == response then
                    is_known = true
                end
                count = count + 1
            end
            if is_known == false then
                table.insert(
                    conversation.responses,
                    response
                )
            end
            conversation = json.encode(conversation)
        end
        redis:hset(
            'ai',
            message,
            conversation
        )
        return mattata.send_reply(
            message,
            string.format(
                'Added "%s" as a response for "%s"!',
                response,
                message.text:lower():match('^/addresp (.-)\n.-$')
            )
        )
    elseif message.chat.type ~= 'private' and message.text:match('^%#%a+') and redis:get(
        string.format(
            'administration:%s:enabled',
            message.chat.id
        )
    ) then
        local trigger = message.text:match('^(%#%a+)')
        local custom_commands = redis:hkeys(
            string.format(
                'administration:%s:custom',
                message.chat.id
            )
        )
        if not custom_commands then
            return
        end
        for k, v in ipairs(custom_commands) do
            if trigger == v then
                local value = redis:hget(
                    string.format(
                        'administration:%s:custom',
                        message.chat.id
                    ),
                    trigger
                )
                if not value then
                    return
                end
                return mattata.send_message(
                    message.chat.id,
                    value
                )
            end
        end
    end
    for _, plugin in ipairs(self.plugins) do
        local plugins = plugin.commands or {}
        for i = 1, #plugins do
            local command = plugin.commands[i]
            if message.text:lower():match(command) then
                if not plugin.on_message then
                    return
                elseif (
                    plugin.name == 'administration' and not redis:hget(
                        string.format(
                            'chat:%s:settings',
                            message.chat.id
                        ),
                        'use administration'
                    ) and not message.text:match('^/administration') and not message.text:match('^/administration%@' .. self.info.username:lower()) and not message.text:match('^/groups') and not message.text:match('^/groups%@' .. self.info.username:lower())
                ) or (
                    plugin.name ~= 'administration' and mattata.is_plugin_disabled(
                        plugin.name,
                        message
                    )
                ) then
                    if message.chat.type ~= 'private' and not redis:get(
                        string.format(
                            'chat:%s:dismiss_disabled_message:%s',
                            message.chat.id,
                            plugin.name
                        )
                    ) then
                        return mattata.send_message(
                            message.chat.id,
                            string.format(
                                '%s is disabled in this chat.',
                                plugin.name:gsub('^%l', string.upper)
                            ),
                            nil,
                            true,
                            false,
                            nil,
                            json.encode(
                                {
                                    ['inline_keyboard'] = {
                                        {
                                            {
                                                ['text'] = 'Dismiss',
                                                ['callback_data'] = string.format(
                                                    'plugins:%s:dismiss_disabled_message:%s',
                                                    message.chat.id,
                                                    plugin.name
                                                )
                                            },
                                            {
                                                ['text'] = 'Enable',
                                                ['callback_data'] = string.format(
                                                    'plugins:%s:enable_via_message:%s',
                                                    message.chat.id,
                                                    plugin.name
                                                )
                                            }
                                        }
                                    }
                                }
                            )
                        )
                    end
                    return
                elseif plugin.name ~= 'administration' and mattata.is_plugin_disabled(
                    plugin.name,
                    message
                ) then
                    return
                elseif plugin.process_message and plugin.name ~= 'administration' then
                    local success, result = pcall(
                        function()
                            plugin.process_message(
                                message,
                                configuration
                            )
                        end
                    )
                    if not success then
                        return
                    end
                end
                local success, result = pcall(
                    function()
                        print(message.text)
                        return plugin.on_message(
                            self,
                            message,
                            configuration
                        )
                    end
                )
                if not success then
                    mattata.exception(
                        self,
                        result,
                        string.format(
                            '%s: %s',
                            message.from.id,
                            message.text
                        ),
                        configuration.log_chat
                    )
                    message = nil
                end
                return
            end
        end
    end
    if not mattata.is_plugin_disabled(
        'captionbotai',
        message
    ) and (
        message.photo or (
            message.reply and message.reply.photo
        )
    ) then
        if message.reply then
            message = message.reply
        end
        if message.text:lower():match('^wh?at .- th[ia][st].-') or message.text:lower():match('^who .- th[ia][st].-') then
            local captionbotai = require('plugins.captionbotai')
            return captionbotai.on_message(
                self,
                message,
                configuration
            )
        end
    end
    if not mattata.is_plugin_disabled(
        'statistics',
        message
    ) then
        local statistics = require('plugins.statistics')
        statistics.process_message(
            self,
            message,
            configuration
        )
        if message.text:match('^/statistics$') or message.text:match('^/statistics@' .. self.info.username:lower()) or message.text:match('^/stats$') or message.text:match('^/stats@' .. self.info.username:lower()) then
            return statistics.on_message(
                self,
                message,
                configuration
            )
        end
    end
    if mattata.is_global_admin(message.from.id) and message.chat.id == configuration.bug_reports_chat and message.reply and message.reply.forward_from and not message.text:match('^/') then
        return mattata.send_message(
            message.reply.forward_from.id,
            string.format(
                'Message from the developer regarding bug report #%s:\n<pre>%s</pre>',
                message.reply.forward_date,
                mattata.escape_html(message.text)
            ),
            'html'
        )
    elseif not mattata.is_plugin_disabled(
        'ai',
        message
    ) and not message.text:match('^Cancel$') and not message.text:match('^/?s/.-/.-/?$') and not message.photo and not message.text:match('^/') and not message.forward_from and (
        message.text:lower():gsub('%W', '') ~= ''
    ) then
        if (
            message.text:lower():match('^' .. self.info.name:lower() .. '.? .-$') or message.text:match('^.-%,? ' .. self.info.name:lower() .. '%??%.?%!?$') or message.chat.type == 'private' or (
                message.reply and message.reply.from.id == self.info.id
            )
        ) and message.text:lower() ~= self.info.name:lower() then
            message.text = message.text:lower():gsub(self.info.name:lower(), '')
            local ai = require('plugins.ai')
            return ai.on_message(
                self,
                message,
                configuration
            )
        elseif message.text:lower() == self.info.name:lower() then
            mattata.send_chat_action(message.chat.id)
            return mattata.send_reply(
                message,
                'Yes?'
            )
        end
    end
    if configuration.respond_to_misc then
        mattata.on_message_misc(
            self,
            message,
            configuration
        )
    end
    if ( -- If a user executes a command and it's not recognised, provide a response - explaining what's happened and how it can be resolved.
        message.text:match('^/') and message.chat.type == 'private'
    ) or (
        message.chat.type ~= 'private' and message.text:match('^/%a+@' .. self.info.username)
    ) then
        return mattata.send_reply(
            message,
            'Sorry, I don\'t understand that command.\nTip: Use /help to discover what else I can do!'
        )
    end
    message = nil
end

function mattata:on_message_misc(message, configuration)
    if message.text:lower():match('^what the fuck did you just fucking say about me%??$') then
        return mattata.send_message(
            message.chat.id,
            'What the fuck did you just fucking say about me, you little bitch? I\'ll have you know I graduated top of my class in the Navy Seals, and I\'ve been involved in numerous secret raids on Al-Quaeda, and I have over 300 confirmed kills. I am trained in gorilla warfare and I\'m the top sniper in the entire US armed forces. You are nothing to me but just another target. I will wipe you the fuck out with precision the likes of which has never been seen before on this Earth, mark my fucking words. You think you can get away with saying that shit to me over the Internet? Think again, fucker. As we speak I am contacting my secret network of spies across the USA and your IP is being traced right now so you better prepare for the storm, maggot. The storm that wipes out the pathetic little thing you call your life. You\'re fucking dead, kid. I can be anywhere, anytime, and I can kill you in over seven hundred ways, and that\'s just with my bare hands. Not only am I extensively trained in unarmed combat, but I have access to the entire arsenal of the United States Marine Corps and I will use it to its full extent to wipe your miserable ass off the face of the continent, you little shit. If only you could have known what unholy retribution your little "clever" comment was about to bring down upon you, maybe you would have held your fucking tongue. But you couldn\'t, you didn\'t, and now you\'re paying the price, you goddamn idiot. I will shit fury all over you and you will drown in it. You\'re fucking dead, kiddo.'
        )
    elseif message.text:lower():match('^gr8 b8,? m8$') then
        return mattata.send_message(
            message.chat.id,
            'Gr8 b8, m8. I rel8, str8 appreci8, and congratul8. I r8 this b8 an 8/8. Plz no h8, I\'m str8 ir8. Cre8 more, can\'t w8. We should convers8, I won\'t ber8, my number is 8888888, ask for N8. No calls l8 or out of st8. If on a d8, ask K8 to loc8. Even with a full pl8, I always have time to communic8 so don\'t hesit8.'
        )
    elseif message.text:lower():match('^w?h?y so salty%??!?%.?$') then
        return mattata.send_sticker(
            message.chat.id,
            'BQADBAADNQIAAlAYNw2gRrzQfFLv9wI'
        )
    elseif message.text:lower():match('^bone? appetite?%??!?%.?$') then
        local responses = {
            'bone apple tea',
            'bone app the teeth',
            'boney african feet',
            'bong asshole sneeze'
        }
        return mattata.send_message(
            message.chat.id,
            responses[math.random(#responses)]
        )
    elseif message.text:lower():match('^y?o?u a?re? a ?p?r?o?p?e?r? fucc?k?boy?i?%??!?%.?$') then
        return mattata.send_message(
            message.chat.id,
            'Sir, I am writing to you on this fateful day to inform you of a tragic reality. While it is unfortunate that I must be the one to let you know, it is for the greater good that this knowledge is made available to you as soon as possible. m8. u r a proper fukboy.'
        )
    elseif message.text:lower():match('^do you have the time,? to listen to me whine%??$') then
        return mattata.send_sticker(
            message.chat.id,
            'BQADBAADOwIAAlAYNw0I9ggFrg4HigI'
        )
    elseif message.text:lower():match('^' .. self.info.name:lower() .. '%,? wh?at time is it.?$') or message.text:lower():match('^' .. self.info.name:lower() .. '%,? wh?at%\'?s the time.?$') then
        message.text = '/time'
        return mattata.on_message(
            self,
            message,
            configuration
        )
    elseif message.text:lower():match('^' .. self.info.name:lower() .. '%,? how do i .-$') then
        message.text = '/google how do i ' .. message.text:lower():match('^' .. self.info.name:lower() .. '%,? how do i (.-)$')
        return mattata.on_message(
            self,
            message,
            configuration
        )
    elseif message.text:lower():match('^' .. self.info.name:lower() .. '%,? search %a+ for %"?%\'?.-%"?%\'?$') then
        local service, query = message.text:lower():match('^' .. self.info.name:lower() .. '%,? search (%a+) for %"?%\'?(.-)%"?%\'?$')
        if service ~= 'youtube' and service ~= 'bing' and service ~= 'google' and service ~= 'flickr' and service ~= 'itunes' then
            return mattata.send_reply(
                message,
                'I\'m sorry, I don\'t recognise that service.'
            )
        end
        message.text = string.format(
            '/%s %s',
            service,
            query
        )
        return mattata.on_message(
            self,
            message,
            configuration
        )
    elseif message.text:lower():match('^' .. self.info.name:lower() .. '%,? who is .-$') or message.text:lower():match('^' .. self.info.name:lower() .. '%,? wh?at is .-$') or message.text:lower():match('^' .. self.info.name:lower() .. '%,? who are .-$') or message.text:lower():match('^' .. self.info.name:lower() .. '%,? what are .-$') then
        message.text = '/ddg ' .. message.text:lower():match('^' .. self.info.name:lower() .. '%,? (.-)$')
        return mattata.on_message(
            self,
            message,
            configuration
        )
    elseif message.text:lower():match('^show me message .-%.?%!?$') and message.chat.type == 'supergroup' then
        local message_id = message.text:lower():match('ge .-%.?%!?$')
        message_id = mattata.trim(message_id):gsub('number', '')
        if tonumber(message_id) == nil then
            return
        end
        local user = message.from.first_name
        if message.from.username then
            user = '@' .. message.from.username
        end
        return mattata.send_message(
            message.chat.id,
            string.format(
                'Here you go %s!',
                user
            ),
            nil,
            true,
            false,
            message_id
        )
    elseif message.text:lower():match('^top%s?kek.?$') then
        return mattata.send_message(
            message.chat.id,
            'toppest of keks!'
        )
    elseif message.text:lower():match('^back.?$') or message.text:lower():match('^i\'?m back.?$') then
        return mattata.send_message(
            message.chat.id,
            'Welcome back, ' .. message.from.first_name .. '!'
        )
    elseif message.text:lower():match('^brb%.?%??%!?$') then
        return mattata.send_message(
            message.chat.id,
            string.format(
                'Don\'t be too long, %s...',
                message.from.first_name
            )
        )
    elseif message.text:lower():match('blue waffle') then
        return mattata.send_photo(
            message.chat.id,
            'AgADBAADwqcxG2QlwVA4aJHiXUZPJQoFYBkABP5H1dYBkOt9nswCAAEC'
        )
    elseif message.text:lower():match('content cop') or message.text:lower():match('tana mongeau') then
        return mattata.send_reply(
            message,
            'SAY N*GGER!!!'
        )
    elseif message.text:lower() == 'pek' or message.text:lower():match('trash dove') then
        return mattata.send_document(
            message.chat.id,
            'CgADBAADqwADEbgxUVfN63j_mEYYAg'
        )
    elseif message.text:lower():match('^gn%.?%??%!?$') or message.text:lower():match('^good night%.?%??%!?$') then
        return mattata.send_message(
            message.chat.id,
            'Good night, ' .. message.from.first_name .. ' - sleep well! ' .. utf8.char(128516)
        )
    elseif message.text:lower():match('^gm%.?%??%!?$') or message.text:lower():match('^good morning?%.?%??%!?$') then
        return mattata.send_message(
            message.chat.id,
            'Good morning, ' .. message.from.first_name .. '! Did you sleep well? ☺'
        )
    elseif message.text:lower():match('^my name is .-%.?%??%!?$') then
        local supposed_name = message.text:lower():match('^my name is (.-)%.?%??%!?$')
        if message.from.first_name:lower() ~= supposed_name then
            return mattata.send_reply(
                message,
                'No, you silly goose - your name is ' .. message.from.first_name .. '!'
            )
        end
    elseif message.text:lower():match('^wh?at is my name%.?%??%!?$') then
        local name = message.from.first_name
        if message.from.last_name then
            name = name .. ' ' .. message.from.last_name
        end
        return mattata.send_reply(
            message,
            'Why, your name is ' .. name .. '!'
        )
    elseif message.text:lower() == 'winrar' then
        return mattata.send_message(
            message.chat.id,
            'Please note that WinRAR is not free software. After a 40 day trial period you must either buy a license or remove it from your computer.'
        )
    elseif message.text == utf8.char(127814) then
        return mattata.send_message(
            message.chat.id,
            utf8.char(127825)
        )
    elseif message.text == utf8.char(127825) then
        return mattata.send_message(
            message.chat.id,
            utf8.char(127814)
        )
    elseif message.text == 'LOL' then
        return mattata.send_reply(
            message,
            'LMAO'
        )
    elseif message.text:match('NSA') then
        return mattata.send_message(
            message.chat.id,
            utf8.char(128065)
        )
    elseif message.text:lower():match('make admin') or message.text:lower():match('make %a+ an admin') or message.text:lower():match('make %a+ admin') then
        return mattata.send_document(
            message.chat.id,
            'CgADBAADFwADJ5WxUim0qGqr-gYQAg'
        )
    elseif message.text:lower():match('pennis') then
        return mattata.send_reply(
            message,
            'and also dicke and balls!'
        )
    elseif message.text:lower():match('harambe') then
        return mattata.send_reply(
            message,
            '*gets dick out*'
        )
    elseif message.text:lower():match('ricc?k? harr?iss?on') then
        return mattata.send_reply(
            message,
            [[I’m Rick Harrison, and this is my pawn shop. I work here with my old man and my son, Big Hoss. Everything in here has a story and a price. One thing I’ve learned after 21 years – you never know WHAT is gonna come through that door.]]
        )
    elseif message.text:lower():match('^your not ') or message.text:lower():match(' your not ') then
        return mattata.send_reply(
            message,
            'you\'re*'
        )
    elseif message.text:lower() == 'coo' then
        return mattata.send_photo(
            message.chat.id,
            'AgADBAAD46gxG6e3EVHYSQNx3Fq-7x8-aRkABONfdSHFUmyNx_oDAAEC'
        )
    elseif message.text:lower():match('it%\'?s my birthday soon') then
        return mattata.send_reply(
            message,
            'get you a man who can give you both'
        )
    elseif (message.text:lower() == 'liv' or message.text:lower() == 'hot') and message.chat.id == -1001086436977 then
        local success = mattata.get_user_profile_photos(65984191)
        if not success or success.result.total_count == 0 then
            return
        end
        return mattata.send_photo(
            message.chat.id,
            success.result.photos[math.random(#success.result.photos)][1].file_id
        )
    elseif message.text:lower() == 'sei' and message.chat.id == -1001086436977 then
        local success = mattata.get_user_profile_photos(71712489)
        if not success or success.result.total_count == 0 then
            return
        end
        return mattata.send_photo(
            message.chat.id,
            success.result.photos[math.random(#success.result.photos)][1].file_id
        )
    elseif message.text:lower() == 'ameme' and message.chat.id == -1001086436977 then
        local success = mattata.get_user_profile_photos(340359975)
        if not success or success.result.total_count == 0 then
            return
        end
        return mattata.send_photo(
            message.chat.id,
            success.result.photos[math.random(#success.result.photos)][1].file_id
        )
    elseif message.text:lower() == 'dick' and message.chat.id == -1001086436977 then
        local success = mattata.get_user_profile_photos(64924135)
        if not success or success.result.total_count == 0 then
            return
        end
        return mattata.send_photo(
            message.chat.id,
            success.result.photos[math.random(#success.result.photos)][1].file_id
        )
    elseif message.text:lower() == 'owo' then
        return mattata.send_message(
            message.chat.id,
            'OwO, what\'s THIS?'
        )
    elseif message.text:lower():match('monke[ey]') then
        local emoji = {
            utf8.char(128584),
            utf8.char(128585),
            utf8.char(128586)
        }
        local success = mattata.send_reply(
            message,
            emoji[1]
        )
        os.execute('sleep 1s')
        mattata.edit_message_text(
            message.chat.id,
            success.result.message_id,
            emoji[2]
        )
        os.execute('sleep 1s')
        return mattata.edit_message_text(
            message.chat.id,
            success.result.message_id,
            emoji[3]
        )
    elseif message.text:lower():match('^.- is l[ou]ve?.?$') then
        return mattata.send_reply(
            message,
            message.text:lower():match('^(.-) is l[ou]ve?.?$') .. ' is life'
        )
    elseif message.text:lower():match('^.- a?re? l[ou]ve?.?$') then
        return mattata.send_reply(
            message,
            message.text:lower():match('^(.-) a?re? l[ou]ve?.?$') .. ' are life'
        )
    elseif message.text:lower():match('^trump is my president%.?%!?%??$') then
        return mattata.send_reply(
            message,
            'Well, he isn\'t MY president! ' .. utf8.char(128560)
        )
    elseif message.text:lower():match('^happy new year%.?%??%!?$') then
        local output = string.format(
            'But it\'s not %s yet!',
            os.date(
                '*t',
                os.time()
            ).year + 1
        )
        if os.date(
            '*t',
            os.time()
        ).month == 1 then
            output = string.format(
                'Thanks, %s - Happy New Year to you too! I can\'t believe it\'s %s already?!',
                message.from.first_name,
                os.date(
                    '*t',
                    os.time()
                ).year
            )
        end
        return mattata.send_reply(
            message,
            output
        )
    elseif message.text:lower():match('^' .. self.info.name:lower() .. ' what.?s? the weather') and not message.text:lower():match('in') then
        message.text = '/weather'
        return mattata.on_message(
            self,
            message,
            configuration
        )
    elseif message.text:lower():match('^' .. self.info.name:lower() .. '%,? .- or .-%?$') and message.text:lower():len() < 50 then
        local choices = {
            message.text:lower():match('^' .. self.info.name:lower() .. '%,? (.-) or .-%??$'),
            message.text:lower():match('^' .. self.info.name:lower() .. '%,? .- or (.-)%??$')
        }
        return mattata.send_reply(
            message,
            choices[math.random(#choices)]
        )
    elseif message.reply and message.reply.text and message.text:lower():match('^wh?at would ' .. self.info.name:lower() .. ' say%??%.?%!?$') and not mattata.is_plugin_disabled(
        'ai',
        message
    ) then
        local old_from = message.from
        message = message.reply
        message.from = old_from
        local ai = require('plugins.ai')
        return ai.on_message(
            self,
            message,
            configuration
        )
    end
end

--[[
function mattata:on_edited_message(edited_message, configuration)
    if not edited_message or edited_message.edit_date < os.time() - 5 or not edited_message.from then -- Don't iterate over old message edits.
        return
    end
    edited_message.text = edited_message.text or edited_message.caption or ''
    self.info.name = redis:get(
        string.format(
            'chat:%s:name',
            edited_message.chat.id
        )
    ) or 'mattata'
    if not redis:get(
        string.format(
            'message:%s:%s',
            edited_message.chat.id,
            edited_message.message_id
        )
    ) then
        return
    end
    edited_message.original_message_id = redis:get(
        string.format(
            'message:%s:%s',
            edited_message.chat.id,
            edited_message.message_id
        )
    )
    for _, plugin in ipairs(self.plugins) do
        local plugins = plugin.commands or {}
        for i = 1, #plugins do
            local command = plugin.commands[i]
            if edited_message.text:match(command) and plugin.on_edited_message then
                local success, result = pcall(
                    function()
                        return plugin.on_edited_message(
                            self,
                            edited_message,
                            configuration
                        )
                    end
                )
                if not success then
                    mattata.exception(
                        self,
                        result,
                        string.format(
                            '%s: %s',
                            edited_message.from.id,
                            edited_message.text
                        ),
                        configuration.log_chat
                    )
                    edited_message = nil
                    return
                end
            end
        end
    end
end
]]

function mattata:on_inline_query(inline_query, configuration)
    if not inline_query.from or redis:get('global_blacklist:' .. inline_query.from.id) then
        inline_query = nil
        return
    end
    for _, plugin in ipairs(self.plugins) do
        local plugins = plugin.commands or {}
        for i = 1, #plugins do
            local command = plugin.commands[i]
            if not inline_query then
                inline_query = nil
                return
            end
            if inline_query.query:match(command) and plugin.on_inline_query then
                local success, result = pcall(
                    function()
                        return plugin.on_inline_query(
                            self,
                            inline_query,
                            configuration
                        )
                    end
                )
                if not success then
                    mattata.exception(
                        self,
                        result,
                        string.format(
                            '%s: %s',
                            inline_query.from.id,
                            inline_query.query
                        ),
                        configuration.log_chat
                    )
                    inline_query = nil
                elseif not result then
                    return api.answer_inline_query(
                        inline_query.id,
                        api.inline_result():id():type('article'):title(configuration.errors.results):description(plugin.help):input_message_content(
                            api.input_text_message_content(plugin.help)
                        )
                    )
                end
            end
        end
    end
    if not inline_query.query or inline_query.query:gsub('%s', '') == '' then
        return mattata.answer_inline_query(
            inline_query.id,
            json.encode(
                mattata.get_inline_list(self.info.username)
            )
        )
    end
    local help = require('plugins.help')
    return help.on_inline_query(
        self,
        inline_query,
        configuration
    )
end

function mattata:on_callback_query(callback_query, message, configuration)
    if redis:get('global_blacklist:' .. callback_query.from.id) then
        callback_query = nil
        return
    elseif message then
        if message.reply and message.chat.type ~= 'channel' and callback_query.from.id ~= message.reply.from.id and not callback_query.data:match('^game:') and not mattata.is_global_admin(callback_query.from.id) then
            return mattata.answer_callback_query(
                callback_query.id,
                string.format(
                    'Only %s can use this!',
                    message.reply.from.first_name
                )
            )
        end
    end
    for _, plugin in ipairs(self.plugins) do
        if plugin.name == callback_query.data:match('^(.-):.-$') and plugin.on_callback_query then
            callback_query.data = callback_query.data:match('^%a+:(.-)$')
            if not callback_query.data then
                plugin = nil
                callback_query = nil
                return
            end
            local success, result = pcall(
                function()
                    return plugin.on_callback_query(
                        self,
                        callback_query,
                        callback_query.message or false,
                        configuration
                    )
                end
            )
            if not success then
                mattata.answer_callback_query(
                    callback_query.id,
                    'An error occured!'
                )
                mattata.exception(
                    self,
                    result,
                    string.format(
                        '%s: %s',
                        callback_query.from.id,
                        callback_query.data
                    ),
                    configuration.log_chat
                )
                plugin = nil
                callback_query = nil
                return
            end
        end
    end
end

--[[

    Functions which compliment the mattata API by providing Lua
    bindings to the Telegram bot API.

]]

function mattata.get_me(token)
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getMe',
            token
        )
    )
end

function mattata.get_updates(timeout, offset, token) -- https://core.telegram.org/bots/api#getupdates
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getUpdates',
            token
        ),
        {
            ['timeout'] = timeout,
            ['offset'] = offset
        }
    )
end

function mattata.send_message(message, text, parse_mode, disable_web_page_preview, disable_notification, reply_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendmessage
    local success = api.send_message(
        message,
        text,
        parse_mode,
        disable_web_page_preview,
        disable_notification,
        reply_id,
        reply_markup or '{"remove_keyboard":true}',
        token
    )
    if not success then
        success = api.send_message(
            message,
            text,
            parse_mode,
            disable_web_page_preview,
            disable_notification,
            reply_id,
            reply_markup,
            token
        )
    end
    return success
end

function mattata.send_reply(message, text, parse_mode, disable_web_page_preview, reply_markup, token) -- A variant of mattata.send_message(), optimised for sending a message as a reply.
    local success = api.send_message(
        message,
        text,
        parse_mode,
        disable_web_page_preview,
        false,
        message.message_id,
        reply_markup or '{"remove_keyboard":true}',
        token
    )
    if not success then
        success = api.send_message(
            message,
            text,
            parse_mode,
            disable_web_page_preview,
            false,
            message.message_id,
            reply_markup,
            token
        )
    end
    return success
end

function mattata.send_force_reply(message, text, parse_mode, disable_web_page_preview, token) -- A variant of mattata.send_message(), optimised for sending a message as a reply.
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

mattata.forward_message = api.forward_message
mattata.send_photo = api.send_photo
mattata.send_audio = api.send_audio
mattata.send_document = api.send_document
mattata.send_sticker = api.send_sticker
mattata.send_video = api.send_video
mattata.send_voice = api.send_voice
mattata.send_location = api.send_location
mattata.send_venue = api.send_venue
mattata.send_contact = api.send_contact
mattata.send_chat_action = api.send_chat_action
mattata.get_user_profile_photos = api.get_user_profile_photos
mattata.get_file = api.get_file
mattata.ban_chat_member = api.ban_chat_member
mattata.kick_chat_member = api.kick_chat_member
mattata.unban_chat_member = api.unban_chat_member
mattata.leave_chat = api.leave_chat
mattata.get_chat_administrators = api.get_chat_administrators
mattata.get_chat_members_count = api.get_chat_members_count
mattata.get_chat_member = api.get_chat_member
mattata.answer_callback_query = api.answer_callback_query
mattata.edit_message_text = api.edit_message_text
mattata.edit_message_caption = api.edit_message_caption
mattata.edit_message_reply_markup = api.edit_message_reply_markup
mattata.answer_inline_query = api.answer_inline_query
mattata.send_game = api.send_game
mattata.set_game_score = api.set_game_score
mattata.get_game_high_scores = api.get_game_high_scores

function mattata.get_chat(chat_id, token)
    local success = api.get_chat(
        chat_id,
        token
    )
    if success and success.result.type == 'private' then
        mattata.process_user(success.result)
    elseif success then
        mattata.process_chat(success.result)
    end
    return success
end

function mattata.is_plugin_disabled(plugin, message)
    if type(message) == 'table' then
        message = message.chat.id
    end
    if redis:hget(
        string.format(
            'chat:%s:disabled_plugins',
            message
        ),
        plugin
    ) == 'true' and plugin ~= 'plugins' then
        return true
    end
    return false
end

function mattata.get_redis_hash(k, v)
    if type(k) == 'table' then
        k = k.chat.id
    end
    return string.format(
        'chat:%s:%s',
        k,
        v
    )
end

function mattata.get_user_redis_hash(k, v)
    if type(k) == 'table' then
        k = k.id
    end
    return string.format(
        'user:%s:%s',
        k,
        v
    )
end

function mattata.get_word(str, i)
    if not str then
        return false
    end
    i = i or 1
    local n = 1
    for word in str:gmatch('%g+') do
        if n == i then
            return word
        end
        n = n + 1
    end
    str = nil
    n = nil
    return false
end

function mattata.input(s)
    if not s then
        return false
    end
    if s:lower():match('^mattata search %a+ for .-$') then
        return s:lower():match('^mattata search %a+ for (.-)$')
    elseif not s:lower():match('^[%%/%%!%%$%%^%%?%%&%%%%]') then
        return s
    end
    local input = s:find(' ')
    if not input then
        s = nil
        return false
    end
    return s:sub(input + 1)
end

mattata.trim = tools.trim

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
            string.format(
                '<pre>%s</pre>',
                output
            ),
            'html'
        )
    end
    err = nil
    message = nil
    log_chat = nil
end

mattata.download_file = tools.download_file

function mattata.is_group_admin(chat_id, user_id, is_real_admin)
    if mattata.is_global_admin(chat_id) or mattata.is_global_admin(user_id) then
        return true
    elseif not is_real_admin and mattata.is_group_mod(
        chat_id,
        user_id
    ) then
        return true
    end
    local admins = mattata.get_chat_administrators(chat_id)
    if not admins then
        return false
    end
    for _, admin in ipairs(admins.result) do
        if admin.user.id == user_id then
            return true
        end
    end
    chat_id = nil
    user_id = nil
    is_real_admin = nil
    return false
end

function mattata.is_group_mod(chat_id, user_id)
    if not chat_id or not user_id then
        return false
    elseif redis:get(
        string.format(
            'mods:%s:%s',
            chat_id,
            user_id
        )
    ) then
        return true
    end
    chat_id = nil
    user_id = nil
    return false
end

function mattata.is_group_owner(chat_id, user_id)
    local is_owner = false
    local user = mattata.get_chat_member(
        chat_id,
        user_id
    )
    if user.status == 'creator' then
        return true
    end
    chat_id = nil
    user_id = nil
    return false
end

mattata.get_linked_name = tools.get_linked_name
mattata.table_size = tools.table_size

function mattata.is_service_message(message)
    if message.new_chat_member or message.left_chat_member or message.new_chat_title or message.new_chat_photo or message.delete_chat_photo or message.group_chat_created or message.supergroup_chat_created or message.channel_chat_created or message.migrate_to_chat_id or message.migrate_from_chat_id or message.pinned_message then
        return true
    end
    message = nil
    return false
end

function mattata.service_message(message)
    if message.new_chat_member then
        return 'new_chat_member'
    elseif message.left_chat_member then
        return 'left_chat_member'
    elseif message.new_chat_title then
        return 'new_chat_title'
    elseif message.new_chat_photo then
        return 'new_chat_photo'
    elseif message.delete_chat_photo then
        return 'delete_chat_photo'
    elseif message.group_chat_created then
        return 'group_chat_created'
    elseif message.supergroup_chat_created then
        return 'supergroup_chat_created'
    elseif message.channel_chat_created then
        return 'channel_chat_created'
    elseif message.migrate_to_chat_id then
        return 'migrate_to_chat_id'
    elseif message.migrate_from_chat_id then
        return 'migrate_from_chat_id'
    elseif message.pinned_message then
        return 'pinned_message'
    end
    message = nil
    return ''
end

function mattata.is_media(message)
    if message.photo or message.audio or message.document or message.sticker or message.video or message.voice or message.contact or message.location or message.venue then
        return true
    end
    message = nil
    return false
end

function mattata.media_type(message)
    if message.photo then
        return 'photo'
    elseif message.audio then
        return 'audio'
    elseif message.document then
        return 'document'
    elseif message.sticker then
        return 'sticker'
    elseif message.video then
        return 'video'
    elseif message.voice then
        return 'voice'
    elseif message.contact then
        return 'contact'
    elseif message.location then
        return 'location'
    elseif message.venue then
        return 'venue'
    end
    message = nil
    return ''
end

function mattata.file_id(message)
    if message.photo then
        return message.photo[#message.photo].file_id
    elseif message.audio then
        return message.audio.file_id
    elseif message.document then
        return message.document.file_id
    elseif message.sticker then
        return message.sticker.file_id
    elseif message.video then
        return message.video.file_id
    elseif message.voice then
        return message.voice.file_id
    elseif message.contact then
        return message.contact.file_id
    elseif message.location then
        return message.location.file_id
    elseif message.venue then
        return message.venue.file_id
    end
    message = nil
    return ''
end

mattata.utf8_len = tools.utf8_len

function mattata.process_chat(chat)
    chat.id_str = tostring(chat.id)
    if chat.type == 'private' then
        return chat
    end
    if not redis:hget(
        string.format(
            'chat:%s:info',
            chat.username or chat.id
        ),
        'id'
    ) then
        print(
            string.format(
                '%s[34m[+] Added the chat %s%s to the database!%s[0m',
                string.char(27),
                chat.username and '@' or '',
                chat.username or chat.id,
                string.char(27)
            )
        )
    end
    redis:hset(
        string.format(
            'chat:%s:info',
            chat.username or chat.id
        ),
        'title',
        chat.title
    )
    redis:hset(
        string.format(
            'chat:%s:info',
            chat.username or chat.id
        ),
        'type',
        chat.type
    )
    if chat.username then
        redis:hset(
            string.format(
                'chat:%s:info',
                chat.username or chat.id
            ),
            'username',
            chat.username
        )
    end
    redis:hset(
        string.format(
            'chat:%s:info',
            chat.username or chat.id
        ),
        'id',
        chat.id
    )
    return chat
end

function mattata.process_user(user)
    if not user.id or not user.first_name then
        user = nil
        return
    end
    local new = false
    user.name = user.first_name
    if user.last_name then
        user.name = string.format(
            '%s %s',
            user.name,
            user.last_name
        )
    end
    if not redis:hget(
        string.format(
            'user:%s:info',
            user.username or user.id
        ),
        'id'
    ) then
        print(
            string.format(
                '%s[34m[+] Added the user %s%s to the database!%s[0m',
                string.char(27),
                user.username and '@' or '',
                user.username or user.id,
                string.char(27)
            )
        )
        new = true
    end
    redis:hset(
        string.format(
            'user:%s:info',
            user.username or user.id
        ),
        'name',
        user.name
    )
    redis:hset(
        string.format(
            'user:%s:info',
            user.username or user.id
        ),
        'first_name',
        user.first_name
    )
    if user.last_name then
        redis:hset(
            string.format(
                'user:%s:info',
                user.username or user.id
            ),
            'last_name',
            user.last_name
        )
    else
        redis:hdel(
            string.format(
                'user:%s:info',
                user.username or user.id
            ),
            'last_name'
        )
    end
    if user.username then
        redis:hset(
            string.format(
                'user:%s:info',
                user.username or user.id
            ),
            'username',
            user.username
        )
    else
        redis:hdel(
            string.format(
                'user:%s:info',
                user.username or user.id
            ),
            'username'
        )
    end
    redis:hset(
        string.format(
            'user:%s:info',
            user.username or user.id
        ),
        'id',
        user.id
    )
    return user, new
end

function mattata.process_message(message)
    message.text = message.text or message.caption or ''
    message.text = message.text:gsub('^/(%a+)%_', '/%1 ')
    message.is_media = mattata.is_media(message)
    message.media_type = mattata.media_type(message)
    message.file_id = mattata.file_id(message)
    message.is_service_message = mattata.is_service_message(message)
    message.service_message = mattata.service_message(message)
    message.from = mattata.process_user(message.from)
    if message.forward_from then
        message.forward_from = mattata.process_user(message.forward_from)
    elseif message.new_chat_member then
        message.new_chat_member = mattata.process_user(message.new_chat_member)
    elseif message.left_chat_member then
        message.left_chat_member = mattata.process_user(message.left_chat_member)
        local members = redis:hget(
            string.format(
                'chat:%s:info',
                message.chat.username or message.chat.id
            ),
            'members'
        ) and json.decode(
            redis:hget(
                string.format(
                    'chat:%s:info',
                    message.chat.username or message.chat.id
                ),
                'members'
            )
        ) or {}
        if members[message.left_chat_member.id] then
            members[message.left_chat_member.id] = nil
            redis:hset(
                string.format(
                    'chat:%s:info',
                    message.chat.username or message.chat.id
                ),
                'members',
                json.encode(members)
            )
            print(
                string.format(
                    '%s[31m[-] Removed %s%s from the members list for %s%s because they left the chat!%s[0m',
                    string.char(27),
                    message.left_chat_member.username and '@' or '',
                    message.left_chat_member.username or message.left_chat_member.id,
                    message.chat.username and '@' or '',
                    message.chat.username or message.chat.id,
                    string.char(27)
                )
            )
        end
    end
    message.chat = mattata.process_chat(message.chat)
    if message.forward_from_chat then
        mattata.process_chat(message.forward_from_chat)
    end
    if message.chat.type ~= 'private' and message.from and message.from.id and message.from.id ~= configuration.admins[1] then
        local members = redis:hget(
            string.format(
                'chat:%s:info',
                message.chat.username or message.chat.id
            ),
            'members'
        )
        if members then
            members = json.decode(members)
        else
            members = {}
        end
        message.from.last_spoken = os.time()
        if not members[tostring(message.from.id)] then
            print(
                string.format(
                    '%s[32m[+] Added %s%s to the members list for %s%s because they have spoken for the first time!%s[0m',
                    string.char(27),
                    message.from.username and '@' or '',
                    message.from.username or message.from.id,
                    message.chat.username and '@' or '',
                    message.chat.username or message.chat.id,
                    string.char(27)
                )
            )
        end
        members[message.from.id] = message.from
        redis:hset(
            string.format(
                'chat:%s:info',
                message.chat.username or message.chat.id
            ),
            'members',
            json.encode(members)
        )
    end
    return message
end

function mattata.is_global_admin(id)
    for k, v in pairs(configuration.admins) do
        if id == v then
            return true
        end
    end
    id = nil
    return false
end

mattata.comma_value = tools.comma_value
mattata.format_ms = tools.format_ms
mattata.round = tools.round

function mattata.get_user(input)
    input = tostring(input):match('^%@(.-)$') or tostring(input)
    local user = redis:hgetall('user:' .. input .. ':info')
    if user.username and user.username:lower() == input:lower() then
        user.type = 'private'
        user.name = user.first_name
        if user.last_name then
            user.name = user.name .. ' ' .. user.last_name
        end
        return {
            ['ok'] = true,
            ['result'] = user
        }
    end
    input = nil
    return false
end

function mattata.get_inline_help(input)
    local inline_help = {}
    local count = 1
    table.sort(plugin_list)
    for k, v in pairs(plugin_list) do
        if count > 50 then -- The bot API only accepts a maximum of 50 results.
            break
        end
        v = v:gsub('\n', ' ')
        if v:match('^/.- %- .-$') and v:lower():match(input) then
            table.insert(
                inline_help,
                {
                    ['type'] = 'article',
                    ['id'] = tostring(count),
                    ['title'] = v:match('^(/.-) %- .-$'),
                    ['description'] = v:match('^/.- %- (.-)$'),
                    ['input_message_content'] = {
                        ['message_text'] = utf8.char(8226) .. ' ' .. v:match('^(/.-) %- .-$') .. ' - ' .. v:match('^/.- %- (.-)$')
                    }
                }
            )
            count = count + 1
        end
    end
    return inline_help
end

function mattata.get_inline_list(username)
    local inline_list = {}
    local count = 1
    table.sort(inline_plugin_list)
    for k, v in pairs(inline_plugin_list) do
        if count > 50 then -- The bot API only accepts a maximum of 50 results.
            break
        end
        v = v:gsub('\n', ' ')
        table.insert(
            inline_list,
            mattata.inline_result():type('article'):id(
                tostring(count)
            ):title(
                string.format(
                    '@%s %s',
                    username,
                    v:match('^(/.-) %- .-$')
                )
            ):description(
                v:match('^/.- %- (.-)$')
            ):input_message_content(
                mattata.input_text_message_content(
                    string.format(
                        '• %s - %s\n\nTo use this command inline, you must use the syntax:\n@%s %s',
                        v:match('^(/.-) %- .-$'),
                        v:match('^/.- %- (.-)$'),
                        username,
                        v:match('^(/.-) %- .-$')
                    )
                )
            ):reply_markup(
                mattata.inline_keyboard():row(
                    mattata.row():switch_inline_query_button(
                        'Show me how!',
                        v:match('^(/.-) ')
                    )
                )
            )
        )
        count = count + 1
    end
    return inline_list
end

function mattata.get_help()
    local help = {}
    local count = 1
    table.sort(plugin_list)
    for k, v in pairs(plugin_list) do
        if v:match('^/.- %- .-$') then
            table.insert(
                help,
                utf8.char(8226) .. ' ' .. v:match('^(/.-) %- .-$')
            )
            count = count + 1
        end
    end
    return help
end

function mattata.get_chat_id(chat)
    if not chat or not mattata.get_chat(chat) then
        chat = nil
        return false
    end
    return mattata.get_chat(chat).result.id
end

function mattata.get_setting(chat_id, setting)
    return redis:hget(
        'chat:' .. chat_id .. ':settings',
        tostring(setting)
    )
end

function mattata.get_chat_members(chat_id)
    return redis:hget(
        'chat:' .. chat_id .. ':info',
        'members'
    )
end

function mattata.get_user_count()
    return #redis:keys('user:*:info')
end

function mattata.get_group_count()
    return #redis:keys('chat:*:info')
end

mattata.input_text_message_content = api.input_text_message_content
mattata.input_location_message_content = api.input_location_message_content
mattata.input_venue_message_content = api.input_venue_message_content
mattata.input_contact_message_content = api.input_contact_message_content
mattata.url_button = api.url_button
mattata.callback_data_button = api.callback_data_button
mattata.switch_inline_query_button = api.switch_inline_query_button
mattata.switch_inline_query_current_chat_button = api.switch_inline_query_current_chat_button
mattata.callback_game_button = api.callback_game_button
mattata.row = api.row
mattata.inline_keyboard = api.inline_keyboard
mattata.keyboard = api.keyboard
mattata.remove_keyboard = api.remove_keyboard
mattata.commands = tools.commands
mattata.escape_markdown = tools.escape_markdown
mattata.escape_html = tools.escape_html
mattata.escape_bash = tools.escape_bash
mattata.send_inline_article = api.send_inline_article
mattata.send_inline_photo = api.send_inline_photo
mattata.inline_result = api.inline_result

return mattata