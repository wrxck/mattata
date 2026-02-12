--[[
    mattata v2.0 - Sticker Plugin
    Manage stickers: get file IDs, add to or remove from the bot's sticker pack.
]]

local plugin = {}
plugin.name = 'sticker'
plugin.category = 'media'
plugin.description = 'Sticker management utilities'
plugin.commands = { 'sticker', 'addsticker', 'delsticker' }
plugin.help = table.concat({
    '/sticker - Reply to a sticker to get its file ID.',
    '/addsticker <emoji> - Reply to a sticker or image to add it to the bot\'s sticker pack.',
    '/delsticker - Reply to a sticker to remove it from the bot\'s sticker pack.'
}, '\n')

local function get_sticker_set_name(bot_username)
    return 'pack_by_' .. bot_username
end

local function handle_sticker(api, message)
    if not message.reply or not message.reply.sticker then
        return api.send_message(message.chat.id, 'Please reply to a sticker to get its file ID.')
    end

    local sticker = message.reply.sticker
    local lines = {
        '<b>Sticker Info</b>',
        'File ID: <code>' .. sticker.file_id .. '</code>',
        'Unique ID: <code>' .. sticker.file_unique_id .. '</code>',
        'Emoji: ' .. (sticker.emoji or 'N/A'),
        'Set: ' .. (sticker.set_name or 'N/A'),
        'Animated: ' .. (sticker.is_animated and 'Yes' or 'No'),
        'Video: ' .. (sticker.is_video and 'Yes' or 'No'),
        string.format('Size: %dx%d', sticker.width or 0, sticker.height or 0)
    }

    return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html')
end

local function handle_addsticker(api, message)
    if not message.reply then
        return api.send_message(message.chat.id, 'Please reply to a sticker or image with an emoji, e.g. <code>/addsticker [emoji]</code>.', 'html')
    end

    local emoji = message.args and message.args:match('^(%S+)') or nil
    if not emoji then
        -- Default emoji if none provided
        emoji = message.reply.sticker and message.reply.sticker.emoji or '\xF0\x9F\x98\x80'
    end

    local bot_username = api.info.username
    local set_name = get_sticker_set_name(bot_username)
    local user_id = message.from.id

    local sticker_input
    if message.reply.sticker then
        -- Use the sticker file directly
        sticker_input = message.reply.sticker.file_id
    elseif message.reply.photo then
        -- Use the largest photo size
        local photos = message.reply.photo
        sticker_input = photos[#photos].file_id
    elseif message.reply.document and message.reply.document.mime_type and message.reply.document.mime_type:match('^image/') then
        sticker_input = message.reply.document.file_id
    else
        return api.send_message(message.chat.id, 'Please reply to a sticker or image.')
    end

    -- Build the sticker input for the API
    local sticker_data = {
        sticker = sticker_input,
        emoji_list = { emoji },
        format = 'static'
    }

    -- Check if the sticker from the reply is animated/video and set format accordingly
    if message.reply.sticker then
        if message.reply.sticker.is_animated then
            sticker_data.format = 'animated'
        elseif message.reply.sticker.is_video then
            sticker_data.format = 'video'
        end
    end

    -- Try to add to existing set first
    local success = api.add_sticker_to_set(user_id, set_name, sticker_data)
    if success and success.result then
        return api.send_message(message.chat.id, string.format(
            'Sticker added to <a href="https://t.me/addstickers/%s">the pack</a>.',
            set_name
        ), 'html')
    end

    -- Set might not exist yet, try to create it
    local title = api.info.first_name .. '\'s Pack'
    local create_result = api.create_new_sticker_set(user_id, set_name, title, { sticker_data })
    if create_result and create_result.result then
        return api.send_message(message.chat.id, string.format(
            'Sticker pack created! <a href="https://t.me/addstickers/%s">View pack</a>.',
            set_name
        ), 'html')
    end

    return api.send_message(message.chat.id, 'Failed to add the sticker. Make sure you have started a private chat with me first.')
end

local function handle_delsticker(api, message)
    if not message.reply or not message.reply.sticker then
        return api.send_message(message.chat.id, 'Please reply to a sticker to remove it from its pack.')
    end

    local sticker = message.reply.sticker
    local bot_username = api.info.username
    local set_name = get_sticker_set_name(bot_username)

    -- Only allow deleting from the bot's own pack
    if sticker.set_name ~= set_name then
        return api.send_message(message.chat.id, 'That sticker is not from the bot\'s sticker pack.')
    end

    local success = api.delete_sticker_from_set(sticker.file_id)
    if success and success.result then
        return api.send_message(message.chat.id, 'Sticker removed from the pack.')
    end

    return api.send_message(message.chat.id, 'Failed to remove the sticker.')
end

function plugin.on_message(api, message, ctx)
    if message.command == 'sticker' then
        return handle_sticker(api, message)
    elseif message.command == 'addsticker' then
        return handle_addsticker(api, message)
    elseif message.command == 'delsticker' then
        return handle_delsticker(api, message)
    end
end

return plugin
