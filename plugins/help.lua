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
    help.help = configuration.command_prefix .. 'help <plugin> - Usage information for the given plugin.'
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
    if callback_query.data == 'commands' then
        local plugin_count = #help.arguments_list
        local page_count = math.floor(tonumber(plugin_count) / 10) + 1
        local keyboard = {}
        keyboard.inline_keyboard = {
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
        local page_count = math.floor(tonumber(plugin_count) / 10) + 1
        if tonumber(new_page) > tonumber(page_count) then
            new_page = 1
        elseif tonumber(new_page) < 1 then
            new_page = tonumber(page_count)
        end
        local keyboard = {}
        keyboard.inline_keyboard = {
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
    elseif callback_query.data == 'administration' then
        local administration_help_text = 'I take advantage of the administrative methods the Telegram bot API offers in the following ways:\n\nYou can <b>kick</b>, <b>ban</b> and <b>unban</b> users from groups you administrate by doing the following:\n\n- Add me to the group you want me to administrate, and grant me the necessary permissions to do my job by promoting me to an administrator. You\'ll know I\'m an administrator when you see a ⭐️ next to my name in the list of users.\n\nWhen the time comes to perform an administrative action, there are two ways to target the user:\n\n- You can specify the user by their @username (or their numerical ID) as an argument to the command - I then do some further checks to make sure the user you specified meets the necessary criteria (i.e. the user exists, they\'re present in the chat, and not an administrator) - don\'t worry, I\'m a bot, I can do this in no time at all!\n- You can target the user by replying to one of their messages with the desired action-corresponding command\n\n<i>If you specify the user by command arguments, but send the message as a reply, I will target the user you specified as the command arguments by default - which means the replied-to user will only be subject to the specified action when you send the command with nothing next to it!</i>'
        local keyboard = {}
        keyboard.inline_keyboard = {
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
            administration_help_text,
            'html',
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data == 'links' then
        local help_links = language.official_links
        local keyboard = {}
        keyboard.inline_keyboard = {
            {
                {
                    ['text'] = 'Support',
                    ['url'] = 'https://telegram.me/joinchat/DTcYUD7ELOondGVro-8PZQ'
                },
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
        local keyboard = {}
        keyboard.inline_keyboard = {
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
            '<b>Hello, ' .. mattata.escape_html(message.reply_to_message.from.first_name) .. '!</b>\n\nTo disable a specific plugin, use \'' .. configuration.command_prefix .. 'plugins disable &lt;plugin&gt;\'. To enable a specific plugin, use \'' .. configuration.command_prefix .. 'plugins enable &lt;plugin&gt;\'.\n\nFor the sake of convenience, you can disable all of my non-core plugins by using \'' .. configuration.command_prefix .. 'plugins disable all\'. To disable all of my non-core plugins, you can use \'' .. configuration.command_prefix .. 'plugins disable all\'.\n\nTo see a list of plugins you\'ve disabled, use \'' .. configuration.command_prefix .. 'plugins disabled\'. For a list of plugins that can be toggled and haven\'t been disabled in this chat yet, use \'' .. configuration.command_prefix .. 'plugins enabled\'.\n\nA list of all toggleable plugins can be viewed by using \'' .. configuration.command_prefix .. 'plugins list\'.',
            'html',
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data == 'back' then
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
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            language.help_introduction:gsub('NAME', '*' .. mattata.escape_markdown(callback_query.from.first_name) .. '*'):gsub('MATTATA', self.info.first_name):gsub('COMMANDPREFIX', configuration.command_prefix),
            'markdown',
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data == 'help' then
        local keyboard = {}
        keyboard.inline_keyboard = {
            {
                {
                    ['text'] = 'Back',
                    ['callback_data'] = 'help:back'
                }
            }
        }
        return mattata.edit_message_text(message.chat.id, message.message_id, language.help_confused:gsub('COMMANDPREFIX', configuration.command_prefix), 'markdown', true, json.encode(keyboard))
    elseif callback_query.data == 'about' then
        local keyboard = {}
        keyboard.inline_keyboard = {
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
            language.help_about,
            'markdown',
            true,
            json.encode(keyboard)
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
    return mattata.send_message(
        message.chat.id,
        language.help_introduction:gsub('NAME', '*' .. mattata.escape_markdown(message.from.first_name) .. '*'):gsub('MATTATA', self.info.first_name):gsub('COMMANDPREFIX', configuration.command_prefix),
        'markdown',
        true,
        false,
        message.message_id,
        json.encode(keyboard)
    )
end

return help