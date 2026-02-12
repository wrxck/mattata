--[[
    mattata v2.0 - Set Language Plugin
    Allows users to select their preferred language via inline keyboard.
]]

local plugin = {}
plugin.name = 'setlang'
plugin.category = 'utility'
plugin.description = 'Set your preferred language'
plugin.commands = { 'setlang', 'language', 'lang' }
plugin.help = '/setlang - Select your preferred language from the available options.'

local LANG_NAMES = {
    en_gb = 'English (GB)',
    en_us = 'English (US)',
    de_de = 'Deutsch',
    de_at = 'Deutsch (AT)',
    ar_ar = 'العربية',
    pl_pl = 'Polski',
    pt_br = 'Português (BR)',
    pt_pt = 'Português (PT)',
    tr_tr = 'Türkçe',
    scottish = 'Scottish'
}

function plugin.on_message(api, message, ctx)
    local i18n = require('src.core.i18n')
    local available = i18n.available()
    -- Build keyboard with 2 languages per row
    local keyboard = api.inline_keyboard()
    local current_row = nil
    for i, code in ipairs(available) do
        if (i - 1) % 2 == 0 then
            current_row = api.row()
        end
        local label = LANG_NAMES[code] or code
        current_row:callback_data_button(label, 'setlang:set:' .. code)
        if i % 2 == 0 or i == #available then
            keyboard:row(current_row)
        end
    end
    return api.send_message(
        message.chat.id,
        'Select your preferred language:',
        nil, true, false, nil, keyboard
    )
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local data = callback_query.data
    local code = data:match('^set:(.+)$')
    if not code then return end
    local i18n = require('src.core.i18n')
    if not i18n.exists(code) then
        return api.answer_callback_query(callback_query.id, 'Language not available.')
    end
    ctx.session.set_setting(callback_query.from.id, 'language', code, 0)
    local name = LANG_NAMES[code] or code
    api.answer_callback_query(callback_query.id, 'Language set to ' .. name .. '!')
    return api.edit_message_text(
        message.chat.id,
        message.message_id,
        string.format('Language set to <b>%s</b>.', name),
        'html'
    )
end

return plugin
