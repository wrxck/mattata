--[[
    mattata v2.1 - Poll Plugin
    Create polls and quizzes via Telegram's native poll API.
]]

local plugin = {}
plugin.name = 'poll'
plugin.category = 'utility'
plugin.description = 'Create polls and quizzes'
plugin.commands = { 'poll', 'quiz' }
plugin.help = '/poll Question? | Option 1 | Option 2 | ... - Create a poll.\n/quiz Question? | Correct Answer | Wrong 1 | Wrong 2 - Create a quiz (first option is correct).'

local json = require('dkjson')

function plugin.on_message(api, message, ctx)
    if not message.args or message.args == '' then
        if message.command == 'quiz' then
            return api.send_message(message.chat.id, 'Usage: /quiz Question? | Correct Answer | Wrong 1 | Wrong 2\n\nThe first option is the correct answer.')
        end
        return api.send_message(message.chat.id, 'Usage: /poll Question? | Option 1 | Option 2 | ...\n\nSeparate options with |. Minimum 2 options, maximum 10.')
    end

    -- Parse question and options
    local parts = {}
    for part in message.args:gmatch('[^|]+') do
        part = part:match('^%s*(.-)%s*$')
        if part ~= '' then
            table.insert(parts, part)
        end
    end

    if #parts < 3 then
        return api.send_message(message.chat.id, 'You need at least a question and 2 options. Separate them with |.')
    end

    if #parts > 11 then
        return api.send_message(message.chat.id, 'Maximum 10 options allowed.')
    end

    local question = parts[1]
    local options = {}
    for i = 2, #parts do
        table.insert(options, parts[i])
    end

    local is_quiz = message.command == 'quiz'

    local opts = {
        is_anonymous = false
    }

    if is_quiz then
        opts.type = 'quiz'
        opts.correct_option_id = 0 -- First option is correct
    end

    return api.send_poll(message.chat.id, question, json.encode(options), opts)
end

return plugin
