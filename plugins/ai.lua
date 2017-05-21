--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local ai = {}
local mattata = require('mattata')
local mattata_ai = require('mattata-ai')
local url = require('socket.url')
local redis = require('mattata-redis')
local json = require('dkjson')

function ai.process(message, reply)
    if not message
    then
        return ai.unsure()
    end
    local original_message = message
    message = message:lower()
    if message:match('^hi%s*')
    or message:match('^hello%s*')
    or message:match('^howdy%s*')
    or message:match('^hi.?$')
    or message:match('^hello.?$')
    or message:match('^howdy.?$')
    then
        return ai.greeting()
    elseif message:match('^bye%s*')
    or message:match('^good[%-%s]?bye%s*')
    or message:match('^bye$')
    or message:match('^good[%-%s]?bye$')
    then
        return ai.farewell()
    elseif message:match('%s*y?o?ur%s*name%s*')
    or message:match('^what%s*is%s*y?o?ur%s*name')
    then
        return 'My name is mattata, what\'s yours?'
    elseif message:match('^do y?o?u[%s.]*')
    then
        return ai.choice(message)
    elseif message:match('^how%s*a?re?%s*y?o?u.?')
    or message:match('.?how%s*a?re?%s*y?o?u%s*')
    or message:match('.?how%s*a?re?%s*y?o?u.?$')
    or message:match('^a?re?%s*y?o?u%s*oka?y?.?$')
    or message:match('%s*a?re?%s*y?o?u%s*oka?y?.?$')
    then
        return ai.feeling()
    else
        local response = mattata_ai.talk(
            original_message,
            reply
            or false,
            true
        )
        if not response
        then
            if redis:hget(
                'ai',
                message
            )
            then
                response = json.decode(
                    redis:hget(
                        'ai',
                        message
                    )
                )
                if not response
                then
                    return false
                end
                return response.responses[math.random(#response.responses)]
            end
            return false
        end
        local conversation = json.encode(
            {
                ['message'] = message,
                ['responses'] = {
                    response
                }
            }
        )
        if redis:hget(
            'ai',
            message
        )
        then
            conversation = json.decode(
                redis:hget(
                    'ai',
                    message
                )
            )
            local is_known = false
            local count = 1
            for k, v in pairs(conversation.responses)
            do
                if count >= 20
                then
                    is_known = true -- Prevent the caching of too many responses!
                elseif v == response
                then
                    is_known = true
                end
                count = count + 1
            end
            if is_known == false
            then
                table.insert(
                    conversation.responses,
                    response
                )
            end
            conversation = json.encode(conversation)
        end
        redis:hset(
            'ai',
            message,
            conversation
        )
        print('Saved responses for "' .. message .. '"!')
        return response
    end
end

function ai.greeting()
    local greetings = {
        'Hello!',
        'Hi.',
        'How are you?',
        'What\'s up?',
        'Are you okay?',
        'How\'s it going?',
        'What\'s your name?',
        'What are you up to?',
        'Hello.',
        'Hey!',
        'Hey.',
        'Howdy!',
        'Howdy.',
        'Hello there!',
        'Hello there.'
    }
    return greetings[math.random(#greetings)]
end

function ai.unsure()
    local unsure = {
        'What?',
        'I really don\'t understand.',
        'What are you trying to say?',
        'Huh?',
        'Um..?',
        'Excuse me?',
        'What does that mean?'
    }
    return unsure[math.random(#unsure)]
end

function ai.feeling()
    local feelings = {
        'I am good thank you!',
        'I am well.',
        'Good, how about you?',
        'Very well thank you; you?',
        'Never better!',
        'I feel great!'
    }
    return feelings[math.random(#feelings)]
end

function ai.choice(message)
    local generic_choices = {
        'I do!',
        'I do not.',
        'Nah, of course not!',
        'Why would I?',
        'Um...',
        'I sure do!',
        'Yes, do you?',
        'Nope!',
        'Yeah!'
    }
    local personal_choices = {
        'I love you!',
        'I\'m sorry, but I don\'t really like you!',
        'I really like you.',
        'I\'m crazy about you!'
    }
    if message:match('%s*me.?$')
    then
        return personal_choices[math.random(#personal_choices)]
    end
    return generic_choices[math.random(#generic_choices)]
end

function ai.offline()
    local responses = {
        'I don\'t feel like talking right now!',
        'I don\'t want to talk at the moment.',
        'Can we talk later?',
        'I\'m not in the mood right now...',
        'Leave me alone!',
        'Please can I have some time to myself?',
        'I really don\'t want to talk to anyone right now!',
        'Please leave me in peace.',
        'I don\'t wanna talk right now, I hope you understand.'
    }
    return responses[math.random(#responses)]
end

function ai:on_message(message, configuration)
    mattata.send_chat_action(
        message.chat.id,
        'typing'
    )
    local output
    if redis:get('ai:' .. message.from.id .. ':use_cleverbot')
    then
        if message.reply_to_message
        and message.reply_to_message.text:len() > 0
        then
            output = ai.process(
                message.text,
                message.reply_to_message.text,
                true
            )
        else
            output = ai.process(message.text)
        end
    else
        local token = message.from.id
        if mattata.get_setting(
            message.chat.id,
            'shared ai'
        )
        then
            token = message.chat.id
        end
        output = mattata_ai.talk(
            message.text,
            false,
            false,
            token
        )
    end
    if not output
    then
        if message.reply_to_message
        and message.reply_to_message.text:len() > 0
        then
            output = ai.process(
                message.text,
                message.reply_to_message.text,
                true
            )
        else
            output = ai.process(message.text)
        end
    end
    return mattata.send_reply(
        message,
        output
        and '<pre>' .. mattata.escape_html(output) .. '</pre>'
        or '<pre>' .. mattata.escape_html(
            ai.offline()
        ) .. '</pre>',
        'html'
    )
end

return ai