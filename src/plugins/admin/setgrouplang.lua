--[[
    mattata v2.0 - Set Group Language Plugin
]]

local plugin = {}
plugin.name = 'setgrouplang'
plugin.category = 'admin'
plugin.description = 'Set the group language'
plugin.commands = { 'setgrouplang' }
plugin.help = '/setgrouplang [language_code] - Sets the group language. Shows available languages if no code given.'
plugin.group_only = true
plugin.admin_only = true

local LANGUAGES = {
    { code = 'en_gb', name = 'English (UK)' },
    { code = 'en_us', name = 'English (US)' },
    { code = 'es_es', name = 'Spanish' },
    { code = 'pt_br', name = 'Portuguese (BR)' },
    { code = 'de_de', name = 'German' },
    { code = 'fr_fr', name = 'French' },
    { code = 'it_it', name = 'Italian' },
    { code = 'ru_ru', name = 'Russian' },
    { code = 'ar_sa', name = 'Arabic' },
    { code = 'tr_tr', name = 'Turkish' },
    { code = 'nl_nl', name = 'Dutch' },
    { code = 'pl_pl', name = 'Polish' },
    { code = 'id_id', name = 'Indonesian' },
    { code = 'uk_ua', name = 'Ukrainian' },
    { code = 'he_il', name = 'Hebrew' },
    { code = 'fa_ir', name = 'Persian' }
}

function plugin.on_message(api, message, ctx)
    if not message.args then
        -- show inline keyboard with available languages
        local keyboard = { inline_keyboard = {} }
        local row = {}
        for i, lang in ipairs(LANGUAGES) do
            table.insert(row, {
                text = lang.name,
                callback_data = 'setgrouplang:' .. lang.code
            })
            if #row == 2 or i == #LANGUAGES then
                table.insert(keyboard.inline_keyboard, row)
                row = {}
            end
        end
        local json = require('dkjson')
        return api.send_message(message.chat.id, '<b>Select the group language:</b>', 'html', false, false, nil, json.encode(keyboard))
    end

    local lang_code = message.args:lower():match('^(%S+)$')
    if not lang_code then
        return api.send_message(message.chat.id, 'Please provide a valid language code.')
    end

    -- validate the language code
    local valid = false
    for _, lang in ipairs(LANGUAGES) do
        if lang.code == lang_code then
            valid = true
            break
        end
    end
    if not valid then
        return api.send_message(message.chat.id, 'Invalid language code. Use /setgrouplang to see available options.')
    end

    ctx.db.call('sp_upsert_chat_setting', { message.chat.id, 'group_language', lang_code })
    ctx.db.call('sp_upsert_chat_setting', { message.chat.id, 'force_group_language', 'true' })

    api.send_message(message.chat.id, string.format('Group language set to <b>%s</b>.', lang_code), 'html')
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local permissions = require('src.core.permissions')
    if not permissions.is_group_admin(api, message.chat.id, callback_query.from.id) then
        return api.answer_callback_query(callback_query.id, 'Only admins can change the group language.')
    end

    local lang_code = callback_query.data
    if not lang_code then return end

    ctx.db.call('sp_upsert_chat_setting', { message.chat.id, 'group_language', lang_code })
    ctx.db.call('sp_upsert_chat_setting', { message.chat.id, 'force_group_language', 'true' })

    -- find language name
    local lang_name = lang_code
    for _, lang in ipairs(LANGUAGES) do
        if lang.code == lang_code then
            lang_name = lang.name
            break
        end
    end

    api.edit_message_text(message.chat.id, message.message_id, string.format(
        'Group language set to <b>%s</b> (%s).', lang_name, lang_code
    ), 'html')
    api.answer_callback_query(callback_query.id, 'Language updated!')
end

return plugin
