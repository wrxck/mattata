--[[
    mattata v2.0 - Bookmark Plugin
    Reply to any message with /bookmark to save it to your DMs.
]]

local plugin = {}
plugin.name = 'bookmark'
plugin.category = 'utility'
plugin.description = 'Bookmark messages by saving them to your DMs'
plugin.commands = { 'bookmark', 'bm' }
plugin.help = '/bookmark - Reply to a message to save it to your DMs.'
plugin.group_only = true

local tools = require('telegram-bot-lua.tools')

function plugin.on_message(api, message, ctx)
    if not message.reply then
        return api.send_message(
            message.chat.id,
            'Please reply to a message you want to bookmark.',
            { parse_mode = 'html' }
        )
    end

    -- Build message link for supergroups
    local link_id = tostring(message.chat.id):gsub('^%-100', '')
    local message_link = string.format('https://t.me/c/%s/%s', link_id, tostring(message.reply.message_id))

    -- Build a preview of the bookmarked content
    local preview = ''
    local reply_text = message.reply.text or message.reply.caption
    if reply_text and reply_text ~= '' then
        if #reply_text > 200 then
            preview = reply_text:sub(1, 197) .. '...'
        else
            preview = reply_text
        end
    else
        preview = '(media or non-text message)'
    end

    local chat_title = tools.escape_html(message.chat.title or 'Unknown chat')
    local bookmark_text = string.format(
        'Bookmark from <b>%s</b>\n\n%s\n\n<a href="%s">Go to message</a>',
        chat_title,
        tools.escape_html(preview),
        message_link
    )

    -- Try to send the bookmark as a DM
    local result = api.send_message(message.from.id, bookmark_text, {
        parse_mode = 'html',
        link_preview_options = { is_disabled = true }
    })

    if not result or not result.result then
        return api.send_message(
            message.chat.id,
            'I couldn\'t send you a DM. Please start a private chat with me first.'
        )
    end

    -- Track bookmark count per user
    ctx.redis.incr('bookmarks:' .. message.from.id)

    return api.send_message(message.chat.id, 'Bookmark saved! Check your DMs.')
end

return plugin
