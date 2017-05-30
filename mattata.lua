--[[
                       _   _        _
       _ __ ___   __ _| |_| |_ __ _| |_ __ _
      | '_ ` _ \ / _` | __| __/ _` | __/ _` |
      | | | | | | (_| | |_| || (_| | || (_| |
      |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|

      v23.0

      Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
      See LICENSE for details

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
local socket = require('socket')
local plugin_list = {}
local inline_plugin_list = {}

function mattata:init()
    self.info = api.info -- Set the bot's information to the object fetched from the Telegram bot API.
    self.plugins = {} -- Make a table for the bot's plugins.
    for k, v in ipairs(configuration.plugins) -- Iterate over all of the configured plugins.
    do
        local plugin = require('plugins.' .. v) -- Load each plugin.
        self.plugins[k] = plugin
        self.plugins[k].name = v
        if plugin.init -- If the plugin has an `init` function, run it.
        then
            plugin.init(
                self,
                configuration
            )
        end
        plugin.is_inline = plugin.on_inline_query
        and true
        or false -- By default, a plugin doesn't have inline functionality; but, if it does, set it to `true` appropriately.
        plugin.commands = plugin.commands
        or {} -- If the plugin hasn't got any commands configured, then set a blank table,
        -- so when it comes to iterating over the commands later on, the bot won't encounter any problems.
        if plugin.help
        then -- If the plugin has help documentation, then insert it into other tables (where necessary).
            table.insert(
                plugin_list,
                plugin.help
            )
            if plugin.is_inline
            then -- If the plugin is inline and has documentation, then insert the documentation into the `inline_plugin_list`
            -- table.
                table.insert(
                    inline_plugin_list,
                    plugin.help
                )
            end
            plugin.help = 'Usage:\n' .. plugin.help:gsub('%. (Alias)', '.\n%1') -- Make the plugin's documentation style all
            -- nicely unified, for consistency.
        end
    end
    print('Connected to the Telegram bot API!')
    print('\n\tUsername: @' .. self.info.username .. '\n\tName: ' .. self.info.name .. '\n\tID: ' .. self.info.id .. '\n')
    self.version = 'v23.0'
    if not redis:get('mattata:version')
    or redis:get('mattata:version') ~= self.version
    then -- Make necessary database changes if the version has changed.
        redis:set(
            'mattata:version',
            self.version
        )
    end
    self.last_update = self.last_update
    or 0 -- If there is no last update known, make it 0 so the bot doesn't encounter any
    -- problems when it tries to add the necessary increment.
    self.last_backup = self.last_backup
    or os.date('%V')
    self.last_cron = self.last_cron
    or os.date('%H')
    return true
end

-- Set a bunch of function aliases, for consistency and legacy compatibility.
mattata.request = api.request
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
mattata.delete_message = api.delete_message
mattata.answer_inline_query = api.answer_inline_query
mattata.send_invoice = api.send_invoice
mattata.answer_shipping_query = api.answer_shipping_query
mattata.answer_pre_checkout_query = api.answer_pre_checkout_query
mattata.send_game = api.send_game
mattata.set_game_score = api.set_game_score
mattata.get_game_high_scores = api.get_game_high_scores
mattata.input_text_message_content = api.input_text_message_content
mattata.input_location_message_content = api.input_location_message_content
mattata.input_venue_message_content = api.input_venue_message_content
mattata.input_contact_message_content = api.input_contact_message_content
mattata.url_button = api.url_button
mattata.callback_data_button = api.callback_data_button
mattata.switch_inline_query_button = api.switch_inline_query_button
mattata.switch_inline_query_current_chat_button = api.switch_inline_query_current_chat_button
mattata.callback_game_button = api.callback_game_button
mattata.pay_button = api.pay_button
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
mattata.trim = tools.trim
mattata.comma_value = tools.comma_value
mattata.format_ms = tools.format_ms
mattata.round = tools.round
mattata.symbols = tools.symbols
mattata.utf8_len = tools.utf8_len
mattata.get_linked_name = tools.get_linked_name
mattata.table_size = tools.table_size

function mattata:run(configuration, token)
-- mattata's main long-polling function which repeatedly checks the Telegram bot API for updates.
-- The objects received in the updates are then further processed through object-specific functions.
    token = token
    or configuration.bot_token
    assert(
        token,
        'You need to enter your Telegram bot API token in configuration.lua, or pass it as the second argument when using the mattata:run() function!'
    )
    local is_running = mattata.init(self) -- Initialise the bot.
    while is_running -- Perform the main loop whilst the bot is running.
    do
        local success = api.get_updates( -- Check the Telegram bot API for updates.
            20,
            self.last_update + 1,
            nil,
            json.encode(
                {
                    'message',
                    'edited_message',
                    'channel_post',
                    'edited_channel_post',
                    'inline_query',
                    'chosen_inline_result',
                    'callback_query',
                    'shipping_query',
                    'pre_checkout_query'
                }
            ),
            configuration.use_beta_endpoint
            or false
        )
        if success
        and success.result
        then
            for k, v in ipairs(success.result)
            do
                self.last_update = v.update_id
                if v.message
                then
                    if v.message.reply_to_message
                    then
                        v.message.reply = v.message.reply_to_message -- Make the `update.message.reply_to_message`
                        -- object `update.message.reply` to make any future handling easier.
                        v.message.reply_to_message = nil -- Delete the old value by setting its value to nil.
                    end
                    mattata.on_message(
                        self,
                        v.message,
                        configuration
                    )
                    if v.message.successful_payment
                    then
                        mattata.send_message(
                            configuration.admins[1],
                            json.encode(v.message)
                        )
                    end
                    if configuration.debug
                    then
                        print(
                            string.format(
                                '%s[36m[Update #%s] Message from %s to %s%s[0m',
                                string.char(27),
                                v.update_id,
                                v.message.from.id,
                                v.message.chat.id,
                                string.char(27)
                            )
                        )
                    end
                elseif v.channel_post
                then
                    if v.channel_post.reply_to_message
                    then
                        v.channel_post.reply = v.channel_post.reply_to_message
                        v.channel_post.reply_to_message = nil
                    end
                    mattata.on_message(
                        self,
                        v.channel_post,
                        configuration
                    )
                    if configuration.debug
                    then
                        print(
                            string.format(
                                '%s[37m[Update #%s] Channel post from %s%s[0m',
                                string.char(27),
                                v.update_id,
                                v.channel_post.chat.id,
                                string.char(27)
                            )
                        )
                    end
                elseif v.inline_query
                then
                    mattata.on_inline_query(
                        self,
                        v.inline_query,
                        configuration
                    )
                    if configuration.debug
                    then
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
                elseif v.callback_query
                then
                    if v.callback_query.message
                    and v.callback_query.message.reply_to_message
                    then
                        v.callback_query.message.reply = v.callback_query.message.reply_to_message
                        v.callback_query.message.reply_to_message = nil
                    end
                    mattata.on_callback_query(
                        self,
                        v.callback_query,
                        v.callback_query.message
                        or false,
                        configuration
                    )
                    if configuration.debug
                    then
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
                elseif v.pre_checkout_query
                then
                    mattata.send_message(
                        configuration.admins[1],
                        json.encode(v)
                    ) -- To be improved.
                    -- Sends the object containing payment-related info to the first configured
                    -- admin, then answers the pre checkout query.
                    mattata.answer_pre_checkout_query(
                        v.pre_checkout_query.id,
                        true
                    )
                end
                v = nil
            end
        else
            print(
                string.format(
                    '%s[31m[Error] There was an error retrieving updates from the Telegram bot API!%s[0m',
                    string.char(27),
                    string.char(27)
                )
            )
        end
        success = nil
        if self.last_backup ~= os.date('%V')
        then -- If it's been a week since the last backup, perform another backup.
            self.last_backup = os.date('%V') -- Set the last backup time to now, since we're
            -- now performing one!
            print(
                io.popen('./backup.sh'):read('*all')
            )
        end
        if self.last_cron ~= os.date('%H')
        then -- Perform hourly CRON jobs.
            self.last_cron = os.date('%H')
            for i = 1, #self.plugins
            do
                local plugin = self.plugins[i]
                if plugin.cron
                then
                    local success, res = pcall(
                        function()
                            plugin.cron(
                                self,
                                configuration
                            )
                        end
                    )
                    if not success
                    then
                        mattata.exception(
                            self,
                            res,
                            'CRON: ' .. i,
                            configuration.log_chat
                        )
                    end
                else
                    plugin = nil
                end
            end
        end
        collectgarbage()
    end
    redis:bgsave() -- Perform a background save of the redis database.
    print('mattata is shutting down...')
end

function mattata:on_message(message, configuration)
    if not message -- If the `message` object is nil, then we'll ignore it.
    or message.date < os.time() - 10 -- We don't want to process old messages, so anything
    -- older than the current system time (giving it a leeway of 10 seconds).
    or not message.from -- If the message is coming from a channel with no `message.from`
    -- object, this means that they haven't enabled the `Sign Messages` option in the channel
    -- settings. We'll ignore this so it doesn't cause any problems with plugins which rely
    -- on the values in the `message.from` object.
    or (
        message.from
        and message.from.id
        and message.chat
        and message.chat.id
        and (
            redis:get('global_blacklist:' .. message.from.id) -- Check if the user is globally
            -- blacklisted from using the bot.
            or redis:get('group_blacklist:' .. message.chat.id .. ':' .. message.from.id) -- Check
            -- if the user is blacklisted from using the bot in the current chat.
        )
    )
    then
    -- If the message was forwarded (from a user/channel, we'll ignore it because it probably
    -- wasn't intended for the bot.
        message = nil -- Free the `message` object from the memory.
        return false
    end
    message.text = message.text
    or message.caption
    or '' -- Ensure there is always a value assigned to message.text.
    if redis:get('blacklisted_chats:' .. message.chat.id) -- Check if the chat is blacklisted.
    then
        mattata.leave_chat(message.chat.id) -- If it's blacklisted, leave the chat.
        return false
    elseif message.from.username
    and redis:hget(
        'afk:' .. message.chat.id .. ':' .. message.from.id,
        'since'
    )
    and not mattata.is_plugin_disabled(
        'afk',
        message
    )
    and not message.text:match('^[/!#]afk')
    and not message.text:lower():match('^i?\'?m? ?back.?$')
    and not message.text:lower():match('^i?\'?l?l? ?brb.?$')
    then
        local since = os.time() - tonumber(
            redis:hget(
                'afk:' .. message.chat.id .. ':' .. message.from.id,
                'since'
            )
        )
        redis:hdel(
            'afk:' .. message.chat.id .. ':' .. message.from.id,
            'since'
        )
        redis:hdel(
            'afk:' .. message.chat.id .. ':' .. message.from.id,
            'note'
        )
        mattata.send_message(
            message.chat.id,
            message.from.first_name .. ' has returned, after being AFK for ' .. mattata.format_time(since) .. '.'
        )
    elseif message.text:match('@[%w_]+') -- If a user gets mentioned, check to see if they're AFK.
    then
        local username = message.text:match('@([%w_]+)')
        local success = mattata.get_user(username)
        if success
        and success.result
        and redis:hexists(
            'afk:' .. message.chat.id .. ':' .. success.result.id,
            'since'
        )
        then -- If all the checks are positive, the mentioned user is AFK, so we'll tell the
        -- person mentioning them that this is the case!
            mattata.send_reply(
                message,
                success.result.first_name .. ' is currently AFK!'
            )
        end
    end
    message.text = message.text:match('^[/!#]start (.*)$')
    or message.text -- Allow deep-linking through the /start command
    local language = require(
        'languages.' .. mattata.get_user_language(message.from.id)
    )
    self.info.nickname = redis:get('chat:' .. message.chat.id .. ':name')
    or self.info.name -- If the chat doesn't have a custom nickname for the bot to respond by, we'll
    -- stick with the default one that was set through @BotFather.
    message = mattata.process_message(message) -- Process the message.
    message.reply = message.reply
    and mattata.process_message(message.reply) -- If there's a reply, process that too.
    or nil
    message.from.first_name = redis:get('nick:' .. message.from.id)
    or message.from.first_name -- If the user has a custom nickname, set that as their preferred name.
    message.from.last_name = message.from.last_name
    or nil
    message.from.name = message.from.last_name
    and message.from.first_name .. ' ' .. message.from.last_name
    or message.from.first_name -- Set the message.from.name value to a concatenated variation of the
    -- user's existing name and, if applicable, last name.
    if message.forward_from
    or message.forward_from_chat
    then
        return -- We don't want to process forwarded messages any further!
    elseif message.text
    and message.chat
    and message.chat.id
    and message.reply
    and message.reply.from
    and message.reply.from.id
    and message.reply.from.id == self.info.id
    and redis:get('action:' .. message.chat.id .. ':' .. message.reply.message_id)
    then
    -- If an action was saved for the replied-to message (as part of a multiple step command), then
    -- we'll get information about the action.
        local action = 'action:' .. message.chat.id .. ':' .. message.reply.message_id
        message.text = redis:get(action) .. ' ' .. message.text -- Concatenate the saved action's command
        -- with the new `message.text`.
        message.reply = nil -- This caused some issues with administrative commands which would
        -- prioritise replied-to users over users given by arguments.
        redis:del(action) -- Delete the action for this message, since we've done what we needed to do
        -- with it now.
    end
    if message.from.language_code
    then
        if not mattata.does_language_exist(message.from.language_code)
        then
            if not redis:sismember(
                'mattata:missing_languages',
                message.from.language_code
            ) -- If we haven't stored the missing language file, add it into the database.
            then
                redis:sadd(
                    'mattata:missing_languages',
                    message.from.language_code
                )
            end
            if message.text == '/start'
            and message.chat.type == 'private'
            then
                mattata.send_message(
                    message.chat.id,
                    'It appears that I haven\'t got a translation in your language (' .. message.from.language_code .. ') yet. If you would like to voluntarily translate me into your language, please join <a href="https://t.me/mattataDev">my official development group</a>. Thanks!',
                    'html'
                )
            end
        elseif redis:sismember(
            'mattata:missing_languages',
            message.from.language_code
        )
        -- If the language file is found, yet it's recorded as missing in the database, it's probably
        -- new, so it is deleted from the database to prevent confusion when processing this list!
        then
            redis:srem(
                'mattata:missing_languages',
                message.from.language_code
            )
        end
    end
    if message.from
    and message.from.language_code
    and (
        not redis:hget(
            string.format(
                'user:%s:info',
                message.from.username
                or message.from.id
            ),
            'language_code'
        )
        or redis:hget(
            string.format(
                'user:%s:info',
                message.from.username
                or message.from.id
            ),
            'language_code'
        ) ~= message.from.language_code
    )
    then
        redis:hset(
            string.format(
                'user:%s:info',
                message.from.username
                or message.from.id
            ),
            'language_code',
            message.from.language_code
        )
        print('Updated language to ' .. message.from.language_code .. ' for ' .. (message.from.username and '@' .. message.from.username or message.from.id) .. '!')
    end
    message.chat.title = message.chat.title
    or message.from.name -- If the chat type is private then there isn't going to be a value for `title`
    -- in the `message.chat` object, so we'll use the name of the message sender instead.
    local is_command = false -- A boolean value to decide later on, whether the message is still being
    -- handled or not.
    if redis:sismember(
        'chat:' .. message.chat.id .. ':muted_users',
        tostring(message.from.id)
    )
    then
        print('Message deleted from ' .. message.from.id .. ' in ' .. message.chat.id)
        return mattata.delete_message(
            message.chat.id,
            message.message_id
        )
    end
    local msg_count = tonumber(
        redis:get('antispam:' .. message.chat.id .. ':' .. message.from.id) -- Check to see if the user
        -- has already sent 1 or more messages to the current chat, in the past 5 seconds.
    )
    or 1 -- If this is the first time the user has posted in the past 5 seconds, we'll make it 1 accordingly.
    redis:setex(
        'antispam:' .. message.chat.id .. ':' .. message.from.id,
        5, -- Set the time to live to 5 seconds.
        msg_count + 1 -- Increase the current message count by 1.
    )
    if msg_count == 7 -- If the user has sent 7 messages in the past 5 seconds, send them a warning.
    and not mattata.is_global_admin(message.from.id)
    then
    -- Don't run the antispam plugin if the user is configured as a global admin in `configuration.lua`.
        mattata.send_reply( -- Send a warning message to the user who is at risk of being blacklisted for sending
        -- too many messages.
            message,
            string.format(
                'Hey %s, please don\'t send that many messages, or you\'ll be forbidden to use me for 24 hours!',
                message.from.username
                and '@' .. message.from.username
                or message.from.name
            )
        )
    elseif messages == 15 -- If the user has sent 15 messages in the past 5 seconds, blacklist them globally from
    -- using the bot for 24 hours.
    and not mattata.is_global_admin(message.from.id) -- Don't blacklist the user if they are configured as a global
    -- admin in `configuration.lua`.
    then
        redis:setex(
            'global_blacklist:' .. message.from.id,
            86400,
            true
        )
        return mattata.send_reply(
            message,
            string.format(
                'Sorry, %s, but you have been blacklisted from using me for the next 24 hours because you have been spamming!',
                message.from.username
                and '@' .. message.from.username
                or message.from.name
            )
        )
    elseif message.chat.type == 'supergroup'
    and message.sticker
    and message.file_id
    then
        -- Process each sticker to see if they are one of the configured, command-performing stickers.
        for k, v in pairs(configuration.stickers.ban)
        do
            if message.file_id == v
            then
                message.text = '/ban'
            end
        end
        for k, v in pairs(configuration.stickers.warn)
        do
            if message.file_id == v
            then
                message.text = '/warn'
            end
        end
        for k, v in pairs(configuration.stickers.kick)
        do
            if message.file_id == v
            then
                message.text = '/kick'
            end
        end
    end
    if not mattata.is_plugin_disabled(
        'github',
        message
    )
    and message.text
    and message.text:match('h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/[A-Z%-%_a-z]+/[A-Z%-%_a-z]+')
    and message.entities
    then
        for k, v in pairs(message.entities)
        do
            if v.type == 'url'
            and message.text:match('(h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/[A-Z%-%_a-z]+/[A-Z%-%_a-z]+)'):len() == v.length
            and not https.request(
                message.text:match('(h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/[A-Z%-%_a-z]+/[A-Z%-%_a-z]+)')
            ):lower():match('%<title%>page not found')
            then
                message.text = string.format(
                    '/github %s %s',
                    message.text:match('h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/([A-Z%-%_a-z]+)/[A-Z%-%_a-z]+'),
                    message.text:match('h?t?t?p?s?:?/?/?w?w?w?%.?github%.com/[A-Z%-%_a-z]+/([A-Z%-%_a-z]+)')
                )
            end
        end
    end
    message.text = message.text:lower():match('%*insert a?n? ?.- gif[ %*]')
    and '/gif ' .. message.text:lower():match('%*insert a?n? ?(.-) gif[ %*]')
    or message.text
    if message.text == '/exec'
    and message.reply
    and message.reply.text
    then
        message.text = '/exec ' .. message.reply.text
    end
    if mattata.is_global_admin(message.from.id)
    and message.text:match(' %-%-switch%-chat$')
    then
        message.text = message.text:match('^(.-) %-%-switch%-chat$')
        local old_id = message.from.id
        message.from.id = message.chat.id
        message.chat.id = old_id
    end
    if message.text:match('^%-%d+%_%a+$')
    and message.chat.type == 'private'
    then
        local chat_id, action = message.text:match('^(%-%d+)%_(%a+)$')
        if action == 'rules'
        and redis:hget(
            string.format(
                'chat:%s:settings',
                chat_id
            ),
            'use administration'
        )
        then
            local administration = require('plugins.administration')
            return mattata.send_message(
                message.chat.id,
                administration.get_rules(chat_id),
                'markdown'
            )
        end
    end
    if message.new_chat_member
    then
        if message.new_chat_member.id == self.info.id
        then
            return mattata.send_message(
                message.chat.id,
                string.format(
                    'My name is %s and I\'m here to help. If you\'re an administrator, use /plugins to choose which features you want to enable in this group and use /administration to set up my administrative functionality. For more information, use /help.',
                    self.info.nickname
                )
            )
        end
        local administration = require('plugins.administration')
        administration.on_new_chat_member(
            self,
            message,
            language
        )
    end
    if (
        message.text:lower():match('^i?\'?l?l? ?brb.?$')
        and not redis:hget(
            'afk:' .. message.chat.id .. ':' .. message.from.id,
            'since'
        )
    )
    then
        message.text = '/afk'
    end
    if message.chat.type == 'supergroup'
    and redis:hget(
        'chat:' .. message.chat.id .. ':settings',
        'use administration'
    )
    then
        if not mattata.is_group_admin(
            message.chat.id,
            self.info.id,
            true
        )
        then
            redis:hdel(
                'chat:' .. message.chat.id .. ':settings',
                'use administration'
            )
        end
        local administration = require('plugins.administration')
        administration.process_message(
            self,
            message,
            language
        )
    end
    if message.chat.type ~= 'private'
    and not mattata.is_plugin_disabled(
        'statistics',
        message
    )
    then
        local statistics = require('plugins.statistics')
        statistics.process_message(
            self,
            message,
            configuration,
            language,
            is_command
        )
    end
    if mattata.is_global_admin(message.from.id)
    and message.text:match('^/addresp .-\n.-$')
    then
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
        )
        then
            conversation = json.decode(
                redis:hget(
                    'ai',
                    message.text:lower():match('^/addresp (.-)\n.-$')
                )
            )
            local is_known = false
            local count = 1
            for k, v in pairs(conversation.responses)
            do
                if count > 19
                then
                    is_known = true -- Prevent too many responses from being cached!
                end
                if v == response
                then
                    is_known = true
                end
                count = count + 1
            end
            if is_known == false
            then
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
    elseif message.chat.type ~= 'private'
    and message.text:match('^%#%a+')
    and mattata.get_setting(
        message.chat.id,
        'use administration'
    )
    then
        local trigger = message.text:match('^(%#%a+)')
        local custom_commands = redis:hkeys(
            string.format(
                'administration:%s:custom',
                message.chat.id
            )
        )
        if custom_commands
        then
            for k, v in ipairs(custom_commands)
            do
                if trigger == v
                then
                    local value = redis:hget(
                        string.format(
                            'administration:%s:custom',
                            message.chat.id
                        ),
                        trigger
                    )
                    if value
                    then
                        return mattata.send_message(
                            message.chat.id,
                            value
                        )
                    end
                end
            end
        end
    end
    for _, plugin in ipairs(self.plugins)
    do
        local plugins = plugin.commands
        or {}
        for i = 1, #plugins
        do
            local command = plugin.commands[i]
            if message.text:match(command)
            then
                is_command = true
                if message.chat.type ~= 'private'
                and not mattata.is_plugin_disabled(
                    'commandstats',
                    message
                )
                then
                    local commandstats = require('plugins.commandstats')
                    commandstats.process_message(
                        self,
                        message,
                        configuration,
                        language,
                        is_command
                    )
                end
                if not plugin.on_message
                then
                    plugin = nil
                    return false
                elseif (
                    plugin.name == 'administration'
                    and not redis:hget(
                        string.format(
                            'chat:%s:settings',
                            message.chat.id
                        ),
                        'use administration'
                    )
                    and not message.text:match('^/administration')
                    and not message.text:match('^/administration%@' .. self.info.username)
                    and not message.text:match('^/groups')
                    and not message.text:match('^/groups%@' .. self.info.username)
                )
                or (
                    plugin.name ~= 'administration'
                    and mattata.is_plugin_disabled(
                        plugin.name,
                        message
                    )
                )
                then
                    if message.chat.type ~= 'private'
                    and not redis:get(
                        string.format(
                            'chat:%s:dismiss_disabled_message:%s',
                            message.chat.id,
                            plugin.name
                        )
                    )
                    then
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
                            mattata.inline_keyboard()
                            :row(
                                mattata.row()
                                :callback_data_button(
                                    'Dismiss',
                                    'plugins:' .. message.chat.id .. ':dismiss_disabled_message:' .. plugin.name
                                )
                                :callback_data_button(
                                    'Enable',
                                    'plugins:' .. message.chat.id .. ':enable_via_message:' .. plugin.name
                                )
                            )
                        )
                    end
                    return
                end
                if plugin.process_message
                and plugin.name ~= 'administration'
                and plugin.name ~= 'statistics'
                and plugin.name ~= 'commandstats'
                then
                    local success, result = pcall(
                        function()
                            plugin.process_message(
                                self,
                                message,
                                configuration,
                                language,
                                is_command
                            )
                        end
                    )
                    if not success
                    then
                        plugin = nil
                        success = nil
                        return false
                    end
                end
                local success, result = pcall(
                    function()
                        return plugin.on_message(
                            self,
                            message,
                            configuration,
                            language
                        )
                    end
                )
                if not success
                then
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
                end
                if mattata.get_setting(
                    message.chat.id,
                    'delete commands'
                )
                and is_command
                then
                    mattata.delete_message(
                        message.chat.id,
                        message.message_id
                    )
                end
                return true
            end
        end
    end
    if not mattata.is_plugin_disabled(
        'captionbotai',
        message
    )
    and (
        message.photo
        or (
            message.reply
            and message.reply.photo
        )
    )
    then
        if message.reply
        then
            message = message.reply
        end
        if message.text
        :lower()
        :match('^wh?at .- th[ia][st].-')
        or message.text
        :lower()
        :match('^who .- th[ia][st].-')
        then
            local captionbotai = require('plugins.captionbotai')
            captionbotai.on_message(
                self,
                message,
                configuration,
                language
            )
        end
    end
    if mattata.is_global_admin(message.from.id)
    and message.chat.id == configuration.bug_reports_chat
    and message.reply
    and message.reply.forward_from
    and not message.text:match('^[/!#]')
    then
        mattata.send_message(
            message.reply.forward_from.id,
            string.format(
                'Message from the developer regarding bug report #%s:\n<pre>%s</pre>',
                message.reply.forward_date,
                mattata.escape_html(message.text)
            ),
            'html'
        )
    elseif not message.text:match('^Cancel$')
    and not message.text:match('^/?s/.-/.-/?$')
    and not message.photo
    and not message.text:match('^[!/#]')
    and not message.forward_from
    and (
        message.text:lower():gsub('%W', '') ~= ''
    )
    then
        if mattata.is_plugin_disabled(
            'ai',
            message
        )
        then
            if (
                message.text:lower():match('^' .. self.info.nickname:lower() .. '.? .-$')
                or message.text:match('^.-%,? ' .. self.info.nickname:lower() .. '%??%.?%!?$')
                or message.chat.type == 'private'
                or (
                    message.reply
                    and message.reply.from.id == self.info.id
                )
            )
            and message.text:lower() ~= self.info.nickname:lower()
            and not redis:get('ai_notify:' .. message.chat.id .. ':' .. message.from.id)
            then
                redis:set(
                    'ai_notify:' .. message.chat.id .. ':' .. message.from.id,
                    true
                ) -- Mark the user as notified.
                mattata.send_reply(
                    message,
                    'Sorry pal, but my AI is switched off in this chat. This is the only time I\'m going to remind you of this, so be sure to remember (it\'ll save you from looking crazy next time!) If you believe this is a mistake, you should contact a group admin as soon as possible!'
                )
            end
        else
            if (
                message.text:lower():match('^' .. self.info.nickname:lower() .. '.? .-$')
                or message.text:match('^.-%,? ' .. self.info.nickname:lower() .. '%??%.?%!?$')
                or message.chat.type == 'private'
                or (
                    message.reply
                    and message.reply.from.id == self.info.id
                )
            )
            and message.text:lower() ~= self.info.nickname:lower()
            then
                message.text = message.text:lower():gsub(self.info.nickname:lower(), '')
                local ai = require('plugins.ai')
                ai.on_message(
                    self,
                    message,
                    configuration,
                    language
                )
            elseif message.text:lower() == self.info.nickname:lower()
            then
                mattata.send_chat_action(message.chat.id)
                mattata.send_reply(
                    message,
                    'Yes?'
                )
            end
        end
    end
    if configuration.respond_to_misc
    and not is_command
    and not mattata.get_setting(
        message.chat.id,
        'misc responses'
    ) -- Ensure the AI functionality hasn't been turned off, since the user probably
    -- won't want the miscellaneous responses if it has been.
    then
        mattata.on_message_misc(
            self,
            message,
            configuration
        )
    end
    if ( -- If a user executes a command and it's not recognised, provide a response
    -- explaining what's happened and how it can be resolved.
        message.text:match('^[!/#]')
        and message.chat.type == 'private'
        and not is_commmand
    )
    or (
        message.chat.type ~= 'private'
        and message.text:match('^[!/#]%a+@' .. self.info.username)
        and not is_command
    )
    then
        mattata.send_reply(
            message,
            'Sorry, I don\'t understand that command.\nTip: Use /help to discover what else I can do!'
        )
    end
    message = nil
    return true
end

function mattata:on_message_misc(message, configuration)
    local matches = {
        ['^what the fuck did you just fucking say about me%??$'] = 'Um, ' .. message.from.name .. '? What the fuck did you just fucking say about me, you little bitch? I\'ll have you know I graduated top of my class in the Navy Seals, and I\'ve been involved in numerous secret raids on Al-Quaeda, and I have over 300 confirmed kills. I am trained in gorilla warfare and I\'m the top sniper in the entire US armed forces. You are nothing to me but just another target. I will wipe you the fuck out with precision the likes of which has never been seen before on this Earth, mark my fucking words. You think you can get away with saying that shit to me over the Internet? Think again, fucker. As we speak I am contacting my secret network of spies across the USA and your IP is being traced right now so you better prepare for the storm, maggot. The storm that wipes out the pathetic little thing you call your life. You\'re fucking dead, kid. I can be anywhere, anytime, and I can kill you in over seven hundred ways, and that\'s just with my bare hands. Not only am I extensively trained in unarmed combat, but I have access to the entire arsenal of the United States Marine Corps and I will use it to its full extent to wipe your miserable ass off the face of the continent, you little shit. If only you could have known what unholy retribution your little "clever" comment was about to bring down upon you, maybe you would have held your fucking tongue. But you couldn\'t, you didn\'t, and now you\'re paying the price, you goddamn idiot. I will shit fury all over you and you will drown in it. You\'re fucking dead, kiddo.',
        ['^gr8 b8,? m8$'] = 'Gr8 b8, m8. I rel8, str8 appreci8, and congratul8. I r8 this b8 an 8/8. Plz no h8, I\'m str8 ir8. Cre8 more, can\'t w8. We should convers8, I won\'t ber8, my number is 8888888, ask for N8. No calls l8 or out of st8. If on a d8, ask K8 to loc8. Even with a full pl8, I always have time to communic8 so don\'t hesit8.',
        ['^bone? appetite?%??!?%.?$'] = {
            'Bone apple tea, ' .. message.from.name .. '!',
            'Bone app the teeth, ' .. message.from.name .. '!',
            'Boney African feet, ' .. message.from.name .. '!',
            'Bong asshole sneeze, ' .. message.from.name .. '!'
        },
        ['^y?o?u a?re? a ?p?r?o?p?e?r? fucc?k?boy?i?%??!?%.?$'] = message.from.name .. ', I am writing to you on this fateful day to inform you of a tragic reality. While it is unfortunate that I must be the one to let you know, it is for the greater good that this knowledge is made available to you as soon as possible. m8. u r a proper fukboy.',
        ['^top%s?kek.?$'] = 'Toppest of keks!',
        ['content cop'] = 'SAY THE "N" WORD ' .. message.from.name:upper() .. '!',
        ['tana mong[eo][ao][us]e?'] = 'SAY THE "N" WORD ' .. message.from.name:upper() .. '!',
        ['good night'] = 'Good night, ' .. message.from.name .. '. Sleep well! ' .. utf8.char(128516),
        ['good morning?'] = 'Good morning, ' .. message.from.name .. '! Did you sleep well? ' .. utf8.char(9786),
        ['^[ia]\'?m back.?$'] = 'Welcome back, ' .. message.from.name .. '!',
        ['winrar'] = 'Please note that WinRAR is not free software. After a 40 day trial period you must either buy a license or remove it from your computer.',
        [utf8.char(127814)] = utf8.char(127825),
        [utf8.char(127825)] = utf8.char(127814),
        ['^nsa$'] = utf8.char(128065),
        ['ric?[ck] harr?iss?on'] = 'I\'m Rick Harrison, and this is my pawn shop. I work here with my old man and my son, Big Hoss. Everything in here has a story and a price. One thing I\'ve learned after 21 years – you never know WHAT is gonna come through that door.',
        ['haramba?e'] = '*gets dick out*',
        ['owo'] = 'OwO, what\'s THIS?',
        ['trump'] = 'Trump? He\'s not MY president! ' .. utf8.char(128560),
        ['pennis'] = '... and also dicke and balls?',
        ['^stop$'] = 'stop',
        ['^no u$'] = 'fight me boi',
        ['fritzypoo'] = 'SORRY MUM, IT\'S A FRITZISM',
        ['vicar'] = 'fml not this again *unzips jeans*',
        ['catholic priests?'] = 'pretty sure you mean boy diddlers m8',
        ['vegan'] = 'nuuuuu i dun like vegans xdd',
        ['^fritzy$'] = 'poo',
        ['^gay$'] = 'I fully support LGBTQ+ rights! You should too, ' .. message.from.name .. '! ' .. utf8.char(127987) .. utf8.char(8205) .. utf8.char(127752)
    }
    for trigger, response in pairs(matches)
    do
        if type(response) == 'table'
        then
            math.randomseed(
                socket.gettime()
            )
            math.random()
            math.random()
            math.random()
            -- Seed and "pop" some random numbers to increase the chances of the results
            -- ACTUALLY being random.
            response = response[math.random(#response)]
        end
        if message.text
        :lower()
        :match(trigger)
        then
            return mattata.send_message(
                message.chat.id,
                '<pre>' .. mattata.escape_html(response) .. '</pre>',
                'html'
            )
        end
    end
    if message.text:lower():match('^w?h?y so salty%??!?%.?$')
    then
        return mattata.send_sticker(
            message.chat.id,
            'BQADBAADNQIAAlAYNw2gRrzQfFLv9wI'
        )
    elseif message.text:lower():match('^do you have the time,? to listen to me whine%??$')
    then
        return mattata.send_sticker(
            message.chat.id,
            'BQADBAADOwIAAlAYNw0I9ggFrg4HigI'
        )
    elseif message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? wh?at time is it.?$')
    or message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? wh?at%\'?s the time.?$')
    then
        message.text = '/time'
        return mattata.on_message(
            self,
            message,
            configuration
        )
    elseif message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? how do i .-$')
    then
        message.text = '/google how do i ' .. message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? how do i (.-)$')
        return mattata.on_message(
            self,
            message,
            configuration
        )
    elseif message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? search %a+ for %"?%\'?.-%"?%\'?$')
    then
        local service, query = message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? search (%a+) for %"?%\'?(.-)%"?%\'?$')
        if service ~= 'youtube'
        and service ~= 'bing'
        and service ~= 'google'
        and service ~= 'flickr'
        and service ~= 'itunes'
        then
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
    elseif message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? who is .-$')
    or message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? wh?at is .-$')
    or message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? who are .-$')
    or message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? what are .-$')
    then
        message.text = '/ddg ' .. message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? (.-)$')
        return mattata.on_message(
            self,
            message,
            configuration
        )
    elseif message.text:lower():match('^show me message .-%.?%!?$')
    and message.chat.type == 'supergroup'
    then
        local message_id = message.text:lower():match('ge .-%.?%!?$')
        message_id = mattata.trim(message_id):gsub('number', '')
        if tonumber(message_id) == nil
        then
            return
        end
        local user = message.from.first_name
        if message.from.username
        then
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
    elseif message.text:lower() == 'pek'
    or message.text:lower():match('trash dove')
    then
        return mattata.send_document(
            message.chat.id,
            'CgADBAADqwADEbgxUVfN63j_mEYYAg'
        )
    elseif message.text:lower():match('make admin')
    or message.text:lower():match('make %a+ an admin')
    or message.text:lower():match('make %a+ admin')
    then
        return mattata.send_document(
            message.chat.id,
            'CgADBAADFwADJ5WxUim0qGqr-gYQAg'
        )
    elseif message.text:lower() == 'coo'
    then
        return mattata.send_photo(
            message.chat.id,
            'AgADBAAD46gxG6e3EVHYSQNx3Fq-7x8-aRkABONfdSHFUmyNx_oDAAEC'
        )
    elseif message.text:lower():match('^happy new year%.?%??%!?$')
    then
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
        ).month == 1
        then
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
    elseif message.text:lower():match('^' .. self.info.nickname:lower() .. ' what.?s? the weather')
    and not message.text:lower():match('in')
    then
        message.text = '/weather'
        return mattata.on_message(
            self,
            message,
            configuration
        )
    elseif message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? .- or .-%?$')
    and message.text:lower():len() < 50
    then
        local choices = {
            message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? (.-) or .-%??$'),
            message.text:lower():match('^' .. self.info.nickname:lower() .. '%,? .- or (.-)%??$')
        }
        return mattata.send_reply(
            message,
            choices[math.random(#choices)]
        )
    elseif message.reply
    and message.reply.text
    and message.text:lower():match('^wh?at would ' .. self.info.nickname:lower() .. ' say%??%.?%!?$')
    and not mattata.is_plugin_disabled(
        'ai',
        message
    )
    then
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

function mattata:on_inline_query(inline_query, configuration)
    if not inline_query.from
    or redis:get('global_blacklist:' .. inline_query.from.id)
    then
        inline_query = nil
        return false
    end
    local language = require(
        'languages.' .. mattata.get_user_language(inline_query.from.id)
    )
    inline_query.offset = inline_query.offset
    and tonumber(inline_query.offset)
    or 0
    for _, plugin in ipairs(self.plugins)
    do
        local plugins = plugin.commands
        or {}
        for i = 1, #plugins
        do
            local command = plugin.commands[i]
            if not inline_query
            then
                inline_query = nil
                return false
            end
            if inline_query.query:match(command)
            and plugin.on_inline_query
            then
                local success, result = pcall(
                    function()
                        return plugin.on_inline_query(
                            self,
                            inline_query,
                            configuration,
                            language
                        )
                    end
                )
                if not success
                then
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
                    return false
                elseif not result
                then
                    return api.answer_inline_query(
                        inline_query.id,
                        api.inline_result()
                        :id()
                        :type('article')
                        :title(configuration.errors.results)
                        :description(plugin.help)
                        :input_message_content(
                            api.input_text_message_content(plugin.help)
                        )
                    )
                end
            end
        end
    end
    if not inline_query.query
    or inline_query.query:gsub('%s', '') == ''
    then
        local offset = inline_query.offset
        and tonumber(inline_query.offset)
        or 0
        local list = mattata.get_inline_list(
            self.info.username,
            offset
        )
        if #list == 0
        then
            return mattata.send_inline_article(
                inline_query.id,
                'No more results found!',
                'There were no more inline features found. Use @' .. self.info.username .. ' <query> to search for more information about commands matching the given search query.'
            )
        end
        return mattata.answer_inline_query(
            inline_query.id,
            json.encode(list),
            0,
            false,
            tostring(offset + 50)
        )

    end
    local help = require('plugins.help')
    return help.on_inline_query(
        self,
        inline_query,
        configuration,
        language
    )
end

function mattata:on_callback_query(callback_query, message, configuration)
    local language = require(
        'languages.' .. mattata.get_user_language(callback_query.from.id)
    )
    if redis:get('global_blacklist:' .. callback_query.from.id)
    then
        callback_query = nil
        return false
    elseif message
    then
        if message.reply
        and message.chat.type ~= 'channel'
        and callback_query.from.id ~= message.reply.from.id
        and not callback_query.data:match('^game:')
        and not mattata.is_global_admin(callback_query.from.id)
        then
            return mattata.answer_callback_query(
                callback_query.id,
                string.format(
                    'Only %s can use this!',
                    message.reply.from.first_name
                )
            )
        end
    end
    for _, plugin in ipairs(self.plugins)
    do
        if plugin.name == callback_query.data:match('^(.-):.-$')
        and plugin.on_callback_query
        then
            callback_query.data = callback_query.data:match('^%a+:(.-)$')
            if not callback_query.data
            then
                plugin = nil
                callback_query = nil
                return false
            end
            local success, result = pcall(
                function()
                    return plugin.on_callback_query(
                        self,
                        callback_query,
                        callback_query.message
                        or false,
                        configuration,
                        language
                    )
                end
            )
            if not success
            then
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
                return false
            end
        end
    end
end

-----------------------------------------
--- Telegram bot API method functions ---
-----------------------------------------

function mattata.get_me(token)
    token = token
    or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getMe',
            token
        )
    )
end

-- https://core.telegram.org/bots/api#getupdates
function mattata.get_updates(timeout, offset, token)
    token = token
    or configuration.bot_token
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

-- https://core.telegram.org/bots/api#sendmessage
function mattata.send_message(message, text, parse_mode, disable_web_page_preview, disable_notification, reply_id, reply_markup, token, remove_keyboard)
    return api.send_message(
        message,
        text,
        parse_mode,
        disable_web_page_preview,
        disable_notification,
        reply_id,
        remove_keyboard
        and '{"remove_keyboard":true}'
        or reply_markup,
        token
    )
end

-- A variant of `mattata.send_message()`, optimised for sending a message as a reply.
function mattata.send_reply(message, text, parse_mode, disable_web_page_preview, reply_markup, token)
    local success = api.send_message(
        message,
        text,
        parse_mode,
        disable_web_page_preview,
        false,
        message.message_id,
        reply_markup
        or '{"remove_keyboard":true}',
        token
    )
    if not success
    then
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

function mattata.get_chat(chat_id, token)
    local success = api.get_chat(
        chat_id,
        token
    )
    if success
    and success.result
    and success.result.type
    and success.result.type == 'private'
    then
        mattata.process_user(success.result)
    elseif success
    and success.result
    then
        mattata.process_chat(success.result)
    end
    return success
end

function mattata.is_plugin_disabled(plugin, message)
    if type(message) == 'table'
    then
        message = message.chat.id
    end
    if redis:hget(
        string.format(
            'chat:%s:disabled_plugins',
            message
        ),
        plugin
    ) == 'true'
    and plugin ~= 'plugins'
    then
        return true
    end
    return false
end

function mattata.get_redis_hash(k, v)
    return string.format(
        'chat:%s:%s',
        type(k) == 'table'
        and k.chat.id
        or k,
        v
    )
end

function mattata.get_user_redis_hash(k, v)
    return string.format(
        'user:%s:%s',
        type(k) == 'table'
        and k.id
        or k,
        v
    )
end

function mattata.get_word(str, i)
    if not str
    then
        return false
    end
    local n = 1
    for word in str:gmatch('%g+')
    do
        i = i
        or 1
        if n == i
        then
            return word
        end
        n = n + 1
    end
    return false
end

function mattata.input(s)
    if not s
    then
        return false
    end
    if s:lower():match('^mattata search %a+ for .-$')
    then
        return s:lower():match('^mattata search %a+ for (.-)$')
    elseif not s:lower():match('^[%%/%%!%%$%%^%%?%%&%%%%]')
    then
        return s
    end
    local input = s:find(' ')
    if not input
    then
        return false
    end
    return s:sub(input + 1)
end

function mattata:exception(err, message, log_chat)
    local output = string.format(
        '[%s]\n%s: %s\n%s\n',
        os.date('%X'),
        self.info.username,
        mattata.escape_html(err)
        or '',
        mattata.escape_html(message)
    )
    if log_chat
    then
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
    if mattata.is_global_admin(chat_id)
    or mattata.is_global_admin(user_id)
    then
        return true
    elseif not is_real_admin
    and mattata.is_group_mod(
        chat_id,
        user_id
    )
    then
        return true
    end
    local admins = mattata.get_chat_administrators(chat_id)
    if not admins
    then
        return false
    end
    for _, admin in ipairs(admins.result)
    do
        if admin.user.id == user_id
        then
            return true
        end
    end
    chat_id = nil
    user_id = nil
    is_real_admin = nil
    return false
end

function mattata.is_group_mod(chat_id, user_id)
    if not chat_id
    or not user_id
    then
        return false
    elseif redis:sismember(
        'administration:' .. chat_id .. ':mods',
        user_id
    )
    then
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
    if user.status == 'creator'
    then
        return true
    end
    chat_id = nil
    user_id = nil
    return false
end

function mattata.is_service_message(message)
    if message.new_chat_member
    or message.left_chat_member
    or message.new_chat_title
    or message.new_chat_photo
    or message.delete_chat_photo
    or message.group_chat_created
    or message.supergroup_chat_created
    or message.channel_chat_created
    or message.migrate_to_chat_id
    or message.migrate_from_chat_id
    or message.pinned_message
    or message.successful_paymentsuccessful_payment
    then
        return true
    end
    message = nil
    return false
end

function mattata.service_message(message)
    if message.new_chat_member
    then
        return 'new_chat_member'
    elseif message.left_chat_member
    then
        return 'left_chat_member'
    elseif message.new_chat_title
    then
        return 'new_chat_title'
    elseif message.new_chat_photo
    then
        return 'new_chat_photo'
    elseif message.delete_chat_photo
    then
        return 'delete_chat_photo'
    elseif message.group_chat_created
    then
        return 'group_chat_created'
    elseif message.supergroup_chat_created
    then
        return 'supergroup_chat_created'
    elseif message.channel_chat_created
    then
        return 'channel_chat_created'
    elseif message.migrate_to_chat_id
    then
        return 'migrate_to_chat_id'
    elseif message.migrate_from_chat_id
    then
        return 'migrate_from_chat_id'
    elseif message.pinned_message
    then
        return 'pinned_message'
    elseif message.successful_payment
    then
        return 'successful_payment'
    end
    message = nil
    return ''
end

function mattata.is_media(message)
    if message.audio
    or message.document
    or message.game
    or message.photo
    or message.sticker
    or message.video
    or message.voice
    or message.video_note
    or message.contact
    or message.location
    or message.venue
    or message.invoice
    then
        return true
    end
    message = nil
    return false
end

function mattata.media_type(message)
    if message.audio
    then
        return 'audio'
    elseif message.document
    then
        return 'document'
    elseif message.game
    then
        return 'game'
    elseif message.photo
    then
        return 'photo'
    elseif message.sticker
    then
        return 'sticker'
    elseif message.video
    then
        return 'video'
    elseif message.voice
    then
        return 'voice'
    elseif message.video_note
    then
        return 'video_note'
    elseif message.contact
    then
        return 'contact'
    elseif message.location
    then
        return 'location'
    elseif message.venue
    then
        return 'venue'
    elseif message.invoice
    then
        return 'invoice'
    end
    message = nil
    return ''
end

function mattata.file_id(message)
    if message.audio
    then
        return message.audio.file_id
    elseif message.document
    then
        return message.document.file_id
    elseif message.sticker
    then
        return message.sticker.file_id
    elseif message.video
    then
        return message.video.file_id
    elseif message.voice
    then
        return message.voice.file_id
    elseif message.video_note
    then
        return message.video_note.file_id
    end
    message = nil
    return ''
end

function mattata.process_chat(chat)
    chat.id_str = tostring(chat.id)
    if chat.type == 'private'
    then
        return chat
    end
    if not redis:hget(
        string.format(
            'chat:%s:info',
            chat.username
            or chat.id
        ),
        'id'
    ) then
        print(
            string.format(
                '%s[34m[+] Added the chat %s to the database!%s[0m',
                string.char(27),
                chat.username
                and '@' .. chat.username
                or chat.id,
                string.char(27)
            )
        )
    end
    redis:hset(
        string.format(
            'chat:%s:info',
            chat.username
            or chat.id
        ),
        'title',
        chat.title
    )
    redis:hset(
        string.format(
            'chat:%s:info',
            chat.username
            or chat.id
        ),
        'type',
        chat.type
    )
    if chat.username then
        redis:hset(
            string.format(
                'chat:%s:info',
                chat.username
                or chat.id
            ),
            'username',
            chat.username
        )
    end
    redis:hset(
        string.format(
            'chat:%s:info',
            chat.username
            or chat.id
        ),
        'id',
        chat.id
    )
    return chat
end

function mattata.process_user(user)
    if not user.id
    or not user.first_name
    then
        user = nil
        return
    end
    local new = false
    user.name = user.first_name
    if user.last_name
    then
        user.name = string.format(
            '%s %s',
            user.name,
            user.last_name
        )
    end
    if not redis:hget(
        string.format(
            'user:%s:info',
            user.username
            or user.id
        ),
        'id'
    ) then
        print(
            string.format(
                '%s[34m[+] Added the user %s to the database!%s%s[0m',
                string.char(27),
                user.username
                and '@' .. user.username
                or user.id,
                user.language_code
                and ' Language: ' .. user.language_code
                or '',
                string.char(27)
            )
        )
        new = true
    end
    redis:hset(
        string.format(
            'user:%s:info',
            user.username
            or user.id
        ),
        'name',
        user.name
    )
    redis:hset(
        string.format(
            'user:%s:info',
            user.username
            or user.id
        ),
        'first_name',
        user.first_name
    )
    if user.last_name
    then
        redis:hset(
            string.format(
                'user:%s:info',
                user.username
                or user.id
            ),
            'last_name',
            user.last_name
        )
    else
        redis:hdel(
            string.format(
                'user:%s:info',
                user.username
                or user.id
            ),
            'last_name'
        )
    end
    if user.username
    then
        redis:hset(
            string.format(
                'user:%s:info',
                user.username
                or user.id
            ),
            'username',
            user.username
        )
    else
        redis:hdel(
            string.format(
                'user:%s:info',
                user.username
                or user.id
            ),
            'username'
        )
    end
    if user.language_code
    then
        if mattata.does_language_exist(user.language_code)
        and not redis:hget(
            'chat:' .. user.id .. ':settings',
            'language'
        )
        then -- If a translation exists for the user's language code, and they haven't selected
        -- a language already, then set it as their primary language!
            redis:hset(
                'chat:' .. user.id .. ':settings',
                'language',
                user.language_code
            )
        end
        redis:hset(
            string.format(
                'user:%s:info',
                user.username
                or user.id
            ),
            'language_code',
            user.language_code
        )
    else
        redis:hdel(
            string.format(
                'user:%s:info',
                user.username
                or user.id
            ),
            'language_code'
        )
    end
    redis:hset(
        string.format(
            'user:%s:info',
            user.username
            or user.id
        ),
        'id',
        user.id
    )
    return user, new
end

function mattata.process_message(message)
    message.text = message.text
    or message.caption
    or ''
    message.text = message.text:gsub('^/(%a+)%_', '/%1 ')
    message.is_media = mattata.is_media(message)
    message.media_type = mattata.media_type(message)
    message.file_id = mattata.file_id(message)
    message.is_service_message = mattata.is_service_message(message)
    message.service_message = mattata.service_message(message)
    if message.from.language_code
    then
        message.from.language_code = message.from.language_code
        :lower()
        :gsub('%-', '_')
        if message.from.language_code:len() == 2
        and message.from.language_code ~= 'en'
        then
            message.from.language_code = message.from.language_code .. '_' .. message.from.language_code
        elseif message.from.language_code:len() == 2
        then
            message.from.language_code = 'en_us'
        end
    end
    message.from = mattata.process_user(message.from)
    if message.forward_from
    then
        message.forward_from = mattata.process_user(message.forward_from)
    elseif message.new_chat_member
    then
        message.new_chat_member = mattata.process_user(message.new_chat_member)
    elseif message.left_chat_member
    then
        message.left_chat_member = mattata.process_user(message.left_chat_member)
    end
    message.chat = mattata.process_chat(message.chat)
    if message.forward_from_chat
    then
        mattata.process_chat(message.forward_from_chat)
    end
    return message
end

function mattata.is_global_admin(id)
    for k, v in pairs(configuration.admins)
    do
        if id == v
        then
            return true
        end
    end
    id = nil
    return false
end

function mattata.get_user(input)
    input = tostring(input):match('^%@(.-)$')
    or tostring(input)
    local user = redis:hexists(
        'user:' .. input .. ':info',
        'id'
    )
    if not user
    then
        return false
    end
    user = {}
    user.type = 'private'
    user.id = redis:hget(
        'user:' .. input .. ':info',
        'id'
    )
    user.name = redis:hget(
        'user:' .. input .. ':info',
        'first_name'
    )
    user.first_name = user.name
    local last_name = redis:hget(
        'user:' .. input .. ':info',
        'last_name'
    )
    if last_name
    then
        user.last_name = last_name
        user.name = user.name .. ' ' .. last_name
    end
    local username = redis:hget(
        'user:' .. input .. ':info',
        'username'
    )
    if username
    then
        user.username = username
    end
    user.language_code = redis:hget(
        'user:' .. input .. ':info',
        'language_code'
    )
    or 'en_gb'
    return {
        ['ok'] = true,
        ['result'] = user
    }
end

function mattata.get_inline_help(input, offset)
    offset = offset
    and tonumber(offset)
    or 0
    local inline_help = {}
    local count = offset + 1
    table.sort(plugin_list)
    for k, v in pairs(plugin_list)
    do
        if k > offset
        and k < offset + 50
        then -- The bot API only accepts a maximum of 50 results, hence we need the offset.
            v = v:gsub('\n', ' ')
            if v:match('^/.- %- .-$')
            and v
            :lower()
            :match(input)
            then
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
    end
    return inline_help
end

function mattata.get_inline_list(username, offset)
    offset = offset
    and tonumber(offset)
    or 0
    local inline_list = {}
    table.sort(inline_plugin_list)
    for k, v in pairs(inline_plugin_list)
    do
        if k > offset
        and k < offset + 50
        then -- The bot API only accepts a maximum of 50 results, hence we need the offset.
            v = v:gsub('\n', ' ')
            table.insert(
                inline_list,
                mattata.inline_result()
                :type('article')
                :id(
                    tostring(k)
                )
                :title(
                    v:match('^(/.-) %- .-$')
                )
                :description(
                    v:match('^/.- %- (.-)$')
                )
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
                        mattata.row():switch_inline_query_button(
                            'Show me how!',
                            v:match('^(/.-) ')
                        )
                    )
                )
            )
        end
    end
    return inline_list
end

function mattata.get_help()
    local help = {}
    local count = 1
    table.sort(plugin_list)
    for k, v in pairs(plugin_list)
    do
        if v:match('^/.- %- .-$')
        then
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
    if not chat
    or not mattata.get_chat(chat)
    then
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

function mattata.get_user_count()
    return #redis:keys('user:*:info')
end

function mattata.get_group_count()
    return #redis:keys('chat:*:info')
end

function mattata.get_log_chat(chat_id)
    return (
        chat_id
        and redis:hget(
            'chat:' .. chat_id .. ':settings',
            'log chat'
        )
    )
    and redis:hget(
        'chat:' .. chat_id .. ':settings',
        'log chat'
    )
    or configuration.log_channel
    or false
end

function mattata.clear_broadcast_memory()
    local broadcasts = redis:keys('broadcasted:*')
    for k, v in pairs(broadcasts)
    do
        if redis:get(v)
        then
            redis:del(v)
        end
    end
end

function mattata.get_user_language(user_id)
    return redis:hget(
        'chat:' .. user_id .. ':settings',
        'language'
    )
    or 'en_gb'
end

function mattata.format_time(seconds)
    if not seconds -- If a nil or boolean value was given.
    or tonumber(seconds) == nil -- If the given string as a numerical value is nil.
    then
        return false
    end
    local output
    seconds = tonumber(seconds) -- Make sure we're handling a numerical value.
    local minutes = math.floor(seconds / 60)
    if minutes == 0
    then
        return seconds ~= 1
        and seconds .. ' seconds'
        or seconds .. ' second'
    elseif minutes < 60
    then
        return minutes ~= 1
        and minutes .. ' minutes'
        or minutes .. ' minute'
    end
    local hours = math.floor(seconds / 3600)
    if hours == 0
    then
        return minutes ~= 1
        and minutes .. ' minutes'
        or minutes .. ' minute'
    elseif hours < 24
    then
        return hours ~= 1
        and hours .. ' hours'
        or hours .. ' hour'
    end
    local days = math.floor(seconds / 86400)
    if days == 0
    then
        return hours ~= 1
        and hours .. ' hours'
        or hours .. ' hour'
    elseif days < 7
    then
        return days ~= 1
        and days .. ' days'
        or days .. ' day'
    end
    local weeks = math.floor(seconds / 604800)
    if weeks == 0
    then
        return days ~= 1
        and days .. ' days'
        or days .. ' day'
    else
        return weeks ~= 1
        and weeks .. ' weeks'
        or weeks .. ' week'
    end
end

function mattata.get_missing_languages(delimiter)
    local missing_languages = redis:smembers('mattata:missing_languages')
    if not missing_languages
    then
        return false
    end
    local output = {}
    for k, v in pairs(missing_languages)
    do
        table.insert(
            output,
            v
        )
    end
    local delimiter = delimiter
    or ', '
    return table.concat(
        output,
        delimiter
    )
end

function mattata.does_language_exist(language)
    return pcall(
        function()
            return require('languages.' .. language)
        end
    )
end

function mattata.purge_user(user) -- To be improved.
    if type(user) ~= 'table'
    then
        return false
    end
    user = user.from
    or user
    redis:hdel(
        'user:' .. user.username
        or user.id .. ':info',
        'id'
    )
    if user.username
    or redis:hget(
        'user:' .. user.username
        or user.id .. ':info',
        'username'
    )
    then
        redis:hdel(
            'user:' .. user.username
            or user.id .. ':info',
            'username'
        )
    end
    redis:hdel(
        'user:' .. user.username
        or user.id .. ':info',
        'first_name'
    )
    if user.name
    or redis:hget(
        'user:' .. user.username
        or user.id .. ':info',
        'name'
    )
    then
        redis:hdel(
            'user:' .. user.username
            or user.id .. ':info',
            'name'
        )
    end
    if user.last_name
    or redis:hget(
        'user:' .. user.username
        or user.id .. ':info',
        'last_name'
    )
    then
        redis:hdel(
            'user:' .. user.username
            or user.id .. ':info',
            'last_name'
        )
    end
    if user.language_code
    or redis:hget(
        'user:' .. user.username
        or user.id .. ':info',
        'language_code'
    )
    then
        redis:hdel(
            'user:' .. user.username
            or user.id .. ':info',
            'language_code'
        )
    end
    return true
end

return mattata