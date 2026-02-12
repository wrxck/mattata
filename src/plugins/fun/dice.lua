--[[
    mattata v2.0 - Dice Plugin
    Roll dice using Telegram's native dice animations.
]]

local plugin = {}
plugin.name = 'dice'
plugin.category = 'fun'
plugin.description = 'Roll dice or play other Telegram dice games'
plugin.commands = { 'dice', 'roll' }
plugin.help = '/dice [type] - Roll a die. Types: dice (default), basketball, darts, football, bowling, slots.'

local EMOJI_MAP = {
    ['dice']       = '\xF0\x9F\x8E\xB2',  -- U+1F3B2
    ['basketball'] = '\xF0\x9F\x8F\x80',  -- U+1F3C0
    ['darts']      = '\xF0\x9F\x8E\xAF',  -- U+1F3AF
    ['football']   = '\xE2\x9A\xBD',       -- U+26BD
    ['bowling']    = '\xF0\x9F\x8E\xB3',  -- U+1F3B3
    ['slots']      = '\xF0\x9F\x8E\xB0',  -- U+1F3B0
}

function plugin.on_message(api, message, ctx)
    local input = message.args and message.args:lower() or 'dice'
    local emoji = EMOJI_MAP[input]
    if not emoji then
        local valid = {}
        for k, _ in pairs(EMOJI_MAP) do
            table.insert(valid, k)
        end
        table.sort(valid)
        return api.send_message(
            message.chat.id,
            'Invalid dice type. Valid types: ' .. table.concat(valid, ', ')
        )
    end
    return api.send_dice(message.chat.id, emoji, false, message.message_id)
end

return plugin
