--[[
    mattata v2.0 - Language Middleware
    Loads the appropriate language file into ctx.lang based on user/group settings.
]]

local language_mw = {}
language_mw.name = 'language'

local i18n = require('src.core.i18n')
local session = require('src.core.session')

function language_mw.run(ctx, message)
    local lang_code = 'en_gb'

    if message.from then
        -- Check user language setting
        local user_lang = session.get_setting(message.from.id, 'language')
            or (message.from.language_code and i18n.exists(message.from.language_code) and message.from.language_code)
        if user_lang and i18n.exists(user_lang) then
            lang_code = user_lang
        end
    end

    -- Check group language override
    if ctx.is_group and message.chat then
        local force_group = session.get_setting(message.chat.id, 'force group language')
        if force_group then
            local group_lang = session.get_setting(message.chat.id, 'group language') or 'en_gb'
            if i18n.exists(group_lang) then
                lang_code = group_lang
            end
        end
    end

    ctx.lang_code = lang_code
    ctx.lang = i18n.get(lang_code)
    return ctx, true
end

return language_mw
