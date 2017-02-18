return { -- rename this file to configuration.lua for the bot to work

    ['bot_token'] = '', -- In order for your bot to actually work, you MUST insert the Telegram bot API token you received from @BotFather.

    ['admins'] = {  -- Here you need to specify the numerical ID of the users who shall have FULL control over the bot, this includes access to server files via the lua and shell plugins.

        221714512,
        280653891

    },

    ['info'] = {

        ['name'] = 'mattata', -- The name of your bot.

        ['first_name'] = 'mattata',

        ['last_name'] = nil,

        ['username'] = 'mattatabot', -- The @username of your bot (this can be found through @BotFather).

        ['id'] = 268302625 -- The numerical ID of your bot (this is the preceding string of numbers before the : in your bot API token).

    },

    ['language'] = 'en', -- Two character locale, this is the default language for all users who haven't adjusted their language.

    ['log_chat'] = -1001053691206, -- This needs to be the numerical identifier of the chat you wish to log errors into. If it's not a private chat it should begin with a '-' symbol.

    ['log_admin_actions'] = true, -- If set to true, administrative actions will be logged in the configured channel (the numerical ID should be set as the value of log_channel).

    ['log_channel'] = -1001086181358, -- THe numerical ID of the chat to (if applicable) log administrative actions to.

    ['bug_reports_chat'] = -188808248, -- The numerical ID of the chat to send bug reports to.

    ['counter_channel'] = -1001081940117, -- The numerical ID of the channel to use in order for /counter to work.

    ['download_location'] = '/tmp/', -- The location to save all downloaded media to.

    ['respond_to_misc'] = true, -- This setting determines whether your bot will respond to certain miscellaneous triggers. It MUST be a boolean value.

    ['max_copypasta_length'] = 300, -- The maximum number of characters a message can have to be able to have /copypasta used on it.

    ['debug'] = false, -- If set to true, information about each API update will be printed to the console.

    ['plugins'] = { -- This table lists the plugins which your bot will load upon each instance.

        'control',
        -- To allow things to work properly, you MUST place all new plugins BELOW this line. It is recommended to keep the list clean by ensuring it keeps its alphabetical order.
        'administration',
        'apod',
        'appstore',
        'avatar',
        'base64',
        'bash',
        'binary',
        'bing',
        'bugreport',
        'calc',
        'canitrust',
        'catfact',
        'cats',
        'channel',
        'chuck',
        'clickbait',
        'coinflip',
        'copypasta',
        'counter',
        'currency',
        'developer',
        'dice',
        'dictionary',
        'dns',
        'doge',
        'doggo',
        'donate',
        'duckduckgo',
        'echo',
        'eightball',
        'exec',
        'facebook',
        'faces',
        'fact',
        'flickr',
        'fortune',
        'game',
        'gblacklist',
        'gif',
        'github',
        'githubfeed',
        'google',
        'gwhitelist',
        'hackernews',
        'help',
        'hexadecimal',
        'hextorgb',
        'id',
        'identicon',
        'imdb',
        'instagram',
        'insult',
        'isp',
        'ispwned',
        'isup',
        'itunes',
        'jsondump',
        'lastfm',
        'license',
        'lmgtfy',
        'location',
        'loremipsum',
        'lua',
        'lyrics',
        'me',
        'minecraft',
        'msglink',
        'name',
        'netflix',
        'news',
        'ninegag',
        'paste',
        'pay',
        'ping',
        'plugins',
        'pokedex',
        'prime',
        'pun',
        'qr',
        'randomword',
        'reddit',
        'rimg',
        'rss',
        'sed',
        'setlang',
        'setloc',
        'shorten',
        'shout',
        'slap',
        'snapchat',
        'spotify',
        'statistics',
        'steam',
        'synonym',
        'theme',
        'time',
        'translate',
        'twitch',
        'unicode',
        'upload',
        'urbandictionary',
        'uuid',
        'weather',
        'whois',
        'wikipedia',
        'xkcd',
        'yify',
        'yomama',
        'youtube'

    },

    ['redis'] = { -- Configurable options for connecting your bot to redis. Do NOT modify these settings if you don't know what you're doing!

        ['host'] = '127.0.0.1',

        ['port'] = 6379,

        ['password'] = nil,

        ['db'] = 1

    },

    ['keys'] = { -- API keys needed for the full functionality of several plugins.

        ['cats'] = '', -- http://thecatapi.com/api-key-registration.html

        ['translate'] = '', -- https://tech.yandex.com/keys/get/?service=trnsl

        ['lyrics'] = '', -- https://developer.musixmatch.com/admin/applications

        ['canitrust'] = '', -- https://www.mywot.com/en/signup

        ['apod'] = '', -- https://api.nasa.gov/index.html#apply-for-an-api-key

        ['synonym'] = '', -- https://tech.yandex.com/keys/get/?service=dict

        ['lastfm'] = '', -- http://www.last.fm/api/account/create

        ['weather'] = '', -- https://darksky.net/dev/register

        ['youtube'] = '', -- https://console.developers.google.com/apis

        ['bing'] = '', -- https://datamarket.azure.com/account/keys

        ['flickr'] = '', -- https://www.flickr.com/services/apps/create/noncommercial/?

        ['githubfeed'] = '',

        ['news'] = '',

        ['twitch'] = '',

        ['pastebin'] = '',

        ['dictionary'] = {

            ['id'] = '',

            ['key'] = ''

        },

        ['adfly'] = {

            ['apikey'] = '',

            ['userid'] = ''

        },

        ['pasteee'] = '',

        ['google'] = { -- https://console.developers.google.com/apis

            ['api_key'] = '',

            ['cse_key'] = ''

        },

        ['steam'] = '' -- https://steamcommunity.com/dev/registerkey

    },

    ['errors'] = { -- Messages to provide a more user-friendly approach to instances of errors.

        ['connection'] = 'I\'m sorry, but there was an error whilst I was processing your request, please try again later.',

        ['results'] = 'I\'m sorry, but I couldn\'t find any results for that.'

    },

    ['dice'] = {

        ['max_range'] = 200,

        ['max_count'] = 200,

        ['min_range'] = 2

    },

    ['eightball'] = {

        'It is certain.',
        'It has been confirmed.',
        'Without any doubts.',
        'Yes, definitely.',
        'You may rely on it.',
        'As I see it, yes.',
        'Most likely.',
        'Outlook: not so good.',
        'Yes.',
        'Signs point to yes.',
        'The reply is very weak, try again.',
        'Ask again later.',
        'I can not tell you right now.',
        'Cannot predict right now.',
        'Concentrate, and then ask again.',
        'Do not count on it.',
        'My reply is no.',
        'My sources say possibly.',
        'Outlook: very good.',
        'Very doubtful.',
        'Rowan\'s voice echoes: There is a time and place for everything, but not now.'

    },

    ['join_messages'] = {

        'Welcome, NAME!',
        'Hello, NAME!',
        'Enjoy your stay, NAME!',
        'I\'m glad you joined, NAME!',
        'Howdy, NAME!',
        'Hi, NAME!'

    },

    ['faces'] = { -- Expressive emoticon faces which can be triggered with /<name>.

        ['shrug'] = '¯\\_(ツ)_/¯',

        ['lenny'] = '( ͡° ͜ʖ ͡°)',

        ['flip'] = '(╯°□°）╯︵ ┻━┻',

        ['look'] = 'ಠ_ಠ',

        ['shots'] = 'SHOTS FIRED',

        ['facepalm'] = '(－‸ლ)',

        ['vibrator'] = 'ヽヽ༼༼ຈຈل͜ل͜ຈຈ༽༽ﾉﾉ TURN OFF THE VIBRATOR ヽヽ༼༼ຈຈل͜ل͜ຈຈ༽༽ﾉﾉ',

        ['africa'] = '( ͡° ͜ʖ ͡°) Every 60 seconds in Africa, a minute passes. Together we can stop this. Please spread the word ( ͡° ͜ʖ ͡°)',

        ['chocolate'] = '\n╔╦╦\n╠╬╬╬╣\n╠╬╬╬╣OK! WHO ATE MY\n╠╬╬╬╣CHOCOLATE!!\n╚╩╩╩╝',

        ['kirby'] = '(つ -‘ _ ‘- )つ',

        ['finger'] = '\n⁣               /´¯/)\n             ,/¯  /\n             /   /\n          /´¯/’  ’/´¯¯`·¸\n        /’/  /   /    /¨¯\\\n       (‘(   ´  ´   ¯~/’  ’)\n        \\          ’    /\n        \\   \\       _ ·´\n         \\          (\n          \\          \\,',

        ['rub'] = 'ヽ( ° ͜ʖ͡°)ﾉ ʀuʙ ᴍʏ ᴅᴏɴɢᴇʀ ヽ( ° ͜ʖ͡°)ﾉ',

        ['party'] = '୧༼ ͡◉ل͜ ͡◉༽୨ (ง ͠° ل͜ °)ง ヽ༼ຈل͜ຈ༽ﾉ ༼ ºل͟º ༽ Join da Party ୧༼ ͡◉ل͜ ͡◉༽୨ (ง ͠° ل͜ °)ง ヽ༼ຈل͜ຈ༽ﾉ ༼ ºل͟º ༽',

        ['lift'] = '\n❚█══█❚\nDo you even lift?',

        ['specs'] = 'ᒡ◯ᵔ◯ᒢ'

    }

} -- End of configuration, you're good to go. Use ./launch.sh to start the bot.