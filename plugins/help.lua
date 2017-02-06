--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local help = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local redis = require('mattata-redis')
local json = require('dkjson')
local configuration = require('configuration')

function help:init(configuration)
    help.arguments_list = {}
    for _, plugin in ipairs(self.plugins) do
        if plugin.arguments then
            table.insert(
                help.arguments_list,
                '• ' .. configuration.command_prefix .. plugin.arguments
            )
            if plugin.help then
                plugin.help_word = mattata.get_word(plugin.arguments)
            end
        end
    end
    table.insert(
        help.arguments_list,
        '• ' .. configuration.command_prefix .. 'help <plugin>'
    )
    table.sort(help.arguments_list)
    help.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('help'):command('start').table
    help.help = '/help <plugin> - Usage information for the given plugin.'
end

function help.get_plugin_page(arguments_list, page)
    local plugin_count = #arguments_list
    local page_begins_at = tonumber(page) * 10 - 9
    local page_ends_at = tonumber(page_begins_at) + 9
    if tonumber(page_ends_at) > tonumber(plugin_count) then page_ends_at = tonumber(plugin_count) end
    local pagePlugins = {}
    for i = tonumber(page_begins_at), tonumber(page_ends_at) do table.insert(pagePlugins, arguments_list[i]) end
    return table.concat(pagePlugins, '\n')
end

function help.get_initial_message(message, is_edit, from)
    local keyboard = {
        ['inline_keyboard'] = {}
    }
    keyboard = help.get_keyboard_row(keyboard, 'Links', 'help:links', 'Administration', 'help:ahelp', 'Commands', 'help:cmds')
    keyboard = help.get_keyboard_row(keyboard, 'FAQ', 'help:faq', 'Plugins', 'help:plugins', 'About', 'help:about')
    local text = string.format(
        'Hi *%s*, I\'m %s - a multi-purpose & administrative bot written in Lua.\nUse the buttons below to discover what I can do for you!',
        from,
        configuration.info.first_name
    )
    keyboard = json.encode(keyboard)
    if is_edit then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            text,
            'markdown',
            true,
            keyboard
        )
    end
    return mattata.send_message(
        message.chat.id,
        text,
        'markdown',
        true,
        false,
        message.message_id,
        keyboard
    )
end

function help.get_keyboard_row(keyboard, text1, callback1, text2, callback2, text3, callback3)
    table.insert(
        keyboard.inline_keyboard,
        {
            {
                ['text'] = text1,
                ['callback_data'] = callback1
            },
            {
                ['text'] = text2,
                ['callback_data'] = callback2
            },
            {
                ['text'] = text3,
                ['callback_data'] = callback3
            }
        }
    )
    return keyboard
end

function help.get_back_keyboard()
    return json.encode(
        {
            ['inline_keyboard'] = {
                {
                    {
                        ['text'] = 'Back',
                        ['callback_data'] = 'help:back'
                    }
                }
            }
        }
    )
end

function help:on_inline_query(inline_query, configuration)
    local results = json.encode({
        {
            ['type'] = 'article',
            ['id'] = '1',
            ['title'] = 'Begin typing to speak with ' .. self.info.first_name .. '!',
            ['description'] = '@' .. self.info.username .. ' <text> - Speak with ' .. self.info.first_name .. '!',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' <text> - Speak with ' .. self.info.first_name .. '!'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/mattata.png'
        },
        {
            ['type'] = 'article',
            ['id'] = '2',
            ['title'] = configuration.command_prefix .. 'id',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'id <user/group> - Get information about a user/group.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'id <user/group> - Get information about a user/group.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/id.png'
        },
        {
            ['type'] = 'article',
            ['id'] = '3',
            ['title'] = configuration.command_prefix .. 'apod',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'apod - Astronomical photo of the day, from NASA.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'apod - Astronomical photo of the day, from NASA.' 
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/apod.jpg'
        },
        {
            ['type'] = 'article',
            ['id'] = '4',
            ['title'] = configuration.command_prefix .. 'gif',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'gif <query> - Search for a gif on GIPHY.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'gif <query> - Search for a gif on GIPHY.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/giphy.png'
        },
        {
            ['type'] = 'article',
            ['id'] = '5',
            ['title'] = configuration.command_prefix .. 'np',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'np - See what you last listened to on last.fm.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'np - See what you last listened to on last.fm.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/lastfm.png'
        },
        {
            ['type'] = 'article',
            ['id'] = '6',
            ['title'] = configuration.command_prefix .. 'translate',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'translate <language> <text> - Translate text between different languages.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'translate <language> <text> - Translate text between different languages.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/translate.jpg'
        },
        {
            ['type'] = 'article',
            ['id'] = '7',
            ['title'] = configuration.command_prefix .. 'lyrics',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'lyrics <song> - Get the lyrics to a song.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'lyrics <song> - Get the lyrics to a song.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/lyrics.png'
        },
        {
            ['type'] = 'article',
            ['id'] = '8',
            ['title'] = configuration.command_prefix .. 'catfact',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'catfact - Discover something new about cats.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'catfact - Discover something new about cats.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/catfact.jpg'
        },
        {
            ['type'] = 'article',
            ['id'] = '9',
            ['title'] = configuration.command_prefix .. 'ninegag',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'ninegag - View the latest images on 9gag.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'ninegag - View the latest images on 9gag.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/ninegag.png'
        },
        {
            ['type'] = 'article',
            ['id'] = '10',
            ['title'] = configuration.command_prefix .. 'urban',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'urban <query> - Search the urban dictionary.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'urban <query> - Search the urban dictionary.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/urbandictionary.jpg'
        },
        {
            ['type'] = 'article',
            ['id'] = '11',
            ['title'] = configuration.command_prefix .. 'cat',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'cat - Get a random photo of a cat. Meow!',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'cat - Get a random photo of a cat. Meow!'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/cats.png'
        },
        {
            ['type'] = 'article',
            ['id'] = '12',
            ['title'] = configuration.command_prefix .. 'flickr <query>',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'flickr <query> - Search for an image on Flickr.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'flickr <query> - Search for an image on Flickr.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/flickr.png'
        },
        {
            ['type'] = 'article',
            ['id'] = '13',
            ['title'] = configuration.command_prefix .. 'location <query>',
            ['description'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'location <query> - Sends a location from Google Maps.',
            ['input_message_content'] = {
                ['message_text'] = '@' .. self.info.username .. ' ' .. configuration.command_prefix .. 'location <query> - Sends a location from Google Maps.'
            },
            ['thumb_url'] = 'http://matthewhesketh.com/mattata/location.png'
        }
    })
    return mattata.answer_inline_query(
        inline_query.id,
        results
    )
end

function help:on_callback_query(callback_query, message, configuration, language)
    if not message.reply_to_message then
        return
    end
    if callback_query.data == 'cmds' then
        local plugin_count = #help.arguments_list
        local page_count = math.floor(tonumber(plugin_count) / 10)
        if math.floor(tonumber(plugin_count) / 10) ~= tonumber(plugin_count) / 10 then
            page_count = page_count + 1
        end
        local keyboard = {
            ['inline_keyboard'] = {
                {
                    {
                        ['text'] = '← Previous',
                        ['callback_data'] = 'help:results:0'
                    },
                    {
                        ['text'] = '1/' .. page_count,
                        ['callback_data'] = 'help:pages:1:' .. page_count
                    },
                    {
                        ['text'] = 'Next →',
                        ['callback_data'] = 'help:results:2'
                    }
                },
                {
                    {
                        ['text'] = 'Back',
                        ['callback_data'] = 'help:back'
                    }
                }
            }
        }
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            help.get_plugin_page(help.arguments_list, 1),
            nil,
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^results:(.-)$') then
        local new_page = callback_query.data:match('^results:(.-)$')
        local plugin_count = #help.arguments_list
        local page_count = math.floor(tonumber(plugin_count) / 10)
        if math.floor(tonumber(plugin_count) / 10) ~= tonumber(plugin_count) / 10 then
            page_count = page_count + 1
        end
        if tonumber(new_page) > tonumber(page_count) then
            new_page = 1
        elseif tonumber(new_page) < 1 then
            new_page = tonumber(page_count)
        end
        local keyboard = {
            ['inline_keyboard'] = {
                {
                    {
                        ['text'] = '← Previous',
                        ['callback_data'] = 'help:results:' .. math.floor(tonumber(new_page) - 1)
                    },
                    {
                        ['text'] = new_page .. '/' .. page_count,
                        ['callback_data'] = 'help:pages:' .. new_page .. ':' .. page_count
                    },
                    {
                        ['text'] = 'Next →',
                        ['callback_data'] = 'help:results:' .. math.floor(tonumber(new_page) + 1)
                    }
                },
                {
                    {
                        ['text'] = 'Back',
                        ['callback_data'] = 'help:back'
                    }
                }
            }
        }
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            help.get_plugin_page(help.arguments_list, new_page),
            nil,
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^pages:(.-):(.-)$') then
        local current_page, total_pages = callback_query.data:match('^pages:(.-):(.-)$')
        return mattata.answer_callback_query(
            callback_query.id,
            'You are on page ' .. current_page .. ' of ' .. total_pages .. '!'
        )
    elseif callback_query.data == 'ahelp' then
        local administration_help_text = 'I can perform many administrative actions in your groups, just add me as an administrator and send /administration to adjust the settings for your group. Here are some administrative commands and a brief comment regarding what they do:\n\n- /pin <text> - Send a Markdown-formatted message which can be edited by using the same command with different text, to save you from having to re-pin a message if you can\'t edit it (which happens if the message is older than 48 hours)\n- /ban - Ban a user by replying to one of their messages, or by specifying them by username/ID\n- /kick - Kick (ban and then unban) a user by replying to one of their messages, or by specifying them by username/ID\n- /unban - Unban a user by replying to one of their messages, or by specifying them by username/ID\n- /setrules <text> - Set the given Markdown-formatted text as the group rules, which will be sent whenever somebody uses /rules\n- /setwelcome - Set the given Markdown-formatted text as a welcome message that will be sent every time a user joins your group (the welcome message can be disabled in the administration menu, accessible via /administration)\n- /warn - Warn a user, and ban them when they hit the maximum number of warnings\n- /mod - Promote the replied-to user, giving them access to administrative commands such as /ban, /kick, /warn etc. (this is useful when you don\'t want somebody to have the ability to delete messages!)\n- /demod - Demote the replied-to user, stripping them from their moderation status and revoking their ability to use administrative commands\n- /staff - View the group\'s creator, administrators, and moderators in a neatly-formatted list\n- /report - Forwards the replied-to message to all administrators and alerts them of the current situation\n- /setlink <URL> - Set the group\'s link to the given URL, which will be sent whenever somebody uses /link\n- /links <text> - Whitelists all of the Telegram links found in the given text (includes @username links)'
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            administration_help_text,
            'markdown',
            true,
            help.get_back_keyboard()
        )
    elseif callback_query.data == 'links' then
        local help_links = language.official_links
        local keyboard = {}
        keyboard.inline_keyboard = {
            {
                {
                    ['text'] = 'Development',
                    ['url'] = 'https://telegram.me/joinchat/DTcYUEDWD1IgrvQDrkKH0w'
                },
                {
                    ['text'] = 'Channel',
                    ['url'] = 'https://telegram.me/mattata'
                }
            },
            {
                {
                    ['text'] = 'Source',
                    ['url'] = 'https://github.com/matthewhesketh/mattata'
                },
                {
                    ['text'] = 'Donate',
                    ['url'] = 'https://paypal.me/wrxck'
                },
                {
                    ['text'] = 'Rate',
                    ['url'] = 'https://telegram.me/storebot?start=mattatabot'
                }
            },
            {
                {
                    ['text'] = 'Back',
                    ['callback_data'] = 'help:back'
                }
            }
        }
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            help_links,
            'markdown',
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data == 'plugins' then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            '<b>Hello, ' .. mattata.escape_html(message.reply_to_message.from.first_name) .. '!</b>\n\nTo disable a specific plugin, use \'/plugins disable &lt;plugin&gt;\'. To enable a specific plugin, use \'/plugins enable &lt;plugin&gt;\'.\n\nFor the sake of convenience, you can disable all of my non-core plugins by using \'/plugins disable all\'. To disable all of my non-core plugins, you can use \'/plugins disable all\'.\n\nTo see a list of plugins you\'ve disabled, use \'/plugins disabled\'. For a list of plugins that can be toggled and haven\'t been disabled in this chat yet, use \'/plugins enabled\'.\n\nA list of all toggleable plugins can be viewed by using \'/plugins list\'.',
            'html',
            true,
            help.get_back_keyboard()
        )
    elseif callback_query.data == 'back' then
        return help.get_initial_message(message, true, mattata.escape_markdown(callback_query.from.first_name))
    elseif callback_query.data == 'faq' then
        return mattata.edit_message_text(message.chat.id, message.message_id, language.help_confused:gsub('COMMANDPREFIX', configuration.command_prefix), 'markdown', true, help.get_back_keyboard())
    elseif callback_query.data == 'about' then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            language.help_about,
            'markdown',
            true,
            help.get_back_keyboard()
        )
    end
end

function help:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if input then
        for _, plugin in ipairs(self.plugins) do
            if plugin.help_word == input:gsub('^' .. configuration.command_prefix, '') then
                return mattata.send_message(
                    message.chat.id,
                    '*Help for* ' .. mattata.escape_markdown(plugin.help_word) .. '*:*\n' .. plugin.help,
                    'markdown'
                )
            end
        end
        return mattata.send_message(
            message.chat.id,
            language.no_documented_help,
            'markdown'
        )
    end
    local keyboard = {}
    keyboard.inline_keyboard = {
        {
            {
                ['text'] = 'Links',
                ['callback_data'] = 'help:links'
            },
            {
                ['text'] = 'Administration',
                ['callback_data'] = 'help:administration'
            },
            {
                ['text'] = 'Commands',
                ['callback_data'] = 'help:commands'
            }
        },
        {
            {
                ['text'] = 'Help',
                ['callback_data'] = 'help:help'
            },
            {
                ['text'] = 'Plugins',
                ['callback_data'] = 'help:plugins'
            },
            {
                ['text'] = 'About',
                ['callback_data'] = 'help:about'
            }
        },
        {
            {
                ['text'] = 'Add me to a group!',
                ['url'] = 'https://telegram.me/' .. self.info.username .. '?startgroup=c'
            }
        }
    }
    return help.get_initial_message(message, false, mattata.escape_markdown(message.from.first_name))
end

return help