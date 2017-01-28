--[[
                       _   _        _
       _ __ ___   __ _| |_| |_ __ _| |_ __ _
      | '_ ` _ \ / _` | __| __/ _` | __/ _` |
      | | | | | | (_| | |_| || (_| | || (_| |
      |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|


        Copyright (c) 2017 Matthew Hesketh
        See './LICENSE' for details

        Current version: v10

]]--

local mattata = {}
local https = require('ssl.https')
local http = require('socket.http')
local url = require('socket.url')
local ltn12 = require('ltn12')
local multipart = require('multipart-post')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')
local colors = require('ansicolors')

function mattata:init()
    if not configuration.bot_token or configuration.bot_token == '' or type(configuration.bot_token) ~= 'string' then
        print(colors.white .. '[mattata]' .. colors.red .. 'You need to enter your bot API key in configuration.lua!' .. colors.reset)
    end
    repeat
        self.info = mattata.request('getMe')
    until self.info
    self.info = self.info.result
    self.plugins = {}
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
        if not plugin.commands then
            plugin.commands = {}
        end
        if plugin.help then
            plugin.help = 'Usage:\n' .. plugin.help:gsub('%. Alias', '.\nAlias')
        end
    end
    print(colors.white .. '[mattata]' .. colors.green .. ' Connected to the Telegram bot API!' .. colors.reset)
    self.info.name = self.info.first_name
    if self.info.last_name then
        self.info.name = self.info.first_name .. ' ' .. self.info.last_name
    end
    print ('\n          ' .. colors.white .. 'Username: @' .. self.info.username .. '\n          Name: ' .. self.info.name .. '\n          ID: ' .. self.info.id .. colors.reset .. '\n')
    self.version = 'v10'
    self.last_update = self.last_update or 0
    self.last_cron = self.last_cron or os.date('%H')
    return true
end

--[[

    Function to make POST requests to the Telegram bot API.
    A custom API can be specified, such as the PWRTelegram API,
    using the 'api' parameter.

--]]

function mattata.request(method, parameters, file, api)
    parameters = parameters or {}
    api = api or 'https://api.telegram.org/bot'
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
        parameters = { '' }
    end
    local response = {}
    local body, boundary = multipart.encode(parameters)
    local success, code = https.request(
        {
            ['url'] = api .. configuration.bot_token .. '/' .. method,
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
        print(colors.white .. '[mattata]' .. colors.red .. ' ' .. method .. ': Connection error: ' .. code .. colors.reset)
        return false, false, code
    end
    local jdat = table.concat(response)
    jdat = json.decode(jdat)
    if not jdat then
        return false, false, code
    elseif jdat.ok == true then
        return jdat, 200, 'Success'
    end
    local api_error = string.format(
        '%s [%s]',
        jdat.description,
        jdat.error_code
    )
    print(api_error)
    return false, api_error
end

--[[

    mattata's main long-polling function which repeatedly checks
    the Telegram bot API for updates.
    The objects received in the updates are then further processed
    through object-specific functions.

--]]

function mattata:run(configuration)
    local init = mattata.init(self, configuration)
    while init do
        local res = mattata.get_updates(
            40,
            self.last_update + 1
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
                        print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Message from ' .. colors.cyan .. update.message.from.id .. colors.green .. ' to ' .. colors.cyan .. update.message.chat.id .. colors.reset)
                    end
                elseif update.channel_post then
                    mattata.on_message(
                        self,
                        update.channel_post,
                        configuration
                    )
                    if configuration.debug then
                        print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Channel post from ' .. colors.cyan .. update.channel_post.chat.id .. colors.reset)
                    end
                elseif update.inline_query then
                    mattata.on_inline_query(
                        self,
                        update.inline_query,
                        configuration
                    )
                    if configuration.debug then
                        print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Inline query from ' .. colors.cyan .. update.inline_query.from.id .. colors.reset)
                    end
                elseif update.callback_query then
                    mattata.on_callback_query(
                        self,
                        update.callback_query,
                        update.callback_query.message,
                        configuration
                    )
                    if configuration.debug then
                        print(colors.white .. '[mattata]' .. colors.yellow .. ' [Update #' .. update.update_id .. ']' .. colors.green .. ' Callback query from ' .. colors.cyan .. update.callback_query.from.id .. colors.reset)
                    end
                end
            end
        else
            print(colors.white .. '[mattata]' .. colors.red .. ' There was an error whilst retrieving updates from the Telegram bot API.' .. colors.reset)
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
        end
    end
    print(colors.white .. '[mattata]' .. colors.yellow .. ' mattata [@' .. self.info.username .. '] is shutting down...' .. colors.reset)
end

--[[

    Functions to run when the Telegram bot API (successfully) returns an object.
    Each object has a designated function within each plugin.

]]--

function mattata:on_message(message, configuration)
    if not message or message.date < os.time() - 5 then -- Don't iterate over old messages.
        return
    end
    message.text = message.text or message.caption or ''
    if not message.from then -- Ignore messages from channels without the 'Sign messages' options enabled.
        if message.text:match('^/(.-)$') then
            return mattata.send_reply(
                message,
                'To be able to use me in this channel, you need to enable the "Sign Messages" option in your channel\'s settings.'
            )
        end
        return
    elseif redis:get('global_blacklist:' .. message.from.id) then -- Ignore messages from globally-blacklisted users.
        return
    elseif redis:get('group_blacklist:' .. message.chat.id .. ':' .. message.from.id) then
        return
    end
    local user_language = mattata.get_user_language(message.from.id)
    local language = require('languages.' .. user_language)
    message = mattata.process_message(message) -- Process the message
    if message.reply_to_message then
        message.reply_to_message = mattata.process_message(message.reply_to_message)
    end
    if message.text:match('^/start (.-)$') then -- Allow deep-linking through the /start command
        message.text = message.text:match('^/start (.-)$')
        message.text_lower = message.text:lower()
        message.text_upper = message.text:upper()
    end
    if message.forward_from or message.forward_from_chat then
        return
    end
    if message.text == configuration.command_prefix .. 'cancel' or message.text == configuration.command_prefix .. 'cancel@' .. self.info.username:lower() then -- A small hack to forcibly remove a keyboard.
        return mattata.send_message(
            message.chat.id,
            'Cancelled current operation!',
            nil,
            true,
            false,
            message.message_id,
            json.encode(
                {
                    remove_keyboard = true
                }
            )
        )
    end
    if mattata.is_global_admin(message.from.id) and message.text:match(' %-%-switch%-chat$') then
        message.text = message.text:match('^(.-) %-%-switch%-chat$')
        local id = message.from.id
        message.from.id = message.chat.id
        message.chat.id = id
    end
    if message.text:match('^(.-)%:(.-)$') and message.chat.type == 'private' then
        local chat_id, action = message.text:match('^(.-)%:(.-)$')
        if action == 'rules' and redis:get('administration:' .. chat_id .. ':enabled') then
            local administration = require('plugins.administration')
            return mattata.send_message(
                message.chat.id,
                administration.get_rules(chat_id),
                'markdown'
            )
        end
    end
    if message.chat.type == 'supergroup' and redis:get('administration:' .. message.chat.id .. ':enabled') then
        local administration = require('plugins.administration')
        administration.process_message(
            self,
            message,
            configuration
        )
    end
    if message.new_chat_member then
        if message.new_chat_member.id == self.info.id then
            message.text = '/help'
            local help = require('plugins.help')
            local user_language = mattata.get_user_language(message.from.id)
            local language = require('languages.' .. user_language)
            return help.on_message(self, message, configuration, language)
        end
        local administration = require('plugins.administration')
        local user_language = mattata.get_user_language(message.new_chat_member.id)
        local language = require('languages.' .. user_language)
        administration.on_new_chat_member(
            self,
            message,
            configuration,
            language
        )
    end
    local user_language = mattata.get_user_language(message.from.id)
    local language = require('languages.' .. user_language)
    if message.chat.type ~= 'private' and message.text:match('^%#(%a+)') and redis:get('administration:' .. message.chat.id .. ':enabled') then
        local trigger = message.text:match('^%#(%a+)')
        trigger = '#' .. trigger
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
                    'administration:' .. message.chat.id .. ':custom',
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
                if (plugin.name == 'administration' and not redis:get('administration:' .. message.chat.id .. ':enabled') and not message.text:match('^%/administration') and not message.text:match('^%/chats') and not message.text:match('^%/groups')) or (plugin.name ~= 'administration' and mattata.is_plugin_disabled(
                    plugin.name,
                    message
                )) then
                    if message.chat.type ~= 'private' and not redis:get('chat:' .. message.chat.id .. ':dismiss_disabled_message:' .. plugin.name) then
                        return mattata.send_message(
                            message.chat.id,
                            plugin.name:gsub('^%l', string.upper) .. ' is disabled in this chat.',
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
                            configuration,
                            language
                        )
                    end
                )
                if not success then
                    mattata.exception(
                        self,
                        result,
                        message.from.id .. ': ' .. message.text,
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
    ) and (message.photo or (message.reply_to_message and message.reply_to_message.photo)) then
        if message.reply_to_message then
            message.reply_to_message.text_lower = message.text_lower
            message = message.reply_to_message
        end
        if message.text_lower:match('^wh?at.-this.-') then
            local captionbotai = require('plugins.captionbotai')
            return captionbotai.on_photo_receive(
                self,
                message,
                configuration,
                language
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
        if message.text_lower:match('^' .. configuration.command_prefix .. 'statistics$') or message.text_lower:match('^' .. configuration.command_prefix .. 'stats$') or message.text_lower:match('^group stats?i?s?t?i?c?s?%.?%??!?$') then 
            return statistics.on_message(
                self,
                message,
                configuration,
                language
            )
        end
    end
    if configuration.respond_to_memes then
        if message.text_lower:match('^what the fuck did you just fucking say about me%??$') then
            return mattata.send_message(
                message.chat.id,
                'What the fuck did you just fucking say about me, you little bitch? I\'ll have you know I graduated top of my class in the Navy Seals, and I\'ve been involved in numerous secret raids on Al-Quaeda, and I have over 300 confirmed kills. I am trained in gorilla warfare and I\'m the top sniper in the entire US armed forces. You are nothing to me but just another target. I will wipe you the fuck out with precision the likes of which has never been seen before on this Earth, mark my fucking words. You think you can get away with saying that shit to me over the Internet? Think again, fucker. As we speak I am contacting my secret network of spies across the USA and your IP is being traced right now so you better prepare for the storm, maggot. The storm that wipes out the pathetic little thing you call your life. You\'re fucking dead, kid. I can be anywhere, anytime, and I can kill you in over seven hundred ways, and that\'s just with my bare hands. Not only am I extensively trained in unarmed combat, but I have access to the entire arsenal of the United States Marine Corps and I will use it to its full extent to wipe your miserable ass off the face of the continent, you little shit. If only you could have known what unholy retribution your little "clever" comment was about to bring down upon you, maybe you would have held your fucking tongue. But you couldn\'t, you didn\'t, and now you\'re paying the price, you goddamn idiot. I will shit fury all over you and you will drown in it. You\'re fucking dead, kiddo.'
            )
        elseif message.text_lower:match('^gr8 b8,? m8$') then
            return mattata.send_message(
                message.chat.id,
                'Gr8 b8, m8. I rel8, str8 appreci8, and congratul8. I r8 this b8 an 8/8. Plz no h8, I\'m str8 ir8. Cre8 more, can\'t w8. We should convers8, I won\'t ber8, my number is 8888888, ask for N8. No calls l8 or out of st8. If on a d8, ask K8 to loc8. Even with a full pl8, I always have time to communic8 so don\'t hesit8.'
            )
        elseif configuration.respond_to_memes and message.text_lower:match('^w?h?y so salty%??!?%.?$') and message.chat.type ~= 'private' then
            return mattata.send_sticker(
                message.chat.id,
                'BQADBAADNQIAAlAYNw2gRrzQfFLv9wI'
            )
        elseif configuration.respond_to_memes and message.text_lower:match('^bone? appetite?%??!?%.?$') and message.chat.type ~= 'private' then
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
        elseif configuration.respond_to_memes and message.text_lower:match('^y?o?u a?re? a ?p?r?o?p?e?r? fucc?k?boy?i?%??!?%.?$') and message.chat.type ~= 'private' then
            return mattata.send_message(
                message.chat.id,
                'Sir, I am writing to you on this fateful day to inform you of a tragic reality. While it is unfortunate that I must be the one to let you know, it is for the greater good that this knowledge is made available to you as soon as possible. m8. u r a proper fukboy.'
            )
        elseif configuration.respond_to_lyrics and message.text_lower:match('^do you have the time,? to listen to me whine%??$') and message.chat.type ~= 'private' then
            return mattata.send_sticker(
                message.chat.id,
                'BQADBAADOwIAAlAYNw0I9ggFrg4HigI'
            )
        end
    end
    if message.text:match('^/donate') then
        return mattata.send_message(
            message.chat.id,
            '<b>Hello, ' .. mattata.escape_html(message.from.first_name) .. '!</b>\n\nIf you\'re feeling generous, you can contribute to the mattata project by making a monetary donation of any amount. This will go towards server costs and any time and resources used to develop mattata. This is an optional act, however it is greatly appreciated and your name will also be listed publically on mattata\'s GitHub page (and, eventually, <a href="http://mattata.pw">website</a>).\n\nIf you\'re still interested in helping me out, you can donate <a href="https://paypal.me/wrxck">here</a>. Thank you for your continued support! 😀',
            'html'
        )
    elseif message.text:match('^/license') then
        local output = io.popen('cat LICENSE'):read('*all')
        if output == 'cat: LICENSE: No such file or directory' then
            return
        end
        return mattata.send_message(
            message.chat.id,
            '<pre>' .. mattata.escape_html(output) .. '</pre>',
            'html'
        )
    elseif message.text_lower:match('^' .. self.info.first_name .. ',? .- or .-%?$') and message.text_lower:len() < 50 then
        local choices = {
            message.text_lower:match('^' .. self.info.first_name .. ',? (.-) or .-%??$'),
            message.text_lower:match('^' .. self.info.first_name .. ',? .- or (.-)%??$')
        }
        return mattata.send_reply(
            message,
            choices[math.random(#choices)]
        )
    elseif not mattata.is_plugin_disabled(
        'ai',
        message
    ) and (message.text_lower == 'hi' or message.text_lower == 'hello' or message.text_lower == 'hey' or message.text_lower == 'howdy' or message.text_lower == 'hai') then
        local greetings = {
            '\'Ello!',
            'Hey there!',
            'Hi!',
            'Hello.',
            'Howdy, partner!',
            '\'Sup?',
            'Aye!',
            'Bonjour!',
            'Hai!',
            'Ohai.',
            'Hiiiii.',
            'Hello to you too!',
            'Hallo!',
            'Haiii',
            'Hello'
        }
        return mattata.send_message(
            message.chat.id,
            greetings[math.random(#greetings)]
        )
    elseif message.text_lower:match('^show me message (.-)%.?%!?$') and message.chat.type == 'supergroup' then
        local message_id = message.text_lower:match('message (.-)%.?%!?$')
        message_id = message_id:gsub('number', '')
        message_id = mattata.trim(message_id)
        if tonumber(message_id) == nil then
            return
        end
        local user = message.from.first_name
        if message.from.username then
            user = '@' .. message.from.username
        end
        return mattata.send_message(
            message.chat.id,
            'Here you go ' .. user .. '!',
            nil,
            true,
            false,
            message_id
        )
    elseif message.text_lower:match('^top ?kek%!?%??%.?%.?%.?$') then
        return mattata.send_message(
            message.chat.id,
            'toppest of keks!'
        )
    elseif message.text:match('😡😡😡') then -- Inside joke.
        return mattata.send_reply(
            message,
            'Uh.. is your name Em or something?'
        )
    elseif message.text_lower:match('^back%.?%??%!?$') or message.text_lower:match('^i\'?m back%.?%??%!?$') then
        return mattata.send_message(
            message.chat.id,
            'Welcome back, ' .. message.from.first_name .. '!'
        )
    elseif message.text_lower:match('^brb%.?%??%!?$') then
        return mattata.send_message(
            message.chat.id,
            'Don\'t be too long, ' .. message.from.first_name .. '...'
        )
    elseif message.text_lower:match('^gn%.?%??%!?$') or message.text_lower:match('^good night%.?%??%!?$') then
        return mattata.send_message(
            message.chat.id,
            'Good night, ' .. message.from.first_name .. ' - sleep well! 😄'
        )
    elseif message.text_lower:match('^gm%.?%??%!?$') or message.text_lower:match('^good morning?%.?%??%!?$') then
        return mattata.send_message(
            message.chat.id,
            'Good morning, ' .. message.from.first_name .. '! Did you sleep well? ☺'
        )
    elseif message.text_lower:match('^my name is (.-)%.?%??%!?$') then
        local supposed_name = message.text_lower:match('^my name is (.-)%.?%??%!?$')
        if message.from.first_name:lower() == supposed_name then
            return mattata.send_reply(
                message,
                'No, you silly goose - your name is ' .. message.from.first_name .. '!'
            )
        end
    elseif message.text_lower:match('^wh?at is my name%.?%??%!?$') then
        local name = message.from.first_name
        if message.from.last_name then
            name = name .. ' ' .. message.from.last_name
        end
        return mattata.send_reply(
            message,
            'Why, your name is ' .. name .. '!'
        )
    elseif message.text_lower == 'winrar' then
        return mattata.send_message(
            message.chat.id,
            'Please note that WinRAR is not free software. After a 40 day trial period you must either buy a license or remove it from your computer.'
        )
    elseif message.text == '🍆' then
        return mattata.send_message(
            message.chat.id,
            '🍑'
        )
    elseif message.text == '🍑' then
        return mattata.send_message(
            message.chat.id,
            '🍆'
        )
    elseif message.text_lower == 'ellie' then -- By her request *sigh*
        return mattata.send_reply(
            message,
            '❤'
        )
    elseif message.text == 'LOL' then
        return mattata.send_reply(
            message,
            'LMAO'
        )
    elseif message.text_lower:match('^trump is my president%.?%!?%??$') then
        return mattata.send_reply(
            message,
            'Well, he isn\'t MY president! 😰'
        )
    elseif message.text == '/canter' or message.text == '/cancer@' .. self.info.username then -- Also by Ellie's request
        return mattata.send_message(
            message.chat.id,
            '🏇 🏇 🏇 Canter!\n🏇 🏇 🏇 Canter!\n🏇 🏇 🏇 Canter!\n🏇 🏇 🏇 Canter!\n🏇 🏇 🏇 Canter!'
        )
    elseif message.text_lower:match('^happy new year%.?%??%!?$') and os.date('*t', os.time()).month == 1 then
        return mattata.send_reply(
            message,
            'Aw, thank you! Happy New Year to you too, ' .. message.from.first_name .. '! I can\'t believe it\'s ' .. os.date("*t", os.time()).year .. ' already!'
        )
    elseif mattata.is_global_admin(message.from.id) and message.chat.id == configuration.bug_reports_chat and message.reply_to_message and message.reply_to_message.forward_from and not message.text:match('^' .. configuration.command_prefix) then
        return mattata.send_message(
            message.reply_to_message.forward_from.id,
            'Message from the developer regarding bug report #' .. message.reply_to_message.forward_date .. ':\n<pre>' .. mattata.escape_html(message.text) .. '</pre>',
            'html'
        )
    end
    if not mattata.is_plugin_disabled(
        'ai',
        message
    ) and not message.text:match('^Cancel$') and not message.text:match('^/?s/(.-)/(.-)/?$') and not message.photo and not message.text:match('^%/') and not message.forward_from then
        local ai_type, is_ai = 1, false
        if message.text:match('^[Pp][Ee][Ww][Dd][Ss]%,? .-$') or message.text:match('^.-%,? [Pp][Ee][Ww][Dd][Ss]%??%.?%!?$') then
            ai_type, is_ai = 2, true
            message.text = message.text:match('^[Pp][Ee][Ww][Dd][Ss]%,? (.-)$') or message.text:match('^(.-)%,? [Pp][Ee][Ww][Dd][Ss]%??%.?%!?$')
        elseif message.text:match('^[Ee][Vv][Ii][Ee]%,? .-$') or message.text:match('^.-%,? [Ee][Vv][Ii][Ee]%??%.?%!?$') then
            ai_type, is_ai = 3, true
            message.text = message.text:match('^[Ee][Vv][Ii][Ee]%,? (.-)$') or message.text:match('^(.-)%,? [Ee][Vv][Ii][Ee]%??%.?%!?$')
        elseif message.text:match('^[Bb][Oo][Ii]%,? .-$') or message.text:match('^.-%,? [Bb][Oo][Ii]%??%.?%!?$') then
            ai_type, is_ai = 4, true
            message.text = message.text:match('^[Bb][Oo][Ii]%,? (.-)$') or message.text:match('^(.-)%,? [Bb][Oo][Ii]%??%.?%!?$')
        elseif message.text:match('^[Ww][Ii][Ll][Ll][Ii][Aa][Mm]%,? .-$') or message.text:match('^.-%,? [Ww][Ii][Ll][Ll][Ii][Aa][Mm]%??%.?%!?$') then
            ai_type, is_ai = 5, true
            message.text = message.text:match('^[Ww][Ii][Ll][Ll][Ii][Aa][Mm]%,? (.-)$') or message.text:match('^(.-)%,? [Ww][Ii][Ll][Ll][Ii][Aa][Mm]%??%.?%!?$')
        elseif (message.text:match('^[Mm][Aa][Tt][Tt][Aa][Tt][Aa]%,? .-$') or message.text:match('^.-%,? [Mm][Aa][Tt][Tt][Aa][Tt][Aa]%??%.?%!?$') or message.chat.type == 'private' or (message.reply_to_message and message.reply_to_message.from.id == self.info.id)) and message.text_lower ~= 'pewds' and message.text_lower ~= 'evie' and message.text_lower ~= 'boi'  and message.text_lower ~= 'mattata' and message.text_lower ~= 'william' then
            ai_type, is_ai = 1, true
            message.text = message.text:match('^[Mm][Aa][Tt][Tt][Aa][Tt][Aa]%,? (.-)$') or message.text:match('^(.-)%,? [Mm][Aa][Tt][Tt][Aa][Tt][Aa]%??%.?%!?$') or message.text
        end
        if is_ai then
            local ai = require('plugins.ai')
            return ai.on_message(
                self,
                message,
                configuration,
                language,
                ai_type
            )
        end
    end
    -- If a user executes a command and it's not recognised; provide a response, explaining what's happened and how they can resolve it.
    if (message.text:match('^%/') and message.chat.type == 'private') or (message.chat.type ~= 'private' and message.text:match('^%/%a+@' .. self.info.username)) then
        return mattata.send_reply(
            message,
            'Sorry, I don\'t understand that command.\nTip: Use /help to discover what I can do!'
        )
    end
end

function mattata:on_inline_query(inline_query, configuration)
    if redis:get('global_blacklist:' .. inline_query.from.id) then
        return
    end
    local user_language = mattata.get_user_language(inline_query.from.id)
    local language = require('languages.' .. user_language)
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
                            configuration,
                            language
                        )
                    end
                )
                if not success then
                    mattata.exception(
                        self,
                        result,
                        inline_query.from.id .. ': ' .. inline_query.query,
                        configuration.log_chat
                    )
                    message = nil
                    return
                end
            end
        end
    end
    if inline_query.query ~= '' and not inline_query.query:match('^%/') then
        local ai = require('plugins.ai')
        return ai.on_inline_query(
            self,
            inline_query,
            configuration,
            language
        )
    else
        local help = require('plugins.help')
        return help.on_inline_query(
            self,
            inline_query,
            configuration,
            language
        )
    end
end

function mattata:on_callback_query(callback_query, message, configuration)
    if redis:get('global_blacklist:' .. callback_query.from.id) then
        return
    elseif message.reply_to_message and message.chat.type ~= 'channel' and callback_query.from.id ~= message.reply_to_message.from.id and not callback_query.data:match('^game%:') then
        return mattata.answer_callback_query(
            callback_query.id,
            'Only ' .. message.reply_to_message.from.first_name .. ' can use this!'
        )
    end
    for _, plugin in ipairs(self.plugins) do
        if plugin.name == callback_query.data:match('^(%a+):.-$') and plugin.on_callback_query then
            callback_query.data = callback_query.data:match('^%a+:(.-)$')
            if not callback_query.data then
                return
            end
            local success, result = pcall(
                function()
                    local user_language = mattata.get_user_language(callback_query.from.id)
                    local language = require('languages.' .. user_language)
                    return plugin.on_callback_query(
                        self,
                        callback_query,
                        callback_query.message,
                        configuration,
                        language
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
                    callback_query.from.id .. ': ' .. callback_query.data,
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
    
--]]

function mattata.get_updates(timeout, offset) -- https://core.telegram.org/bots/api#getupdates
    return mattata.request(
        'getUpdates',
        {
            ['timeout'] = timeout,
            ['offset'] = offset
        }
    )
end

function mattata.send_message(chat_id, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendmessage
    if disable_web_page_preview == nil then
        disable_web_page_preview = true
    end
    return mattata.request(
        'sendMessage',
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
end

function mattata.send_reply(message, text, parse_mode, disable_web_page_preview, reply_markup) -- A variant of mattata.send_message(), optimised for sending a message as a reply.
    if disable_web_page_preview == nil then
        disable_web_page_preview = true
    end
    return mattata.request(
        'sendMessage',
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
end

function mattata.forward_message(chat_id, from_chat_id, disable_notification, message_id) -- https://core.telegram.org/bots/api#forwardmessage
    return mattata.request(
        'forwardMessage',
        {
            ['chat_id'] = chat_id,
            ['from_chat_id'] = from_chat_id,
            ['disable_notification'] = disable_notification or false,
            ['message_id'] = message_id
        }
    )
end

function mattata.send_photo(chat_id, photo, caption, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendphoto
    return mattata.request(
        'sendPhoto',
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

function mattata.send_audio(chat_id, audio, caption, duration, performer, title, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendaudio
    return mattata.request(
        'sendAudio',
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

function mattata.send_document(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#senddocument
    return mattata.request(
        'sendDocument',
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

function mattata.send_sticker(chat_id, sticker, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendsticker
    return mattata.request(
        'sendSticker',
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

function mattata.send_video(chat_id, video, duration, width, height, caption, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendvideo
    return mattata.request(
        'sendVideo',
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

function mattata.send_voice(chat_id, voice, caption, duration, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendvoice
    return mattata.request(
        'sendVoice',
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

function mattata.send_location(chat_id, latitude, longitude, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendlocation
    return mattata.request(
        'sendLocation',
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

function mattata.send_venue(chat_id, latitude, longitude, title, address, foursquare_id, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendvenue
    return mattata.request(
        'sendVenue',
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

function mattata.send_contact(chat_id, phone_number, first_name, last_name, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendcontact
    return mattata.request(
        'sendContact',
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

function mattata.send_chat_action(chat_id, action) -- https://core.telegram.org/bots/api#sendchataction
    return mattata.request(
        'sendChatAction',
        {
            ['chat_id'] = chat_id,
            ['action'] = action or 'typing'
        }
    )
end

function mattata.get_user_profile_photos(user_id, offset, limit) -- https://core.telegram.org/bots/api#getuserprofilephotos
    return mattata.request(
        'getUserProfilePhotos',
        {
            ['user_id'] = user_id,
            ['offset'] = offset,
            ['limit'] = limit
        }
    )
end

function mattata.get_file(file_id) -- https://core.telegram.org/bots/api#getfile
    return mattata.request(
        'getFile',
        {
            ['file_id'] = file_id
        }
    )
end

function mattata.kick_chat_member(chat_id, user_id) -- https://core.telegram.org/bots/api#kickchatmember
    return mattata.request(
        'kickChatMember',
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        }
    )
end

function mattata.leave_chat(chat_id) -- https://core.telegram.org/bots/api#leavechat
    return mattata.request(
        'leaveChat',
        {
            ['chat_id'] = chat_id
        }
    )
end

function mattata.unban_chat_member(chat_id, user_id) -- https://core.telegram.org/bots/api#unbanchatmember
    return mattata.request(
        'unbanChatMember',
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        }
    )
end

function mattata.get_chat_administrators(chat_id) -- https://core.telegram.org/bots/api#getchatadministrators
    return mattata.request(
        'getChatAdministrators',
        {
            ['chat_id'] = chat_id
        }
    )
end

function mattata.get_chat_members_count(chat_id) -- https://core.telegram.org/bots/api#getchatmemberscount
    return mattata.request(
        'getChatMembersCount',
        {
            ['chat_id'] = chat_id
        }
    )
end

function mattata.get_chat_member(chat_id, user_id) -- https://core.telegram.org/bots/api#getchatmember
    return mattata.request(
        'getChatMember',
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        }
    )
end

function mattata.answer_callback_query(callback_query_id, text, show_alert, url) -- https://core.telegram.org/bots/api#answercallbackquery
    return mattata.request(
        'answerCallbackQuery',
        {
            ['callback_query_id'] = callback_query_id,
            ['text'] = text,
            ['show_alert'] = show_alert or false,
            ['url'] = url
        }
    )
end

function mattata.edit_message_text(chat_id, message_id, text, parse_mode, disable_web_page_preview, reply_markup) -- https://core.telegram.org/bots/api#editmessagetext
    return mattata.request(
        'editMessageText',
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['disable_web_page_preview'] = disable_web_page_preview,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.edit_message_caption(chat_id, message_id, inline_message_id, caption, reply_markup) -- https://core.telegram.org/bots/api#editmessagecaption
    return mattata.request(
        'editMessageCaption',
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id,
            ['caption'] = caption,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.edit_message_reply_markup(chat_id, message_id, inline_message_id, reply_markup) -- https://core.telegram.org/bots/api#editmessagereplymarkup
    return mattata.request(
        'editMessageReplyMarkup',
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.answer_inline_query(inline_query_id, results, cache_time, is_personal, next_offset, switch_pm_text, switch_pm_parameter) -- https://core.telegram.org/bots/api#answerinlinequery
    return mattata.request(
        'answerInlineQuery',
        {
            ['inline_query_id'] = inline_query_id,
            ['results'] = results,
            ['cache_time'] = cache_time or 0,
            ['is_personal'] = is_personal or false,
            ['next_offset'] = next_offset,
            ['switch_pm_text'] = switch_pm_text,
            ['switch_pm_parameter'] = switch_pm_parameter
        }
    )
end

function mattata.send_game(chat_id, game_short_name, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendgame
    return mattata.request(
        'sendGame',
        {
            ['chat_id'] = chat_id,
            ['game_short_name'] = game_short_name,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function mattata.set_game_score(user_id, score, force, disable_edit_message, chat_id, message_id, inline_message_id) -- https://core.telegram.org/bots/api#setgamescore
    return mattata.request(
        'setGameScore',
        {
            ['user_id'] = user_id,
            ['score'] = score,
            ['force'] = force,
            ['disable_edit_message'] = disable_edit_message or false,
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id
        }
    )
end

function mattata.get_game_high_scores(user_id, chat_id, message_id, inline_message_id) -- https://core.telegram.org/bots/api#getgamehighscores
    return mattata.request(
        'getGameHighScores',
        {
            ['user_id'] = user_id,
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id
        }
    )
end

function mattata.get_chat(chat_id) -- https://core.telegram.org/bots/api#getchat
    return mattata.request(
        'getChat',
        {
            ['chat_id'] = chat_id
        }
    )
end

-- PWRTelegram methods

function mattata.get_chat_pwr(chat_id, full)
    local success = mattata.request(
        'getChat',
        {
            ['chat_id'] = chat_id,
            ['full'] = full or false
        },
        nil,
        'https://api.pwrtelegram.xyz/bot'
    )
    if not success then
        return false
    elseif success.result.type == 'user' then
        success.result.type = 'private'
    end
    return success
end

function mattata.get_chat_by_file_pwr(file_id)
    return mattata.request(
        'getChatByFile',
        {
            ['file_id'] = file_id
        },
        nil,
        'https://api.pwrtelegram.xyz/bot'
    )
end

function mattata.get_message_pwr(chat_id, message_id)
    return mattata.request(
        'getMessage',
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id
        },
        nil,
        'https://api.pwrtelegram.xyz/bot'
    )
end

function mattata.add_chat_user_pwr(chat_id, user_id, fwd_limit)
    return mattata.request(
        'addChatUser',
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id,
            ['fwd_limit'] = fwd_limit or nil
        },
        nil,
        'https://beta.pwrtelegram.xyz/bot'
    )
end

function mattata.send_file_pwr(chat_id, file, caption, duration, performer, title, width, height, file_name, disable_notification, reply_to_message_id, reply_markup)
    return mattata.request(
        'sendFile',
        {
            ['chat_id'] = chat_id,
            ['caption'] = caption or nil,
            ['duration'] = duration or nil,
            ['performer'] = performer or nil,
            ['title'] = title or nil,
            ['width'] = width or nil,
            ['height'] = height or nil,
            ['file_name'] = file_name or nil,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id or nil,
            ['reply_markup'] = reply_markup or nil
        },
        {
            ['file'] = file
        },
        'https://beta.pwrtelegram.xyz/bot'
    )
end

--[[

    General functions for general use throughout mattata's
    framework and plugins.

]]--

function mattata.is_plugin_disabled(plugin, message)
    if type(message) == 'table' then
        message = message.chat.id
    end
    if redis:hget(
        'chat:' .. message .. ':disabled_plugins',
        plugin
    ) == 'true' then
        return true
    end
    return false
end

function mattata.get_redis_hash(k, v)
    if type(k) == 'table' then
        k = k.chat.id
    end
    return 'chat:' .. k .. ':' .. v
end

function mattata.get_user_redis_hash(k, v)
    if type(k) == 'table' then
        k = k.id
    end
    return 'user:' .. k .. ':' .. v
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
            '<pre>' .. output .. '</pre>',
            'html'
        )
    end
end

function mattata.download_file(url, name)
    name = name or os.time() .. '.' .. url:match('.+/%.(.-)$')
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
    file:write(table.concat(body))
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
        print(1)
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
    elseif redis:get('mods:' .. chat_id .. ':' .. user_id) then
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

function mattata.resolve_username(input)
    local success = mattata.get_chat_pwr(input)
    if not success then
        return input
    elseif success.result.type ~= 'private' then
        return input
    end
    return tonumber(success.result.id)
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
    str = tostring(str)
    str = str:gsub('%_', '\\_'):gsub('%[', '\\['):gsub('%*', '\\*'):gsub('%`', '\\`')
    return str
end

function mattata.escape_html(str)
    str = tostring(str)
    str = str:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
    return str
end

mattata.commands_meta = {}

mattata.commands_meta.__index = mattata.commands_meta

function mattata.commands_meta:command(command)
    table.insert(
        self.table,
        '^' .. self.command_prefix .. command .. '$'
    )
    table.insert(
        self.table,
        '^' .. self.command_prefix .. command .. '@' .. self.username:lower() .. '$'
    )
    table.insert(
        self.table,
        '^' .. self.command_prefix .. command .. '%s+[^%s]*'
    )
    table.insert(
        self.table,
        '^' .. self.command_prefix .. command .. '@' .. self.username:lower() .. '%s+[^%s]*'
    )
    return self
end

function mattata.commands(username, command_prefix, command_table)
    local self = setmetatable(
        {},
        mattata.commands_meta
    )
    self.username = username
    self.command_prefix = command_prefix
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
        local count = #message.photo
        return message.photo[count].file_id
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

function mattata.utf8_len(s)
    local chars = 0
    for i = 1, s:len() do
        local b = s:byte(i)
        if b < 128 or b >= 192 then
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
        'chat:' .. chat.id .. ':info',
        'id'
    ) then
        print('New chat added to database [' .. chat.id .. ']')
    end
    redis:hset(
        'chat:' .. chat.id .. ':info',
        'title',
        chat.title
    )
    redis:hset(
        'chat:' .. chat.id .. ':info',
        'type',
        chat.type
    )
    if chat.username then
        redis:hset(
            'chat:' .. chat.id .. ':info',
            'username',
            chat.username
        )
    end
    redis:hset(
        'chat:' .. chat.id .. ':info',
        'id',
        chat.id
    )
    return chat
end

function mattata.process_user(user)
    if not user.id or not user.first_name then
        return
    end
    user.id_str = tostring(user.id)
    user.name = user.first_name
    if user.last_name then
        user.name = user.name .. ' ' .. user.last_name
    end
    if not redis:hget(
        'user:' .. user.id .. ':info',
        'id'
    ) then
        print('New user added to database [' .. user.id .. ']')
    end
    redis:hset(
        'user:' .. user.id .. ':info',
        'name',
        user.name
    )
    redis:hset(
        'user:' .. user.id .. ':info',
        'first_name',
        user.first_name
    )
    if user.last_name then
        redis:hset(
            'user:' .. user.id .. ':info',
            'last_name',
            user.last_name
        )
    end
    if user.username then
        redis:hset(
            'user:' .. user.id .. ':info',
            'username',
            user.username
        )
    end
    redis:hset(
        'user:' .. user.id .. ':info',
        'id',
        user.id
    )
    return user
end

function mattata.process_message(message)
    message.text = message.text or message.caption or ''
    message.text = message.text:gsub('^%/(%a+)%_', '/%1 ')
    message.is_media = mattata.is_media(message)
    message.media_type = mattata.media_type(message)
    message.file_id = mattata.file_id(message)
    message.is_service_message = mattata.is_service_message(message)
    message.service_message = mattata.service_message(message)
    message.text_lower = message.text:lower()
    message.text_upper = message.text:upper()
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

function mattata.get_user_language(id)
    local language = redis:hget(
        'user:' .. id .. ':language',
        'language'
    )
    if not language then
        language = 'en'
    end
    return language
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

function mattata.escape_bash(str)
    str = tostring(str)
    str = str:gsub('$', ''):gsub('%^', ''):gsub('&', ''):gsub('|', ''):gsub(';', '')
    return str
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
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function mattata.index_chat(input)
    if tonumber(input) == nil and not input:match('^%@') then
        input = '@' .. input
    end
    local chats = mattata.get_chat_pwr(
        tostring(input),
        true
    )
    for k, v in pairs(chats.result.participants) do
        mattata.process_user(v.user)
    end
end

return mattata