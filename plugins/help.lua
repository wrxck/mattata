--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local help = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local redis = require('mattata-redis')
local json = require('dkjson')
local configuration = require('configuration')

function help:init()
    help.commands = mattata.commands(
        self.info.username
    ):command('help')
     :command('start').table
    help.help = [[/help [plugin] - A help-orientated menu is sent if no arguments are given. If arguments are given, usage information for the given plugin is sent instead. Alias: /start.]]
end

function help.get_initial_keyboard()
    return json.encode(
        {
            ['inline_keyboard'] = {
                {
                    {
                        ['text'] = 'Links',
                        ['callback_data'] = 'help:links'
                    },
                    {
                        ['text'] = 'Administration',
                        ['callback_data'] = 'help:ahelp'
                    },
                    {
                        ['text'] = 'Commands',
                        ['callback_data'] = 'help:cmds'
                    }
                }
            }
        }
    )
end

function help.get_plugin_page(arguments_list, page)
    local plugin_count = #arguments_list
    local page_begins_at = tonumber(page) * 10 - 9
    local page_ends_at = tonumber(page_begins_at) + 9
    if tonumber(page_ends_at) > tonumber(plugin_count) then
        page_ends_at = tonumber(plugin_count)
    end
    local page_plugins = {}
    for i = tonumber(page_begins_at), tonumber(page_ends_at) do
        table.insert(
            page_plugins,
            arguments_list[i]
        )
    end
    return table.concat(
        page_plugins,
        '\n'
    )
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
    local output = mattata.get_inline_help(inline_query.query)
    local success = mattata.answer_inline_query(
        inline_query.id,
        json.encode(
            output
        )
    )
    if not success then
        return mattata.answer_inline_query(
            inline_query.id,
            json.encode(
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = 'No results found!',
                    ['description'] = string.format(
                        'There were not enough, either that or there were too many, results found for "%s", please try and be more specific!',
                        inline_query.query
                    ),
                    ['input_message_content'] = {
                        ['message_text'] = string.format(
                            'There were not enough, either that or there were too many, results found for "%s", please try and be more specific!',
                            inline_query.query
                        )
                    }
                }
            )
        )
    end
end

function help:on_callback_query(callback_query, message, configuration)
    if callback_query.data == 'cmds' then
        local arguments_list = mattata.get_help()
        local plugin_count = #arguments_list
        local page_count = math.floor(
            tonumber(plugin_count) / 10
        )
        if math.floor(
            tonumber(plugin_count) / 10
        ) ~= tonumber(plugin_count) / 10 then
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
            help.get_plugin_page(
                arguments_list,
                1
            ) .. '\n\nArguments: <required> [optional]\n\nSearch for a feature or get help with a command by using my inline search functionality - just mention me in any chat using the syntax @' .. self.info.username .. ' <search query>.',
            nil,
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^results%:%d*$') then
        local new_page = callback_query.data:match('^results%:(%d*)$')
        local arguments_list = mattata.get_help()
        local plugin_count = #arguments_list
        local page_count = math.floor(
            tonumber(plugin_count) / 10
        )
        if math.floor(
            tonumber(plugin_count) / 10
        ) ~= tonumber(plugin_count) / 10 then
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
                        ['callback_data'] = 'help:results:' .. math.floor(
                            tonumber(new_page) - 1
                        )
                    },
                    {
                        ['text'] = new_page .. '/' .. page_count,
                        ['callback_data'] = 'help:pages:' .. new_page .. ':' .. page_count
                    },
                    {
                        ['text'] = 'Next →',
                        ['callback_data'] = 'help:results:' .. math.floor(
                            tonumber(new_page) + 1
                        )
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
            help.get_plugin_page(
                arguments_list,
                new_page
            ) .. '\n\nArguments: <required> [optional]\n\nSearch for a feature or get help with a command by using my inline search functionality - just mention me in any chat using the syntax @' .. self.info.username .. ' <search query>.',
            nil,
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data:match('^pages%:%d*%:%d*$') then
        local current_page, total_pages = callback_query.data:match('^pages%:(%d*)%:(%d*)$')
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
        local keyboard = {
            ['inline_keyboard'] = {
                {
                    {
                        ['text'] = 'mattata Development',
                        ['url'] = 'https://t.me/joinchat/AAAAAEDWD1KbS5gSkP3pSA'
                    },
                    {
                        ['text'] = 'mattata\'s Channel',
                        ['url'] = 'https://t.me/mattata'
                    }
                },
                {
                    {
                        ['text'] = 'Source Code',
                        ['url'] = 'https://github.com/wrxck/mattata'
                    },
                    {
                        ['text'] = 'Donate',
                        ['url'] = 'https://paypal.me/wrxck'
                    },
                    {
                        ['text'] = 'Rate Me',
                        ['url'] = 'https://t.me/storebot?start=mattatabot'
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
            'Below are some links you might find useful:',
            nil,
            true,
            json.encode(keyboard)
        )
    elseif callback_query.data == 'back' then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            string.format(
                [[Hi *%s*, I'm %s - a multi-purpose bot written in Lua by [Matthew Hesketh](https://t.me/wrxck), with many features including the ability to talk to you and administrate your chats. Use the buttons below to discover more about what I can do for you. For help with commands, you can use my interactive inline help menu - just mention me in any chat using the following syntax: `@%s <search query/pattern>`. To keep up-to-date with the latest news about me, feel free to join [my channel.](https://t.me/mattata)]],
                mattata.escape_markdown(callback_query.from.first_name),
                mattata.escape_markdown(self.info.name),
                self.info.username
            ),
            'markdown',
            true,
            help.get_initial_keyboard()
        )
    end
end

function help:on_message(message, configuration)
    return mattata.send_message(
        message.chat.id,
        string.format(
            [[Hi *%s*, I'm %s - a multi-purpose bot written in Lua by [Matthew Hesketh](https://t.me/wrxck), with many features including the ability to talk to you and administrate your chats. Use the buttons below to discover more about what I can do for you. For help with commands, you can use my interactive inline help menu - just mention me in any chat using the following syntax: `@%s <search query/pattern>`. To keep up-to-date with the latest news about me, feel free to join [my channel.](https://t.me/mattata)]],
            mattata.escape_markdown(message.from.first_name),
            mattata.escape_markdown(self.info.name),
            self.info.username
        ),
        'markdown',
        true,
        false,
        nil,
        help.get_initial_keyboard()
    )
end

return help