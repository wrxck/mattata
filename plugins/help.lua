--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local help = {}

local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local redis = require('mattata-redis')
local configuration = require('configuration')

function help:init()
    help.commands = mattata.commands(
        self.info.username
    ):command('help')
     :command('start').table
    help.help = [[/help [plugin] - A help-orientated menu is sent if no arguments are given. If arguments are given, usage information for the given plugin is sent instead. Alias: /start.]]
end

function help.get_initial_keyboard()
    return mattata.inline_keyboard():row(
        mattata.row():callback_data_button(
            'Links',
            'help:links'
        ):callback_data_button(
            'Admin Help',
            'help:ahelp:1'
        ):callback_data_button(
            'Commands',
            'help:cmds'
        )
    ):row(
        mattata.row():switch_inline_query_button(
            'Inline Mode',
            '/'
        ):callback_data_button(
            'Settings',
            'help:settings'
        )
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
    return mattata.inline_keyboard():row(
        mattata.row():callback_data_button(
            'Back',
            'help:back'
        )
    )
end

function help:on_inline_query(inline_query, configuration)
    local output = mattata.get_inline_help(inline_query.query)
    if #output == 0 then
        return mattata.send_inline_article(
            inline_query.id,
            'No results found!',
            string.format(
                'There were no features found matching "%s", please try and be more specific!',
                inline_query.query
            )
        )
    end
    mattata.answer_inline_query(
        inline_query.id,
        output
    )
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
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            help.get_plugin_page(
                arguments_list,
                1
            ) .. '\n\nArguments: <required> [optional]\n\nSearch for a feature or get help with a command by using my inline search functionality - just mention me in any chat using the syntax @' .. self.info.username .. ' <search query>.',
            nil,
            true,
            mattata.inline_keyboard():row(
                mattata.row():callback_data_button(
                    '← Previous',
                    'help:results:0'
                ):callback_data_button(
                    '1/' .. page_count,
                    'help:pages:1:' .. page_count
                ):callback_data_button(
                    'Next →',
                    'help:results:2'
                )
            ):row(
                mattata.row():callback_data_button(
                    'Back',
                    'help:back'
                ):switch_inline_query_current_chat_button(
                    '🔎 Search',
                    '/'
                )
            )
        )
    elseif callback_query.data:match('^results:%d*$') then
        local new_page = callback_query.data:match('^results:(%d*)$')
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
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            help.get_plugin_page(
                arguments_list,
                new_page
            ) .. '\n\nArguments: <required> [optional]\n\nSearch for a feature or get help with a command by using my inline search functionality - just mention me in any chat using the syntax @' .. self.info.username .. ' <search query>.',
            nil,
            true,
            mattata.inline_keyboard():row(
                mattata.row():callback_data_button(
                    '← Previous',
                    'help:results:' .. math.floor(
                        tonumber(new_page) - 1
                    )
                ):callback_data_button(
                    new_page .. '/' .. page_count,
                    'help:pages:' .. new_page .. ':' .. page_count
                ):callback_data_button(
                    'Next →',
                    'help:results:' .. math.floor(
                        tonumber(new_page) + 1
                    )
                )
            ):row(
                mattata.row():callback_data_button(
                    'Back',
                    'help:back'
                ):switch_inline_query_current_chat_button(
                    '🔎 Search',
                    '/'
                )
            )
        )
    elseif callback_query.data:match('^pages:%d*:%d*$') then
        local current_page, total_pages = callback_query.data:match('^pages:(%d*):(%d*)$')
        return mattata.answer_callback_query(
            callback_query.id,
            'You are on page ' .. current_page .. ' of ' .. total_pages .. '!'
        )
    elseif callback_query.data == 'ahelp:1' then
        local administration_help_text = [[
I can perform many administrative actions in your groups, just add me as an administrator and send /administration to adjust the settings for your group.
Here are some administrative commands and a brief comment regarding what they do:

• /pin <text> - Send a Markdown-formatted message which can be edited by using the same command with different text, to save you from having to re-pin a message if you can't edit it (which happens if the message is older than 48 hours)

• /ban - Ban a user by replying to one of their messages, or by specifying them by username/ID

• /kick - Kick (ban and then unban) a user by replying to one of their messages, or by specifying them by username/ID

• /unban - Unban a user by replying to one of their messages, or by specifying them by username/ID

• /setrules <text> - Set the given Markdown-formatted text as the group rules, which will be sent whenever somebody uses /rules

• /setwelcome - Set the given Markdown-formatted text as a welcome message that will be sent every time a user joins your group (the welcome message can be disabled in the administration menu, accessible via /administration)
        ]]
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            administration_help_text,
            'markdown',
            true,
            mattata.inline_keyboard():row(
                mattata.row():callback_data_button(
                    'Back',
                    'help:back'
                ):callback_data_button(
                    'Next',
                    'help:ahelp:2'
                )
            )
        )
    elseif callback_query.data == 'ahelp:2' then
        local administration_help_text = [[
• /warn - Warn a user, and ban them when they hit the maximum number of warnings

• /mod - Promote the replied-to user, giving them access to administrative commands such as /ban, /kick, /warn etc. (this is useful when you don't want somebody to have the ability to delete messages!)

• /demod - Demote the replied-to user, stripping them from their moderation status and revoking their ability to use administrative commands

• /staff - View the group's creator, administrators, and moderators in a neatly-formatted list

• /report - Forwards the replied-to message to all administrators and alerts them of the current situation

• /setlink <URL> - Set the group's link to the given URL, which will be sent whenever somebody uses /link

• /links <text> - Whitelists all of the Telegram links found in the given text (includes @username links)
        ]]
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            administration_help_text,
            'markdown',
            true,
            mattata.inline_keyboard():row(
                mattata.row():callback_data_button(
                    'Back',
                    'help:ahelp:1'
                )
            )
        )
    elseif callback_query.data == 'links' then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            'Below are some links you might find useful:',
            nil,
            true,
            mattata.inline_keyboard():row(
                mattata.row():url_button(
                    'mattata Development',
                    'https://t.me/joinchat/AAAAAEDWD1KbS5gSkP3pSA'
                ):url_button(
                    'mattata\'s Channel',
                    'https://t.me/mattata'
                )
            ):row(
                mattata.row():url_button(
                    'Source Code',
                    'https://github.com/wrxck/mattata'
                ):url_button(
                    'Donate',
                    'https://paypal.me/wrxck'
                ):url_button(
                    'Rate Me',
                    'https://t.me/storebot?start=mattatabot'
                )
            ):row(
                mattata.row():callback_data_button(
                    'Back',
                    'help:back'
                )
            )
        )
    elseif callback_query.data == 'settings' then
        if message.chat.type == 'supergroup' and not mattata.is_group_admin(
            message.chat.id,
            callback_query.from.id
        ) then
            return mattata.answer_callback_query(
                callback_query.id,
                configuration.errors.admin
            )
        end
        return mattata.edit_message_reply_markup(
            message.chat.id,
            message.message_id,
            nil,
            (
                message.chat.type == 'supergroup' and mattata.is_group_admin(
                    message.chat.id,
                    callback_query.from.id
                )
            ) and mattata.inline_keyboard():row(
                mattata.row():callback_data_button(
                    'Admin Settings',
                    string.format(
                        'administration:%s:back',
                        message.chat.id
                    )
                ):callback_data_button(
                    'Plugins',
                    string.format(
                        'plugins:%s:page:1',
                        message.chat.id
                    )
                )
            ):row(
                mattata.row():callback_data_button(
                    'Back',
                    'help:back'
                )
            ) or mattata.inline_keyboard():row(
                mattata.row():callback_data_button(
                    'Plugins',
                    string.format(
                        'plugins:%s:page:1',
                        message.chat.id
                    )
                )
            ):row(
                mattata.row():callback_data_button(
                    'Back',
                    'help:back'
                )
            )
        )
    elseif callback_query.data == 'back' then
        return mattata.edit_message_text(
            message.chat.id,
            message.message_id,
            string.format(
                [[
<b>Hi %s! My name's %s, it's a pleasure to meet you</b> %s

I'm a smart bot who is capable of having conversations with humans such as yourself, and I have the ability to administrate your groups too!

I understand many commands, which you can learn more about by pressing the "Commands" button using the attached keyboard.

%s <b>Tip:</b> Use the "Settings" button to change how I work%s!
                ]],
                mattata.escape_html(callback_query.from.first_name),
                mattata.escape_html(
                    mattata.get_me().result.first_name
                ),
                utf8.char(128513),
                utf8.char(128161),
                message.chat.type ~= 'private' and ' in ' .. mattata.escape_html(message.chat.title) or ''
            ),
            'html',
            true,
            help.get_initial_keyboard(message.chat.type == 'supergroup' and message.chat.id or false)
        )
    end
end

function help:on_message(message, configuration)
    return mattata.send_message(
        message.chat.id,
        string.format(
            [[
<b>Hi %s! My name's %s, it's a pleasure to meet you</b> %s

I'm a smart bot who is capable of having conversations with humans such as yourself, and I have the ability to administrate your groups too!

I understand many commands, which you can learn more about by pressing the "Commands" button using the attached keyboard.

%s <b>Tip:</b> Use the "Settings" button to change how I work%s!
            ]],
            mattata.escape_html(message.from.first_name),
            mattata.escape_html(
                mattata.get_me().result.first_name
            ),
            utf8.char(128513),
            utf8.char(128161),
            message.chat.type ~= 'private' and ' in ' .. mattata.escape_html(message.chat.title) or ''
        ),
        'html',
        true,
        false,
        nil,
        help.get_initial_keyboard(message.chat.type == 'supergroup' and message.chat.id or false)
    )
end

return help