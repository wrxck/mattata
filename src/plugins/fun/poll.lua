--[[
    mattata v2.0 - Poll Plugin
    Quick poll creation via /poll and /vote commands.
]]

local plugin = {}
plugin.name = 'poll'
plugin.category = 'fun'
plugin.description = 'Create quick polls in groups'
plugin.commands = { 'poll', 'vote' }
plugin.help = '/poll <question> | <option 1> | <option 2> [| ...] - Create a non-anonymous poll.\n'
    .. '/vote <question> | <option 1> | <option 2> [| ...] - Create an anonymous poll.'
plugin.group_only = true

function plugin.on_message(api, message, ctx)
    if not message.args or message.args == '' then
        return api.send_message(message.chat.id,
            '<b>Usage:</b>\n'
            .. '<code>/poll Question? | Option 1 | Option 2</code> - Non-anonymous poll\n'
            .. '<code>/vote Question? | Option 1 | Option 2</code> - Anonymous poll\n\n'
            .. 'Separate the question and options with <code>|</code>. You can have 2-10 options.',
            { parse_mode = 'html' }
        )
    end

    -- Split on | and trim whitespace
    local parts = {}
    for part in message.args:gmatch('[^|]+') do
        local trimmed = part:match('^%s*(.-)%s*$')
        if trimmed and trimmed ~= '' then
            parts[#parts + 1] = trimmed
        end
    end

    if #parts < 3 then
        return api.send_message(message.chat.id, 'You need a question and at least 2 options, separated by |.')
    end

    local question = parts[1]
    if #question > 300 then
        return api.send_message(message.chat.id, 'The question must be 300 characters or fewer.')
    end

    local options = {}
    for i = 2, #parts do
        if #parts[i] > 100 then
            return api.send_message(message.chat.id,
                string.format('Option %d is too long. Each option must be 100 characters or fewer.', i - 1)
            )
        end
        options[#options + 1] = { text = parts[i] }
    end

    if #options > 10 then
        return api.send_message(message.chat.id, 'You can have a maximum of 10 options.')
    end

    local is_anonymous = message.command == 'vote'

    return api.send_poll(message.chat.id, question, options, {
        is_anonymous = is_anonymous
    })
end

return plugin
