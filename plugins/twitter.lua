--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local twitter = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')
local ltn12 = require('ltn12')
local redis = require('mattata-redis')
local base64 = require('plugins.base64')
local oauth = require('OAuth')
local helpers = require('OAuth.helpers')

function twitter:init()
    twitter.commands = mattata.commands(self.info.username)
    :command('twitter')
    :command('tweet')
    :command('authtwitter').table
    twitter.help = '/twitter [text] - Sends a Tweet from your linked Twitter account with the given text as the contents. If the command is used in reply, without any arguments, the replied-to message text is Tweeted instead. Use /authtwitter to authorise your Twitter account. Alias: /tweet.'
end

function twitter.authorise(message, configuration, language)
    local input = mattata.input(message.text)
    if not input
    then
        local client = oauth.new(
            configuration['keys']['twitter']['consumer_key'],
            configuration['keys']['twitter']['consumer_secret'],
            {
                ['RequestToken'] = 'https://api.twitter.com/oauth/request_token',
                ['AuthorizeUser'] = {
                    'https://api.twitter.com/oauth/authorize',
                    ['method'] = 'GET'
                },
                ['AccessToken'] = 'https://api.twitter.com/oauth/access_token'
            }
        )
        local values = client:RequestToken(
            {
                ['oauth_callback'] = 'oob'
            }
        )
        if not values
        or not next(values)
        or not values.oauth_token
        or not values.oauth_token_secret
        then
            return mattata.send_reply(
                message,
                language['errors']['connection']
            )
        end
        redis:set(
            'twitter:' .. message.from.id .. ':oauth_token',
            values.oauth_token
        )
        redis:set(
            'twitter:' .. message.from.id .. ':oauth_token_secret',
            values.oauth_token_secret
        )
        local tracking_code = ''
        for i = 1, 5
        do
            tracking_code = tracking_code .. tostring(
                math.random(9)
            )
        end
        local new_url = client:BuildAuthorizationUrl(
            {
                ['oauth_callback'] = 'oob',
                ['state'] = tracking_code
            }
        )
        local success = mattata.send_force_reply(
            message,
            'To authorise mattata to use your Twitter account, please [navigate to this page](' .. new_url .. '), authorise mattata, and reply to this message with the code you are presented with on your screen.',
            'markdown'
        )
        if success
        then
            redis:set(
                string.format(
                    'action:%s:%s',
                    message.chat.id,
                    success.result.message_id
                ),
                '/authtwitter'
            )
        end
        return
    elseif tonumber(input) == nil
    then
        return mattata.send_reply(
            message,
            'Invalid code. The code you should have been presented with is supposed to be numerical!'
        )
    end
    input = tostring(input)
    local client = oauth.new(
        'consumer_key',
        'consumer_secret',
        {
            ['RequestToken'] = 'https://api.twitter.com/oauth/request_token',
            ['AuthorizeUser'] = {
                'https://api.twitter.com/oauth/authorize',
                ['method'] = 'GET'
            },
            ['AccessToken'] = 'https://api.twitter.com/oauth/access_token'
        },
        {
            ['OAuthToken'] = redis:get('twitter:' .. message.from.id .. ':oauth_token'),
            ['OAuthVerifier'] = input
        }
    )
    client:SetTokenSecret(
        redis:get('twitter:' .. message.from.id .. ':oauth_token_secret')
    )
    local values, res, headers, status, body = client:GetAccessToken()
    if not values
    or not next(values)
    then
        return mattata.send_reply(
            message,
            language['errors']['connection']
        )
    end
    redis:set(
        'twitter:' .. message.from.id .. ':oauth_token',
        values.oauth_token
    )
    redis:set(
        'twitter:' .. message.from.id .. ':oauth_token_secret',
        values.oauth_token_secret
    )
    return mattata.send_reply(
        message,
        'Your account was successfully authorised!'
    )
end

function twitter.tweet(configuration, user_id, text)
    if not configuration
    or not user_id
    or not text
    then
        return false
    end
    local client = oauth.new(
        configuration['keys']['twitter']['consumer_key'],
        configuration['keys']['twitter']['consumer_secret'],
        {
            RequestToken = 'https://api.twitter.com/oauth/request_token',
            AuthorizeUser = {
                'https://api.twitter.com/oauth/authorize',
                method = 'GET'
            },
            AccessToken = 'https://api.twitter.com/oauth/access_token'
        },
        {
            OAuthToken = redis:get('twitter:' .. user_id .. ':oauth_token'),
            OAuthTokenSecret = redis:get('twitter:' .. user_id .. ':oauth_token_secret')
        }
    )
    local req = helpers.multipart.Request(
        {
            status = tostring(text)
        }
    )
    local code, headers, status, body = client:PerformRequest(
        'POST',
        'https://api.twitter.com/1.1/statuses/update.json',
        req.body,
        req.headers
    )
    if code ~= 200
    then
        return false, code
    end
    return true, body
end

function twitter:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    if not redis:get('twitter:' .. message.from.id .. ':oauth_token')
    or not redis:get('twitter:' .. message.from.id .. ':oauth_token_secret')
    or message.text:match('^[/!#]authtwitter')
    then
        return twitter.authorise(
            message,
            configuration,
            language
        )
    elseif not input
    and not message.reply
    then
        return mattata.send_reply(
            message,
            twitter.help
        )
    elseif message.reply
    then
        input = message.reply.text
    end
    input = tostring(input)
    if input:len() > 140
    then
        return mattata.send_reply(
            message,
            'Tweets must be no more than 140 characters in length!'
        )
    end
    local success, jstr = twitter.tweet(
        configuration,
        message.from.id,
        input
    )
    if not success
    or not jstr
    then
        if tonumber(jstr) >= 400
        then
            for k, v in pairs(
                redis:keys('twitter:' .. message.from.id .. ':*')
            )
            do
                redis:del(v)
            end
            print(
                'Erased saved Twitter credentials for ' .. (
                    message.from.username
                    and '@' .. message.from.username
                    or message.from.id
                )
            )
        end
        return mattata.send_reply(
            message,
            'I could not send your tweet. Are you sure you\'ve authorised your Twitter to be used with me? Try sending /authtwitter to re-authorise your account.'
        )
    end
    local jdat = json.decode(jstr)
    if not jdat
    or not next(jdat)
    or not jdat.id_str
    or not jdat.user
    or not jdat.user.screen_name
    then
        return mattata.send_reply(
            message,
            language['errors']['generic']
        )
    end
    return mattata.send_reply(
        message,
        'Your tweet has been sent! Click [here](https://twitter.com/' .. jdat.user.screen_name .. '/status/' .. jdat.id_str .. ') to view it!',
        'markdown'
    )
end

return twitter