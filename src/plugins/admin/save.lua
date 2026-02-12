--[[
    mattata v2.0 - Save/Get Notes Plugin
]]

local plugin = {}
plugin.name = 'save'
plugin.category = 'admin'
plugin.description = 'Save and retrieve notes'
plugin.commands = { 'save', 'get' }
plugin.help = '/save <name> - Saves replied-to message as a note. /get <name> - Retrieves a saved note.'
plugin.group_only = true
plugin.admin_only = false

function plugin.on_message(api, message, ctx)
    local tools = require('telegram-bot-lua.tools')
    local permissions = require('src.core.permissions')

    if message.command == 'get' then
        if not message.args then
            -- List all saved notes
            local notes = ctx.db.execute(
                'SELECT note_name FROM saved_notes WHERE chat_id = $1 ORDER BY note_name',
                { message.chat.id }
            )
            if not notes or #notes == 0 then
                return api.send_message(message.chat.id, 'No notes saved. An admin can save notes with /save <name> in reply to a message.')
            end
            local output = '<b>Saved notes:</b>\n\n'
            for _, note in ipairs(notes) do
                output = output .. '- <code>' .. tools.escape_html(note.note_name) .. '</code>\n'
            end
            return api.send_message(message.chat.id, output, 'html')
        end

        local name = message.args:lower():match('^(%S+)')
        local note = ctx.db.execute(
            'SELECT content, content_type, file_id FROM saved_notes WHERE chat_id = $1 AND note_name = $2',
            { message.chat.id, name }
        )
        if not note or #note == 0 then
            return api.send_message(message.chat.id, string.format('Note <code>%s</code> not found.', tools.escape_html(name)), 'html')
        end

        local n = note[1]
        if n.content_type == 'photo' and n.file_id then
            api.send_photo(message.chat.id, n.file_id, n.content)
        elseif n.content_type == 'document' and n.file_id then
            api.send_document(message.chat.id, n.file_id, n.content)
        elseif n.content_type == 'video' and n.file_id then
            api.send_video(message.chat.id, n.file_id, nil, nil, nil, n.content)
        elseif n.content_type == 'audio' and n.file_id then
            api.send_audio(message.chat.id, n.file_id, n.content)
        elseif n.content_type == 'sticker' and n.file_id then
            api.send_sticker(message.chat.id, n.file_id)
        else
            api.send_message(message.chat.id, n.content, 'html')
        end
        return
    end

    -- /save requires admin
    if not ctx.is_admin and not ctx.is_global_admin then
        return api.send_message(message.chat.id, 'Only admins can save notes.')
    end

    if not message.args then
        return api.send_message(message.chat.id, 'Usage: /save <name> in reply to a message.')
    end

    local name = message.args:lower():match('^(%S+)')
    if not name then
        return api.send_message(message.chat.id, 'Please provide a name for the note.')
    end

    local content = ''
    local content_type = 'text'
    local file_id = nil

    if message.reply then
        content = message.reply.text or message.reply.caption or ''
        if message.reply.photo then
            content_type = 'photo'
            file_id = message.reply.photo[#message.reply.photo].file_id
        elseif message.reply.document then
            content_type = 'document'
            file_id = message.reply.document.file_id
        elseif message.reply.video then
            content_type = 'video'
            file_id = message.reply.video.file_id
        elseif message.reply.audio then
            content_type = 'audio'
            file_id = message.reply.audio.file_id
        elseif message.reply.sticker then
            content_type = 'sticker'
            file_id = message.reply.sticker.file_id
        end
    else
        -- If no reply, save the text after the note name
        local _, rest = message.args:match('^(%S+)%s+(.+)$')
        if rest then
            content = rest
        else
            return api.send_message(message.chat.id, 'Please reply to a message or provide text after the note name.')
        end
    end

    ctx.db.upsert('saved_notes', {
        chat_id = message.chat.id,
        note_name = name,
        content = content,
        content_type = content_type,
        file_id = file_id,
        created_by = message.from.id
    }, { 'chat_id', 'note_name' }, { 'content', 'content_type', 'file_id', 'created_by' })

    api.send_message(message.chat.id, string.format(
        'Note <code>%s</code> has been saved. Use /get %s to retrieve it.',
        tools.escape_html(name), tools.escape_html(name)
    ), 'html')
end

return plugin
