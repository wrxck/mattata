--[[
                     _   _        _
     _ __ ___   __ _| |_| |_ __ _| |_ __ _
    | '_ ` _ \ / _` | __| __/ _` | __/ _` |
    | | | | | | (_| | |_| || (_| | || (_| |
    |_| |_| |_|\__,_|\__|\__\__,_|\__\__,_|

    Configuration file for mattata v1.1

    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.

    Each value in an array should be comma separated, with the exception of the last value!
    Make sure you always update your configuration file after pulling changes from GitHub!

]]

local configuration = { -- Rename this file to configuration.lua for the bot to work!
    ['bot_token'] = '', -- In order for the bot to actually work, you MUST insert the Telegram
    -- bot API token you received from @BotFather.
    ['connected_message'] = 'Connected to the Telegram bot API!', -- The message to print when the bot is connected to the Telegram bot API.
    ['version'] = '1.1', -- the version of mattata, don't change this!
    -- The following two tokens will require you to have setup payments with @BotFather, and
    -- a Stripe account with @stripe!
    ['stripe_live_token'] = '', -- Payment token you receive from @BotFather.
    ['stripe_test_token'] = '', -- Test payment token you receive from @BotFather.
    ['admins'] = {  -- Here you need to specify the numerical ID of the users who shall have
    -- FULL control over the bot, this includes access to server files via the lua and shell plugins.
        221714512
    },
    ['blacklist_plugin_exceptions'] = {
        'antispam'
    },
    ['beta_plugins'] = {
        'array_of_beta_plugins_here'
    },
    ['updates'] = {
        ['timeout'] = 3, -- timeout in seconds for api.get_updates()
        ['limit'] = 100 -- message limit for api.get_updates() - must be between 1-100
    },
    ['language'] = 'en', -- The two character locale to set your default language to.
    ['log_chat'] = nil, -- This needs to be the numerical identifier of the chat you wish to log
    -- errors into. If it's not a private chat it should begin with a '-' symbol.
    ['log_admin_actions'] = true, -- Should administrative actions be logged? [true/false]
    ['log_channel'] = nil, -- This needs to be the numerical identifier of the channel you wish
    -- to log administrative actions in by default. It should begin with a '-' symbol.
    ['bug_reports_chat'] = nil, -- This needs to be the numerical identifier of the chat you wish to send
    -- bug reports into. If it's not a private chat it should begin with a '-' symbol.
    ['counter_channel'] = nil, -- This needs to be the numerical identifier of the channel you wish
    -- to forward messages into, for use with the /counter command. It should begin with a '-' symbol.
    ['download_location'] = '/your/downloads/directory', -- The location to save all downloaded media to.
    ['fonts_directory'] = '/your/fonts/directory', -- The location where fonts are stored for CAPTCHAs
    ['respond_to_misc'] = true, -- Respond to shitpostings/memes in mattata.lua? [true/false]
    ['max_copypasta_length'] = 300, -- The maximum number of characters a message can have to be
    -- able to have /copypasta used on it.
    ['debug'] = true, -- Turn this on to print EVEN MORE information to the terminal.
    ['redis'] = { -- Configurable options for connecting the bot to redis. Do NOT modify
    -- these settings if you don't know what you're doing!
        ['host'] = '127.0.0.1',
        ['port'] = 6379,
        ['password'] = nil,
        ['db'] = 2
    },
    ['keys'] = { -- API keys needed for the full functionality of several plugins.
        ['cats'] = '', -- http://thecatapi.com/api-key-registration.html
        ['translate'] = '', -- https://tech.yandex.com/keys/get/?service=trnsl
        ['lyrics'] = '', -- https://developer.musixmatch.com/admin/applications
        ['lastfm'] = '', -- http://www.last.fm/api/account/create
        ['weather'] = '', -- https://darksky.net/dev/register
        ['youtube'] = '', -- https://console.developers.google.com/apis
        ['maps'] = '', -- https://console.cloud.google.com/google/maps-apis
        ['location'] = '', -- https://opencagedata.com/api
        ['bing'] = '', -- https://datamarket.azure.com/account/keys
        ['flickr'] = '', -- https://www.flickr.com/services/apps/create/noncommercial/
        ['news'] = '', -- https://newsapi.org/
        ['twitch'] = '', -- https://twitchapps.com/tmi/
        ['pastebin'] = '', -- https://pastebin.com/api
        ['dictionary'] = {  -- https://developer.oxforddictionaries.com/
            ['id'] = '',
            ['key'] = ''
        },
        ['adfly'] = { -- https://ay.gy/publisher/tools#tools-api
            ['api_key'] = '',
            ['user_id'] = '',
            ['secret_key'] = ''
        },
        ['pasteee'] = '', -- https://paste.ee/
        ['google'] = { -- https://console.developers.google.com/apis
            ['api_key'] = '',
            ['cse_key'] = ''
        },
        ['steam'] = '', -- https://steamcommunity.com/dev/apikey
        ['spotify'] = { -- https://developer.spotify.com/my-applications/#!/applications/create
            ['client_id'] = '',
            ['client_secret'] = '',
            ['redirect_uri'] = ''
        },
        ['twitter'] = { -- https://apps.twitter.com/app/new
            ['consumer_key'] = '',
            ['consumer_secret'] = ''
        },
        ['imgur'] = { -- https://api.imgur.com/oauth2/addclient
            ['client_id'] = '',
            ['client_secret'] = ''
        },
        ['spamwatch'] = '' -- https://t.me/SpamWatchSupport
    },
    ['errors'] = { -- Messages to provide a more user-friendly approach to errors.
        ['connection'] = 'Connection error.',
        ['results'] = 'I couldn\'t find any results for that.',
        ['supergroup'] = 'This command can only be used in supergroups.',
        ['admin'] = 'You need to be a moderator or an administrator in this chat in order to use this command.',
        ['unknown'] = 'I don\'t recognise that user. If you would like to teach me who they are, forward a message from them to any chat that I\'m in.',
        ['generic'] = 'An unexpected error occured. Please report this error using /bugreport.'
    },
    ['limits'] = {
        ['bing'] = {
            ['private'] = 12,
            ['public'] = 8
        },
        ['reddit'] = {
            ['private'] = 8,
            ['public'] = 4
        },
        ['chatroulette'] = 512,
        ['copypasta'] = 300,
        ['drawtext'] = 1000,
        ['help'] = {
            ['per_page'] = 4
        }
    },
    ['administration'] = { -- Values used in administrative plugins
        ['warnings'] = {
            ['maximum'] = 10,
            ['minimum'] = 2,
            ['default'] = 3
        },
        ['store_chat_members'] = true,
        ['global_antispam'] = { -- normal antispam is processed in plugins/antispam.mattata
            ['ttl'] = 5, -- amount of seconds to process the messages in
            ['message_warning_amount'] = 10, -- amount of messages a user can send in the TTL until they're warned
            ['message_blacklist_amount'] = 25, -- amount of messages a user can send in the TTL until they're blacklisted
            ['blacklist_length'] = 86400, -- amount (in seconds) to blacklist the user for (set it to -1 if you want it forever)
            ['max_code_length'] = 64 -- maximum length of code or pre entities that are allowed with "remove pasted code" setting on
        },
        ['default'] = {
            ['antispam'] = {
                ['text'] = 8,
                ['forwarded'] = 16,
                ['sticker'] = 4,
                ['photo'] = 4,
                ['video'] = 4,
                ['location'] = 4,
                ['voice'] = 4,
                ['game'] = 2,
                ['venue'] = 4,
                ['video_note'] = 4,
                ['invoice'] = 2,
                ['contact'] = 2,
                ['dice'] = 1,
                ['poll'] = 1
            }
        },
        ['feds'] = {
            ['group_limit'] = 3,
            ['shortened_feds'] = {
                ['name'] = 'uuid'
            }
        },
        ['voteban'] = {
            ['upvotes'] = {
                ['maximum'] = 50,
                ['minimum'] = 2,
                ['default'] = 5
            },
            ['downvotes'] = {
                ['maximum'] = 50,
                ['minimum'] = 2,
                ['default'] = 5
            }
        }
    },
    ['join_messages'] = { -- Values used in plugins/administration.lua.
        'Welcome, NAME!',
        'Hello, NAME!',
        'Enjoy your stay, NAME!',
        'I\'m glad you joined, NAME!',
        'Howdy, NAME!',
        'Hi, NAME!'
    },
    ['groups'] = {
        ['name'] = 'https://t.me/link'
    },
    ['sort_groups'] = true, -- Decides whether groups will be sorted by name in /groups.
    ['stickers'] = { -- Values used in mattata.lua, for administrative plugin functionality.
    -- These are the file_id values for stickers which are binded to the relevant command.
        ['ban'] = {
            'AgAD0AIAAlAYNw0',
            'AgADzwIAAlAYNw0'
        },
        ['warn'] = {
            'AgAD0QIAAlAYNw0',
            'AgAD0gIAAlAYNw0'
        },
        ['kick'] = {
            'AgAD0wIAAlAYNw0'
        }
    },
    ['slaps'] = {
        '{THEM} was shot by {ME}.',
        '{THEM} was pricked to death.',
        '{THEM} walked into a cactus while trying to escape {ME}.',
        '{THEM} drowned.',
        '{THEM} drowned whilst trying to escape {ME}.',
        '{THEM} blew up.',
        '{THEM} was blown up by {ME}.',
        '{THEM} hit the ground too hard.',
        '{THEM} fell from a high place.',
        '{THEM} fell off a ladder.',
        '{THEM} fell into a patch of cacti.',
        '{THEM} was doomed to fall by {ME}.',
        '{THEM} was blown from a high place by {ME}.',
        '{THEM} was squashed by a falling anvil.',
        '{THEM} went up in flames.',
        '{THEM} burned to death.',
        '{THEM} was burnt to a crisp whilst fighting {ME}.',
        '{THEM} walked into a fire whilst fighting {ME}.',
        '{THEM} tried to swim in lava.',
        '{THEM} tried to swim in lava whilst trying to escape {ME}.',
        '{THEM} was struck by lightning.',
        '{THEM} was slain by {ME}.',
        '{THEM} got finished off by {ME}.',
        '{THEM} was killed by magic.',
        '{THEM} was killed by {ME} using magic.',
        '{THEM} starved to death.',
        '{THEM} suffocated in a wall.',
        '{THEM} fell out of the world.',
        '{THEM} was knocked into the void by {ME}.',
        '{THEM} withered away.',
        '{THEM} was pummeled by {ME}.',
        '{THEM} was fragged by {ME}.',
        '{THEM} was desynchronized.',
        '{THEM} was wasted.',
        '{THEM} was busted.',
        '{THEM}\'s bones are scraped clean by the desolate wind.',
        '{THEM} has died of dysentery.',
        '{THEM} fainted.',
        '{THEM} is out of usable Pokemon! {THEM} whited out!',
        '{THEM} is out of usable Pokemon! {THEM} blacked out!',
        '{THEM} whited out!',
        '{THEM} blacked out!',
        '{THEM} says goodbye to this cruel world.',
        '{THEM} got rekt.',
        '{THEM} was sawn in half by {ME}.',
        '{THEM} died. I blame {ME}.',
        '{THEM} was axe-murdered by {ME}.',
        '{THEM}\'s melon was split by {ME}.',
        '{THEM} was sliced and diced by {ME}.',
        '{THEM} was split from crotch to sternum by {ME}.',
        '{THEM}\'s death put another notch in {ME}\'s axe.',
        '{THEM} died impossibly!',
        '{THEM} died from {ME}\'s mysterious tropical disease.',
        '{THEM} escaped infection by dying.',
        '{THEM} played hot-potato with a grenade.',
        '{THEM} was knifed by {ME}.',
        '{THEM} fell on his sword.',
        '{THEM} ate a grenade.',
        '{THEM}\'s parents got shot by {ME}.',
        '{THEM} practiced being {ME}\'s clay pigeon.',
        '{THEM} is what\'s for dinner!',
        '{THEM} was terminated by {ME}.',
        '{THEM} was shot before being thrown out of a plane.',
        '{THEM} was not invincible.',
        '{THEM} has encountered an error.',
        '{THEM} died and reincarnated as a goat.',
        '{ME} threw {THEM} off a building.',
        '{THEM} is sleeping with the fishes.',
        '{THEM} got a premature burial.',
        '{ME} replaced all of {THEM}\'s music with Nickelback.',
        '{ME} spammed {THEM}\'s email.',
        '{ME} cut {THEM}\'s genitals off with a rusty pair of scissors!',
        '{ME} made {THEM} a knuckle sandwich.',
        '{ME} slapped {THEM} with pure nothing.',
        '{ME} hit {THEM} with a small, interstellar spaceship.',
        '{THEM} was quickscoped by {ME}.',
        '{ME} put {THEM} in check-mate.',
        '{ME} RSA-encrypted {THEM} and deleted the private key.',
        '{ME} put {THEM} in the friendzone.',
        '{ME} molested {THEM} in a shed.',
        '{ME} slaps {THEM} with a DMCA takedown request!',
        '{THEM} became a corpse blanket for {ME}.',
        'Death is when the monsters get you. Death comes for {THEM}.',
        'Cowards die many times before their death. {THEM} never tasted death but once.',
        '{THEM} died of hospital gangrene.',
        '{THEM} got a house call from Doctor {ME}.',
        '{ME} beheaded {THEM}.',
        '{THEM} got stoned...by an angry mob.',
        '{ME} sued the pants off {THEM}.',
        '{THEM} was impeached.',
        '{THEM} was beaten to a pulp by {ME}.',
        '{THEM} was forced to have cheeky bum sex with {ME}!',
        '{THEM} was one-hit KO\'d by {ME}.',
        '{ME} sent {THEM} to /dev/null.',
        '{ME} sent {THEM} down the memory hole.',
        '{THEM} was a mistake.',
        '{THEM} is a failed abortion.',
        '{THEM}\'s birth certificate is just an apology letter from their local condom dispensary.',
        '\'{THEM} was a mistake.\' - {ME}',
        '{ME} checkmated {THEM} in two moves.',
        '{THEM} was brutally raped by {ME}.'
    }
}

local get_plugins = function(extension, directory)
    extension = extension and tostring(extension) or 'mattata'
    if extension:match('^%.') then
        extension = extension:match('^%.(.-)$')
    end
    directory = directory and tostring(directory) or 'plugins'
    if directory:match('/$') then
        directory = directory:match('^(.-)/$')
    end
    local plugins = {}
    local all = io.popen('ls ' .. directory .. '/'):read('*all')
    for plugin in all:gmatch('[%w_-]+%.' .. extension .. ' ?') do
        plugin = plugin:match('^([%w_-]+)%.' .. extension .. ' ?$')
        table.insert(plugins, plugin)
    end
    return plugins
end

configuration.plugins = get_plugins()
configuration.administrative_plugins = get_plugins(nil, 'plugins/administration')
for _, v in pairs(configuration.administrative_plugins) do
    table.insert(configuration.plugins, v)
end

return configuration

--[[

    End of configuration, you're good to go.
    Use `./launch.sh` to start the bot.
    If you can't execute the script, try running `chmod +x launch.sh`

]]
