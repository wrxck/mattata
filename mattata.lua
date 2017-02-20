--[[
                       _   _        _
       _ __ ___   __ _| |_| |_ __ _| |_ __ _
      | '_ ` _ \ / _` | __| __/ _` | __/ _` |
      | | | | | | (_| | |_| || (_| | || (_| |
      |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|


        Copyright (c) 2017 Matthew Hesketh
        See './LICENSE' for details

        Current version: v15

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
local plugin_list = {}
local inline_plugin_list = {}

function mattata:init()
    repeat
        self.info = mattata.get_me()
    until self.info
    self.info = self.info.result
    self.plugins = {}
    plugin_list = {}
    inline_plugin_list = {}
    for k, v in ipairs(configuration.plugins) do
        local plugin = require('plugins.' .. v)
        self.plugins[k] = plugin
        self.plugins[k].name = v
        if plugin.init then
            plugin.init(
                self,
                configuration
            )
        end
        plugin.is_inline = false
        if plugin.on_inline_query then
            plugin.is_inline = true
        end
        if not plugin.commands then
            plugin.commands = {}
        end
        if plugin.help then
            table.insert(
                plugin_list,
                plugin.help
            )
            if plugin.is_inline then
                table.insert(
                    inline_plugin_list,
                    plugin.help
                )
            end
            plugin.help = 'Usage:\n' .. plugin.help:gsub('%. (Alias)', '.\n%1')
        end
    end
    print('Connected to the Telegram bot API!')
    self.info.name = self.info.first_name
    print(
        string.format(
            '\n          Username: @%s\n          Name: %s\n          ID: %s\n',
            self.info.username,
            self.info.name,
            self.info.id
        )
    )
    self.version = 'v15'
    if not redis:get('mattata:version') or redis:get('mattata:version') ~= self.version then -- Make necessary database changes.
        for k, v in pairs(
            redis:keys('user:*:info')
        ) do
            mattata.process_user(
                redis:hgetall(v)
            )
        end
    end
    redis:set(
        'mattata:version',
        self.version
    )
    self.last_update = self.last_update or 0
    self.last_cron = self.last_cron or os.date('%H')
    self.last_m_cron = self.last_m_cron or os.date('%M')
    return true
end

--[[

    Function to make POST requests to the Telegram bot API.
    A custom API can be specified, such as the PWRTelegram API,
    using the 'api' parameter.
]]

function mattata.request(endpoint, parameters, file)
    assert(
        endpoint,
        'You must specify an endpoint to make this request to!'
    )
    parameters = parameters or {}
    for k, v in pairs(parameters) do
        parameters[k] = tostring(v)
    end
    if file and next(file) ~= nil then
        local file_type, file_name = next(file)
        if not file_name then
            return false
        end
        if file_name:match(configuration.download_location) then
            local file_res = io.open(
                file_name,
                'r'
            )
            local file_data = {
                filename = file_name,
                data = file_res:read('*a')
            }
            file_res:close()
            parameters[file_type] = file_data
        else
            local file_type, file_name = next(file)
            parameters[file_type] = file_name
        end
    end
    if next(parameters) == nil then
        parameters = {
            ''
        }
    end
    local response = {}
    local body, boundary = multipart.encode(parameters)
    local success, code = https.request(
        {
            ['url'] = endpoint,
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
                ['Content-Length'] = #body
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if not success then
        print(
            string.format(
                'Connection error [%s]',
                code
            )
        )
        return false, code
    end
    local jdat = table.concat(response)
    if not json.decode(jdat) then
        return jdat, code
    end
    jdat = json.decode(jdat)
    if jdat.ok == true then
        return jdat, code
    end
    print(
        string.format(
            '%s [%s]',
            jdat.description,
            jdat.error_code
        )
    )
    return false, jdat
end

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
    local init = mattata.init(self)
    while init do
        local res = mattata.get_updates(
            5, -- Limit
            self.last_update + 1 -- Offset
        )
        if res then
            for _, update in ipairs(res.result) do
                self.last_update = update.update_id
                if update.message then
                    mattata.on_message(
                        self,
                        update.message,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '[Update #%s] Message from %s to %s',
                                update.update_id,
                                update.message.from.id,
                                update.message.chat.id
                            )
                        )
                    end
                elseif update.edited_message then
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
                elseif update.channel_post then
                    mattata.on_message(
                        self,
                        update.channel_post,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '[Update #%s] Channel post from %s',
                                update.update_id,
                                update.channel_post.chat.id
                            )
                        )
                    end
                elseif update.edited_channel_post then
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
                elseif update.inline_query then
                    mattata.on_inline_query(
                        self,
                        update.inline_query,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '[Update #%s] Inline query from %s',
                                update.update_id,
                                update.inline_query.from.id
                            )
                        )
                    end
                elseif update.callback_query then
                    mattata.on_callback_query(
                        self,
                        update.callback_query,
                        update.callback_query.message or false,
                        configuration
                    )
                    if configuration.debug then
                        print(
                            string.format(
                                '[Update #%s] Callback query from %s',
                                update.update_id,
                                update.callback_query.from.id
                            )
                        )
                    end
                else
                    print(json.encode(update))
                end
            end
        else
            print('There was an error retrieving updates from the Telegram bot API!')
        end
        if self.last_cron ~= os.date('%H') then
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
        if self.last_m_cron ~= os.date('%M') then
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
    if not message.from and message.text:match('^%/') then
        return mattata.send_reply(
            message,
            'To be able to use me in this channel, you need to enable the "Sign Messages" option in your channel\'s settings.'
        )
    elseif not message.from or redis:get('global_blacklist:' .. message.from.id) or redis:get( -- Ignore messages from a user if they're speaking in a channel that doesn't have the sign messages setting enabled, or if they're blacklisted (whether that'd be globally or just in the group).
        string.format(
            'group_blacklist:%s:%s',
            message.chat.id,
            message.from.id
        )
    ) then
        return
    end
    self.info.name = redis:get(
        string.format(
            'chat:%s:name',
            message.chat.id
        )
    ) or 'mattata'
    message = mattata.process_message(message) -- Process the message.
    if message.reply_to_message then
        message.reply_to_message = mattata.process_message(message.reply_to_message)
    end
    if message.text:match('^%/start .-$') then -- Allow deep-linking through the /start command.
        message.text = message.text:match('^%/start (.-)$')
    end
    if message.forward_from or message.forward_from_chat then
        return
    end
    message.chat.title = message.chat.title or message.from.name
    if mattata.is_global_admin(message.from.id) and message.text:match(' %-%-switch%-chat$') then
        message.text = message.text:match('^(.-) %-%-switch%-chat$')
        local old_id = message.from.id
        message.from.id = message.chat.id
        message.chat.id = old_id
    end
    if message.text:match('^.-%:.-$') and message.chat.type == 'private' then
        local chat_id, action = message.text:match('^(.-)%:(.-)$')
        if action == 'rules' and redis:get(
            string.format(
                'administration:%s:enabled',
                chat_id
            )
        ) then
            local administration = require('plugins.administration')
            return mattata.send_message(
                message.chat.id,
                administration.get_rules(chat_id),
                'markdown'
            )
        end
    end
    if message.chat.type == 'supergroup' and redis:get(
        string.format(
            'administration:%s:enabled',
            message.chat.id
        )
    ) then
        local administration = require('plugins.administration')
        administration.process_message(
            self,
            message
        )
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
    elseif mattata.is_global_admin(message.from.id) and message.text:match('^%/addresp .-\n.-$') then
        local response = message.text:lower():match('^%/addresp .-\n(.-)$')
        local conversation = json.encode(
            {
                ['message'] = message.text:lower():match('^%/addresp (.-)\n.-$'),
                ['responses'] = {
                    response
                }
            }
        )
        if redis:hget(
            'ai',
            message.text:lower():match('^%/addresp (.-)\n.-$')
        ) then
            conversation = json.decode(
                redis:hget(
                    'ai',
                    message.text:lower():match('^%/addresp (.-)\n.-$')
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
                message.text:lower():match('^%/addresp (.-)\n.-$')
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
            if message.text:match(command) then
                if not plugin.on_message then
                    return
                elseif (
                    plugin.name == 'administration' and not redis:get(
                        string.format(
                            'administration:%s:enabled',
                            message.chat.id
                        )
                    ) and not message.text:match('^%/administration') and not message.text:match('^%/administration%@' .. self.info.username:lower()) and not message.text:match('^%/groups') and not message.text:match('^%/groups%@' .. self.info.username:lower())
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
            message.reply_to_message and message.reply_to_message.photo
        )
    ) then
        if message.reply_to_message then
            message = message.reply_to_message
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
        if message.text:match('^%/statistics$') or message.text:match('^%/statistics@' .. self.info.username:lower()) or message.text:match('^%/stats$') or message.text:match('^%/stats@' .. self.info.username:lower()) then 
            return statistics.on_message(
                self,
                message,
                configuration
            )
        end
    end
    if mattata.is_global_admin(message.from.id) and message.chat.id == configuration.bug_reports_chat and message.reply_to_message and message.reply_to_message.forward_from and not message.text:match('^%/') then
        return mattata.send_message(
            message.reply_to_message.forward_from.id,
            string.format(
                'Message from the developer regarding bug report #%s:\n<pre>%s</pre>',
                message.reply_to_message.forward_date,
                mattata.escape_html(message.text)
            ),
            'html'
        )
    elseif not mattata.is_plugin_disabled(
        'ai',
        message
    ) and not message.text:match('^Cancel$') and not message.text:match('^%/?s%/.-%/.-%/?$') and not message.photo and not message.text:match('^%/') and not message.forward_from then
        if (
            message.text:lower():match('^' .. self.info.name:lower() .. '.? .-$') or message.text:match('^.-%,? ' .. self.info.name:lower() .. '%??%.?%!?$') or message.chat.type == 'private' or (
            message.reply_to_message and message.reply_to_message.from.id == self.info.id
        )
    ) and message.text:lower() ~= self.info.name:lower() then
            message.text = message.text:lower():gsub(self.info.name:lower(), '')
            local ai = require('plugins.ai')
            return ai.on_message(
                self,
                message,
                configuration
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
        message.text:match('^%/') and message.chat.type == 'private'
    ) or (
        message.chat.type ~= 'private' and message.text:match('^%/%a+@' .. self.info.username)
    ) then
        return mattata.send_reply(
            message,
            'Sorry, I don\'t understand that command.\nTip: Use /help to discover what else I can do!'
        )
    end
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
    elseif message.reply_to_message and message.reply_to_message.text and message.text:lower():match('^wh?at would ' .. self.info.name:lower() .. ' say%??%.?%!?$') and not mattata.is_plugin_disabled(
        'ai',
        message
    ) then
        local old_from = message.from
        message = message.reply_to_message
        message.from = old_from
        local ai = require('plugins.ai')
        return ai.on_message(
            self,
            message,
            configuration
        )
    end
end

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
    if not mattata.is_plugin_disabled(
        'ai',
        edited_message
    ) and not edited_message.text:match('^Cancel$') and not edited_message.text:match('^%/?s%/.-%/.-%/?$') and not edited_message.photo and not edited_message.text:match('^%/') and not edited_message.forward_from then
        if (
            edited_message.text:lower():match('^' .. self.info.name:lower() .. '.? .-$') or edited_message.text:match('^.-%,? ' .. self.info.name:lower() .. '%??%.?%!?$') or edited_message.chat.type == 'private' or (
            edited_message.reply_to_message and edited_message.reply_to_message.from.id == self.info.id
        )
    ) and edited_message.text:lower() ~= self.info.name:lower() then
            edited_message.text = edited_message.text:lower():gsub(self.info.name:lower(), '')
            local ai = require('plugins.ai')
            return ai.on_edited_message(
                self,
                edited_message,
                configuration
            )
        end
    end
end

function mattata:on_inline_query(inline_query, configuration)
    if not inline_query.from or redis:get('global_blacklist:' .. inline_query.from.id) then
        return
    end
    for _, plugin in ipairs(self.plugins) do
        local plugins = plugin.commands or {}
        for i = 1, #plugins do
            local command = plugin.commands[i]
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
                    message = nil
                    return
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
        return
    elseif message then
        if message.reply_to_message and message.chat.type ~= 'channel' and callback_query.from.id ~= message.reply_to_message.from.id and not callback_query.data:match('^game%:') then
            return mattata.answer_callback_query(
                callback_query.id,
                string.format(
                    'Only %s can use this!',
                    message.reply_to_message.from.first_name
                )
            )
        end
    end
    for _, plugin in ipairs(self.plugins) do
        if plugin.name == callback_query.data:match('^(.-)%:.-$') and plugin.on_callback_query then
            callback_query.data = callback_query.data:match('^%a+%:(.-)$')
            if not callback_query.data then
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

function mattata.send_message(message, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendmessage
    token = token or configuration.bot_token
    if disable_web_page_preview == nil then
        disable_web_page_preview = true
    end
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    local chat_id = message
    if type(message) == 'table' then
        chat_id = message.chat.id
    end
    local success = mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendMessage',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['disable_web_page_preview'] = disable_web_page_preview,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
    if success and type(message) == 'table' then
        redis:set(
            'message:' .. message.chat.id .. ':' .. message.message_id,
            success.result.message_id
        )
    end
    return success
end

function mattata.send_reply(message, text, parse_mode, disable_web_page_preview, reply_markup, token) -- A variant of mattata.send_message(), optimised for sending a message as a reply.
    token = token or configuration.bot_token
    if disable_web_page_preview == nil then
        disable_web_page_preview = true
    end
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    local success = mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendMessage',
            token
        ),
        {
            ['chat_id'] = message.chat.id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['disable_web_page_preview'] = disable_web_page_preview,
            ['disable_notification'] = false,
            ['reply_to_message_id'] = message.message_id,
            ['reply_markup'] = reply_markup
        }
    )
    if success then
        redis:set(
            'message:' .. message.chat.id .. ':' .. message.message_id,
            success.result.message_id
        )
    end
    return success
end

function mattata.forward_message(chat_id, from_chat_id, disable_notification, message_id, token) -- https://core.telegram.org/bots/api#forwardmessage
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/forwardMessage',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['from_chat_id'] = from_chat_id,
            ['disable_notification'] = disable_notification or false,
            ['message_id'] = message_id
        }
    )
end

function mattata.send_photo(chat_id, photo, caption, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendphoto
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendPhoto',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['caption'] = caption,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['photo'] = photo
        }
    )
end

function mattata.send_audio(chat_id, audio, caption, duration, performer, title, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendaudio
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendAudio',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['caption'] = caption,
            ['duration'] = duration,
            ['performer'] = performer,
            ['title'] = title,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['audio'] = audio
        }
    )
end

function mattata.send_document(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#senddocument
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendDocument',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['caption'] = caption,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['document'] = document
        }
    )
end

function mattata.send_sticker(chat_id, sticker, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendsticker
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendSticker',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['sticker'] = sticker
        }
    )
end

function mattata.send_video(chat_id, video, duration, width, height, caption, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendvideo
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendVideo',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['duration'] = duration,
            ['width'] = width,
            ['height'] = height,
            ['caption'] = caption,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['video'] = video
        }
    )
end

function mattata.send_voice(chat_id, voice, caption, duration, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendvoice
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendVoice',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['caption'] = caption,
            ['duration'] = duration,
            ['disable_notification'] = disable_notification,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['voice'] = voice
        }
    )
end

function mattata.send_location(chat_id, latitude, longitude, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendlocation
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendLocation',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.send_venue(chat_id, latitude, longitude, title, address, foursquare_id, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendvenue
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendVenue',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['title'] = title,
            ['address'] = address,
            ['foursquare_id'] = foursquare_id,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.send_contact(chat_id, phone_number, first_name, last_name, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendcontact
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendContact',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['phone_number'] = phone_number,
            ['first_name'] = first_name,
            ['last_name'] = last_name,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.send_chat_action(chat_id, action, token) -- https://core.telegram.org/bots/api#sendchataction
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendChatAction',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['action'] = action or 'typing'
        }
    )
end

function mattata.get_user_profile_photos(user_id, offset, limit, token) -- https://core.telegram.org/bots/api#getuserprofilephotos
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getUserProfilePhotos',
            token
        ),
        {
            ['user_id'] = user_id,
            ['offset'] = offset,
            ['limit'] = limit
        }
    )
end

function mattata.get_file(file_id, token) -- https://core.telegram.org/bots/api#getfile
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getFile',
            token
        ),
        {
            ['file_id'] = file_id
        }
    )
end

function mattata.ban_chat_member(chat_id, user_id, token) -- https://core.telegram.org/bots/api#kickchatmember
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/kickChatMember',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        }
    )
end

function mattata.kick_chat_member(chat_id, user_id, token)
    token = token or configuration.bot_token
    local success = mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/kickChatMember',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        }
    )
    if not success then
        return success
    end
    return mattata.unban_chat_member(
        chat_id,
        user_id,
        token
    )
end

function mattata.unban_chat_member(chat_id, user_id, token) -- https://core.telegram.org/bots/api#unbanchatmember
    token = token or configuration.bot_token
    local success
    for i = 1, 3 do
        success = mattata.request(
            string.format(
                'https://api.telegram.org/bot%s/unbanChatMember',
                token
            ),
            {
                ['chat_id'] = chat_id,
                ['user_id'] = user_id
            }
        )
    end
    return success
end

function mattata.leave_chat(chat_id, token) -- https://core.telegram.org/bots/api#leavechat
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/leaveChat',
            token
        ),
        {
            ['chat_id'] = chat_id
        }
    )
end

function mattata.get_chat_administrators(chat_id, token) -- https://core.telegram.org/bots/api#getchatadministrators
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getChatAdministrators',
            token
        ),
        {
            ['chat_id'] = chat_id
        }
    )
end

function mattata.get_chat_members_count(chat_id, token) -- https://core.telegram.org/bots/api#getchatmemberscount
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getChatMembersCount',
            token
        ),
        {
            ['chat_id'] = chat_id
        }
    )
end

function mattata.get_chat_member(chat_id, user_id, token) -- https://core.telegram.org/bots/api#getchatmember
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getChatMember',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        }
    )
end

function mattata.answer_callback_query(callback_query_id, text, show_alert, url, token) -- https://core.telegram.org/bots/api#answercallbackquery
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/answerCallbackQuery',
            token
        ),
        {
            ['callback_query_id'] = callback_query_id,
            ['text'] = text,
            ['show_alert'] = show_alert or false,
            ['url'] = url
        }
    )
end

function mattata.edit_message_text(chat_id, message_id, text, parse_mode, disable_web_page_preview, reply_markup, inline_message_id, token) -- https://core.telegram.org/bots/api#editmessagetext
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/editMessageText',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['disable_web_page_preview'] = disable_web_page_preview,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.edit_message_caption(chat_id, message_id, inline_message_id, caption, reply_markup, token) -- https://core.telegram.org/bots/api#editmessagecaption
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/editMessageCaption',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id,
            ['caption'] = caption,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.edit_message_reply_markup(chat_id, message_id, inline_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#editmessagereplymarkup
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/editMessageReplyMarkup',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.answer_inline_query(inline_query_id, results, cache_time, is_personal, next_offset, switch_pm_text, switch_pm_parameter, token) -- https://core.telegram.org/bots/api#answerinlinequery
    token = token or configuration.bot_token
    if type(results) == 'table' then
        if results.id then
            results = {
                results
            }
        end
        results = json.encode(results)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/answerInlineQuery',
            token
        ),
        {
            ['inline_query_id'] = inline_query_id,
            ['results'] = results,
            ['switch_pm_text'] = switch_pm_text or 'More features!',
            ['switch_pm_parameter'] = switch_pm_parameter,
            ['cache_time'] = cache_time or 0,
            ['is_personal'] = is_personal or false,
            ['next_offset'] = next_offset
        }
    )
end

function mattata.send_game(chat_id, game_short_name, disable_notification, reply_to_message_id, reply_markup, token) -- https://core.telegram.org/bots/api#sendgame
    token = token or configuration.bot_token
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/sendGame',
            token
        ),
        {
            ['chat_id'] = chat_id,
            ['game_short_name'] = game_short_name,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.set_game_score(chat_id, user_id, message_id, score, force, disable_edit_message, inline_message_id, token) -- https://core.telegram.org/bots/api#setgamescore
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/setGameScore',
            token
        ),
        {
            ['user_id'] = user_id,
            ['score'] = score,
            ['force'] = force or false,
            ['disable_edit_message'] = disable_edit_message or false,
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id
        }
    )
end

function mattata.get_game_high_scores(user_id, chat_id, message_id, inline_message_id, token) -- https://core.telegram.org/bots/api#getgamehighscores
    token = token or configuration.bot_token
    return mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getGameHighScores',
            token
        ),
        {
            ['user_id'] = user_id,
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id
        }
    )
end

function mattata.get_chat(chat_id, token) -- https://core.telegram.org/bots/api#getchat
    token = token or configuration.bot_token
    local success = mattata.request(
        string.format(
            'https://api.telegram.org/bot%s/getChat',
            token
        ),
        {
            ['chat_id'] = chat_id
        }
    )
    if success and success.result.type == 'private' then
        mattata.process_user(success.result)
    elseif success then
        mattata.process_chat(success.result)
    end
    return success
end

--[[

    General functions for general use throughout mattata's
    framework and plugins.

]]

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
    return false
end

function mattata.input(s)
    if not s then
        return false
    end
    if s:lower():match('^mattata search %a+ for .-$') then
        return s:lower():match('^mattata search %a+ for (.-)$')
    end
    local input = s:find(' ')
    if not input then
        return false
    end
    return s:sub(input + 1)
end

function mattata.trim(str)
    str = str:gsub('^%s*(.-)%s*$', '%1')
    return str
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
            string.format(
                '<pre>%s</pre>',
                output
            ),
            'html'
        )
    end
end

function mattata.download_file(url, name)
    name = name or string.format(
        '%s.%s',
        os.time(),
        url:match('.+%/%.(.-)$')
    )
    local body = {}
    local protocol = http
    local redirect = true
    if url:match('^https') then
        protocol = https
        redirect = false
    end
    local _, res = protocol.request(
        {
            ['url'] = url,
            ['sink'] = ltn12.sink.table(body),
            ['redirect'] = redirect
        }
    )
    if res ~= 200 then
        return false
    end
    local file = io.open(
        configuration.download_location .. name,
        'w+'
    )
    file:write(
        table.concat(body)
    )
    file:close()
    return configuration.download_location .. name
end

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
    return false
end

function mattata.get_linked_name(id)
    local success = mattata.get_chat(id)
    if not success then
        return false
    end
    local output = mattata.escape_html(success.result.first_name)
    if success.result.username then
        output = string.format(
            '<a href="https://t.me/%s">%s</a>',
            success.result.username,
            output
        )
    end
    return output
end

function mattata.escape_markdown(str)
    return tostring(str):gsub('%_', '\\_'):gsub('%[', '\\['):gsub('%*', '\\*'):gsub('%`', '\\`')
end

function mattata.escape_html(str)
    return tostring(str):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end

function mattata.escape_bash(str)
    return tostring(str):gsub('$', ''):gsub('%^', ''):gsub('&', ''):gsub('|', ''):gsub(';', '')
end

mattata.commands_meta = {}

mattata.commands_meta.__index = mattata.commands_meta

function mattata.commands_meta:command(command)
    table.insert(
        self.table,
        string.format(
            '^[%%/%%!%%$%%^%%?%%&%%%%]%s$',
            command
        )
    )
    table.insert(
        self.table,
        string.format(
            '^[%%/%%!%%$%%^%%?%%&%%%%]%s@%s$',
            command,
            self.username
        )
    )
    table.insert(
        self.table,
        string.format(
            '^[%%/%%!%%$%%^%%?%%&%%%%]%s%%s+[^%%s]*',
            command
        )
    )
    table.insert(
        self.table,
        string.format(
            '^[%%/%%!%%$%%^%%?%%&%%%%]%s@%s%%s+[^%%s]*',
            command,
            self.username
        )
    )
    return self
end

function mattata.commands(username, command_table)
    local self = setmetatable(
        {},
        mattata.commands_meta
    )
    self.username = username:lower()
    self.table = command_table or {}
    return self
end

function mattata.table_size(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
    end
    return i
end

function mattata.is_service_message(message)
    if message.new_chat_member or message.left_chat_member or message.new_chat_title or message.new_chat_photo or message.delete_chat_photo or message.group_chat_created or message.supergroup_chat_created or message.channel_chat_created or message.migrate_to_chat_id or message.migrate_from_chat_id or message.pinned_message then
        return true
    end
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
    return ''
end

function mattata.is_media(message)
    if message.photo or message.audio or message.document or message.sticker or message.video or message.voice or message.contact or message.location or message.venue then
        return true
    end
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
    return ''
end

function mattata.utf8_len(str)
    local chars = 0
    for i = 1, str:len() do
        local byte = str:byte(i)
        if byte < 128 or byte >= 192 then
            chars = chars + 1
        end
    end
    return chars
end

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
                'New chat added to database [%s]',
                chat.username or chat.id
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
                'New user added to database [%s]',
                user.username or user.id
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
    message.text = message.text:gsub('^%/(%a+)%_', '/%1 ')
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
    end
    message.chat = mattata.process_chat(message.chat)
    if message.forward_from_chat then
        mattata.process_chat(message.forward_from_chat)
    end 
    return message
end

function mattata.is_global_admin(id)
    for k, v in pairs(configuration.admins) do
        if id == v then
            return true
        end
    end
    return false
end

function mattata.comma_value(amount)
    amount = tostring(amount)
    while true do
        amount, k = amount:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then
            break
        end
    end
    return amount
end

function mattata.format_ms(milliseconds)
    local total_seconds = math.floor(milliseconds / 1000)
    local seconds = total_seconds % 60
    local minutes = math.floor(total_seconds / 60)
    local hours = math.floor(minutes / 60)
    minutes = minutes % 60
    return string.format(
        '%02d:%02d:%02d',
        hours,
        minutes,
        seconds
    )
end

function mattata.round(num, idp)
    if idp and idp > 0 then
        local mult = 10 ^ idp
        return math.floor(num * mult + .5) / mult
    end
    return math.floor(num + .5)
end

function mattata.get_user(input)
    input = tostring(input):match('^%@(.-)$') or tostring(input)
    local user = redis:hgetall('user:' .. input .. ':info')
    if user.username and user.username:lower() == input:lower() then
        return mattata.get_chat(user.id)
    end
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
        if v:match('^%/.- %- .-$') and v:lower():match(input) then
            table.insert(
                inline_help,
                {
                    ['type'] = 'article',
                    ['id'] = tostring(count),
                    ['title'] = v:match('^(%/.-) %- .-$'),
                    ['description'] = v:match('^%/.- %- (.-)$'),
                    ['input_message_content'] = {
                        ['message_text'] = utf8.char(8226) .. ' ' .. v:match('^(%/.-) %- .-$') .. ' - ' .. v:match('^%/.- %- (.-)$')
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
                    v:match('^(%/.-) %- .-$')
                )
            ):description(
                v:match('^%/.- %- (.-)$')
            ):input_message_content(
                mattata.input_text_message_content(
                    string.format(
                        '• %s - %s\n\nTo use this command inline, you must use the syntax:\n@%s %s',
                        v:match('^(%/.-) %- .-$'),
                        v:match('^(%/.-) %- .-$'),
                        username,
                        v:match('^(%/.-) %- .-$')
                    )
                )
            ):reply_markup(
                mattata.inline_keyboard():row(
                    mattata.row():switch_inline_query_button(
                        'Show me how!',
                        v:match('^(%/.-) ')
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
        if v:match('^%/.- %- .-$') then
            table.insert(
                help,
                utf8.char(8226) .. ' ' .. v:match('^(%/.-) %- .-$')
            )
            count = count + 1
        end
    end
    return help
end

function mattata.get_chat_id(chat)
    if not chat or not mattata.get_chat(chat) then
        return false
    end
    return mattata.get_chat(chat).result.id
end

--[[

    Functions for handling and generating InputMessageContent objects, for use with the series of inline result objects.

    This object represents the content of a message to be sent as a result of an inline query. Telegram clients currently support the following 4 types:

        InputTextMessageContent         => mattata.input_text_message_content()
        InputLocationMessageContent     => mattata.input_location_message_content()
        InputVenueMessageContent        => mattata.input_venue_message_content()
        InputContactMessageContent      => mattata.input_contact_message_content()

]]

function mattata.input_text_message_content(message_text, parse_mode, disable_web_page_preview, encoded)
    local input_message_content = {
        ['message_text'] = tostring(message_text),
        ['parse_mode'] = parse_mode,
        ['disable_web_page_preview'] = disable_web_page_preview
    }
    if encoded then
        input_message_content = json.encode(input_message_content)
    end
    return input_message_content
end

function mattata.input_location_message_content(latitude, longitude, encoded)
    local input_message_content = {
        ['latitude'] = tonumber(latitude),
        ['longitude'] = tonumber(longitude)
    }
    if encoded then
        input_message_content = json.encode(input_message_content)
    end
    return input_message_content
end

function mattata.input_venue_message_content(latitude, longitude, title, address, foursquare_id, encoded)
    local input_message_content = {
        ['latitude'] = tonumber(latitude),
        ['longitude'] = tonumber(longitude),
        ['title'] = tostring(title),
        ['address'] = tostring(address),
        ['foursquare_id'] = foursquare_id
    }
    if encoded then
        input_message_content = json.encode(input_message_content)
    end
    return input_message_content
end

function mattata.input_contact_message_content(phone_number, first_name, last_name, encoded)
    local input_message_content = {
        ['phone_number'] = tostring(phone_number),
        ['first_name'] = tonumber(first_name),
        ['last_name'] = last_name
    }
    if encoded then
        input_message_content = json.encode(input_message_content)
    end
    return input_message_content
end

--[[

    Functions for handling inline objects to use with mattata.answer_inline_query()

]]

function mattata.send_inline_article(inline_query_id, title, description, message_text, parse_mode, reply_markup)
    description = description or title
    message_text = message_text or description
    return mattata.answer_inline_query(
        inline_query_id,
        json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = title,
                    ['description'] = description,
                    ['input_message_content'] = {
                        ['message_text'] = message_text,
                        ['parse_mode'] = parse_mode
                    },
                    ['reply_markup'] = reply_markup
                }
            }
        )
    )
end

function mattata.send_inline_article_url(inline_query_id, title, url, hide_url, input_message_content, reply_markup, id)
    if id then
        id = tostring(id)
    end
    return mattata.answer_inline_query(
        inline_query_id,
        json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = id or '1',
                    ['title'] = tostring(title),
                    ['url'] = tostring(url),
                    ['hide_url'] = hide_url or false,
                    ['input_message_content'] = input_message_content,
                    ['reply_markup'] = reply_markup
                }
            }
        )
    )
end

mattata.inline_result_meta = {}

mattata.inline_result_meta.__index = mattata.inline_result_meta

function mattata.inline_result_meta:type(type)
    self['type'] = tostring(type)
    return self
end

function mattata.inline_result_meta:id(id)
    if id then
        id = tostring(id)
    end
    self['id'] = id or '1'
    return self
end

function mattata.inline_result_meta:title(title)
    self['title'] = tostring(title)
    return self
end

function mattata.inline_result_meta:input_message_content(input_message_content)
    self['input_message_content'] = input_message_content
    return self
end

function mattata.inline_result_meta:reply_markup(reply_markup)
    self['reply_markup'] = reply_markup
    return self
end

function mattata.inline_result_meta:url(url)
    self['url'] = tostring(url)
    return self
end

function mattata.inline_result_meta:hide_url(hide_url)
    self['hide_url'] = hide_url or false
    return self
end

function mattata.inline_result_meta:description(description)
    self['description'] = tostring(description)
    return self
end

function mattata.inline_result_meta:thumb_url(thumb_url)
    self['thumb_url'] = tostring(thumb_url)
    return self
end

function mattata.inline_result_meta:thumb_width(thumb_width)
    self['thumb_width'] = tonumber(thumb_width)
    return self
end

function mattata.inline_result_meta:thumb_height(thumb_height)
    self['thumb_height'] = tonumber(thumb_height)
    return self
end

function mattata.inline_result_meta:photo_url(photo_url)
    self['photo_url'] = tostring(photo_url)
    return self
end

function mattata.inline_result_meta:photo_width(photo_width)
    self['photo_width'] = tonumber(photo_width)
    return self
end

function mattata.inline_result_meta:photo_height(photo_height)
    self['photo_height'] = tonumber(photo_height)
    return self
end

function mattata.inline_result_meta:caption(caption)
    self['caption'] = tostring(caption)
    return self
end

function mattata.inline_result_meta:gif_url(gif_url)
    self['gif_url'] = tostring(gif_url)
    return self
end

function mattata.inline_result_meta:gif_width(gif_width)
    self['gif_width'] = tonumber(gif_width)
    return self
end

function mattata.inline_result_meta:gif_height(gif_height)
    self['gif_height'] = tonumber(gif_height)
    return self
end

function mattata.inline_result_meta:mpeg4_url(mpeg4_url)
    self['mpeg4_url'] = tostring(mpeg4_url)
    return self
end

function mattata.inline_result_meta:mpeg4_width(mpeg4_width)
    self['mpeg4_width'] = tonumber(mpeg4_width)
    return self
end

function mattata.inline_result_meta:mpeg4_height(mpeg4_height)
    self['mpeg4_height'] = tonumber(mpeg4_height)
    return self
end

function mattata.inline_result_meta:video_url(video_url)
    self['video_url'] = tostring(video_url)
    return self
end

function mattata.inline_result_meta:mime_type(mime_type)
    self['mime_type'] = tostring(mime_type)
    return self
end

function mattata.inline_result_meta:video_width(video_width)
    self['video_width'] = tonumber(video_width)
    return self
end

function mattata.inline_result_meta:video_height(video_height)
    self['video_height'] = tonumber(video_height)
    return self
end

function mattata.inline_result_meta:video_duration(video_duration)
    self['video_duration'] = tonumber(video_duration)
    return self
end

function mattata.inline_result_meta:audio_url(audio_url)
    self['audio_url'] = tostring(audio_url)
    return self
end

function mattata.inline_result_meta:performer(performer)
    self['performer'] = tostring(performer)
    return self
end

function mattata.inline_result_meta:audio_duration(audio_duration)
    self['audio_duration'] = tonumber(audio_duration)
    return self
end

function mattata.inline_result_meta:voice_url(voice_url)
    self['voice_url'] = tostring(voice_url)
    return self
end

function mattata.inline_result_meta:voice_duration(voice_duration)
    self['voice_duration'] = tonumber(voice_duration)
    return self
end

function mattata.inline_result_meta:document_url(document_url)
    self['document_url'] = tostring(document_url)
    return self
end

function mattata.inline_result_meta:latitude(latitude)
    self['latitude'] = tonumber(latitude)
    return self
end

function mattata.inline_result_meta:longitude(longitude)
    self['longitude'] = tonumber(longitude)
    return self
end

function mattata.inline_result_meta:address(address)
    self['address'] = tostring(address)
    return self
end

function mattata.inline_result_meta:foursquare_id(foursquare_id)
    self['foursquare_id'] = tostring(foursquare_id)
    return self
end

function mattata.inline_result_meta:phone_number(phone_number)
    self['phone_number'] = tostring(phone_number)
    return self
end

function mattata.inline_result_meta:first_name(first_name)
    self['first_name'] = tostring(first_name)
    return self
end

function mattata.inline_result_meta:last_name(last_name)
    self['last_name'] = tostring(last_name)
    return self
end

function mattata.inline_result_meta:game_short_name(game_short_name)
    self['game_short_name'] = tostring(game_short_name)
    return self
end

function mattata.inline_result()
    local output = setmetatable(
        {},
        mattata.inline_result_meta
    )
    return output
end

function mattata.send_inline_photo(inline_query_id, photo_url, caption, reply_markup)
    return mattata.answer_inline_query(
        inline_query_id,
        json.encode(
            {
                {
                    ['type'] = 'photo',
                    ['id'] = '1',
                    ['photo_url'] = photo_url,
                    ['thumb_url'] = photo_url,
                    ['caption'] = caption,
                    ['reply_markup'] = reply_markup
                }
            }
        )
    )
end

function mattata.send_inline_cached_photo(inline_query_id, photo_file_id, caption, reply_markup)
    return mattata.answer_inline_query(
        inline_query_id,
        json.encode(
            {
                {
                    ['type'] = 'photo',
                    ['id'] = '1',
                    ['photo_file_id'] = photo_file_id,
                    ['caption'] = caption,
                    ['reply_markup'] = reply_markup
                }
            }
        )
    )
end

function mattata.url_button(text, url, encoded)
    if not text or not url then
        return false
    end
    local button = {
        ['text'] = tostring(text),
        ['url'] = tostring(url)
    }
    if encoded then
        button = json.encode(button)
    end
    return button
end

function mattata.callback_data_button(text, callback_data, encoded)
    if not text or not callback_data then
        return false
    end
    local button = {
        ['text'] = tostring(text),
        ['callback_data'] = tostring(callback_data)
    }
    if encoded then
        button = json.encode(button)
    end
    return button
end

function mattata.switch_inline_query_button(text, switch_inline_query, encoded)
    if not text or not switch_inline_query then
        return false
    end
    local button = {
        ['text'] = tostring(text),
        ['switch_inline_query'] = tostring(switch_inline_query)
    }
    if encoded then
        button = json.encode(button)
    end
    return button
end

function mattata.switch_inline_query_current_chat_button(text, switch_inline_query_current_chat, encoded)
    if not text or not switch_inline_query_current_chat then
        return false
    end
    local button = {
        ['text'] = tostring(text),
        ['switch_inline_query_current_chat'] = tostring(switch_inline_query_current_chat)
    }
    if encoded then
        button = json.encode(button)
    end
    return button
end

function mattata.callback_game_button(text, callback_game, encoded)
    if not text or not callback_game then
        return false
    end
    local button = {
        ['text'] = tostring(text),
        ['callback_game'] = tostring(callback_game)
    }
    if encoded then
        button = json.encode(button)
    end
    return button
end

mattata.row_meta = {}

mattata.row_meta.__index = mattata.row_meta

function mattata.row_meta:url_button(text, url)
    table.insert(
        self,
        {
            ['text'] = tostring(text),
            ['url'] = tostring(url)
        }
    )
    return self
end

function mattata.row_meta:callback_data_button(text, callback_data)
    table.insert(
        self,
        {
            ['text'] = tostring(text),
            ['callback_data'] = tostring(callback_data)
        }
    )
    return self
end

function mattata.row_meta:switch_inline_query_button(text, switch_inline_query)
    table.insert(
        self,
        {
            ['text'] = tostring(text),
            ['switch_inline_query'] = tostring(switch_inline_query)
        }
    )
    return self
end

function mattata.row_meta:switch_inline_query_current_chat_button(text, switch_inline_query_current_chat)
    table.insert(
        self,
        {
            ['text'] = tostring(text),
            ['switch_inline_query_current_chat'] = tostring(switch_inline_query_current_chat)
        }
    )
    return self
end

function mattata.row(buttons)
    return setmetatable(
        {},
        mattata.row_meta
    )
end

mattata.inline_keyboard_meta = {}

mattata.inline_keyboard_meta.__index = mattata.inline_keyboard_meta

function mattata.inline_keyboard_meta:row(row)
    table.insert(
        self.inline_keyboard,
        row
    )
    return self
end

function mattata.inline_keyboard()
    return setmetatable(
        {
            ['inline_keyboard'] = {}
        },
        mattata.inline_keyboard_meta
    )
end

mattata.keyboard_meta = {}

mattata.keyboard_meta.__index = mattata.keyboard_meta

function mattata.keyboard_meta:row(row)
    table.insert(
        self.keyboard,
        row
    )
    return self
end

function mattata.keyboard(resize_keyboard, one_time_keyboard, selective)
    return setmetatable(
        {
            ['keyboard'] = {},
            ['resize_keyboard'] = resize_keyboard or false,
            ['one_time_keyboard'] = one_time_keyboard or false,
            ['selective'] = selective or false
        },
        mattata.keyboard_meta
    )
end

function mattata.remove_keyboard(selective)
    return {
        ['remove_keyboard'] = true,
        ['selective'] = selective or false
    }
end

return mattata