return { -- Rename this file to configuration.lua for the bot to work.
    ['bot_token'] = '', -- In order for the bot to actually work, you MUST insert the Telegram bot API token you received from @BotFather.
    ['admins'] = {  -- Here you need to specify the numerical ID of the users who shall have FULL control over the bot, this includes access to server files via the lua and shell plugins.
        nil
    },
    ['language'] = 'en', -- The two character locale to set your default language to, this is also the default language for all users who haven't adjusted their language
    ['log_chat'] = nil, -- This needs to be the numerical identifier of the chat you wish to log errors into. If it's not a private chat it should begin with a '-' symbol.
    ['log_admin_actions'] = true,
    ['log_channel'] = nil,
    ['admin_log_chat'] = nil,
    ['bug_reports_chat'] = nil,
    ['counter_channel'] = nil,
    ['download_location'] = '/tmp/', -- The location to save all downloaded media to.
    ['respond_to_misc'] = true,
    ['max_copypasta_length'] = 300, -- The maximum number of characters a message can have to be able to have /copypasta used on it.
    ['debug'] = false,
    ['plugins'] = { -- This table lists the plugins which the bot will load upon each instance.
        'control',
        -- To allow things to work properly, you MUST place all new plugins BELOW this line. It is recommended to keep the list clean by ensuring it keeps its alphabetical order.
        'administration',
        'aesthetic',
        'apod',
        'appstore',
        'avatar',
        'ban',
        'base64',
        'bash',
        'belikebill',
        'bing',
        'blacklist',
        'blacklistchat',
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
        'custom',
        'demote',
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
        'fakeid',
        'fileid',
        'flickr',
        'fortune',
        'frombinary',
        'game',
        'gblacklist',
        'gif',
        'github',
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
        'ipsw',
        'isp',
        'ispwned',
        'isup',
        'itunes',
        'jsondump',
        'kick',
        'lastfm',
        'license',
        'lmgtfy',
        'location',
        'logchat',
        'loremipsum',
        'lua',
        'lyrics',
        'me',
        'minecraft',
        'msglink',
        'name',
        'netflix',
        'news',
        'nick',
        'ninegag',
        'obama',
        'optout',
        'paste',
        'pay',
        'ping',
        'plugins',
        'pokedex',
        'prime',
        'promote',
        'pun',
        'qr',
        'quote',
        'randomcolor',
        'randomsite',
        'randomword',
        'reddit',
        'remind',
        'rimg',
        'rms',
        'rss',
        'save',
        'sed',
        'setai',
        'setlang',
        'setloc',
        'settings',
        'setwelcome',
        'share',
        'shorten',
        'shout',
        'shsh',
        'slap',
        'snapchat',
        'spotify',
        'statistics',
        'steam',
        'synonym',
        'theme',
        'thoughts',
        'time',
        'tobinary',
        'tpb',
        'translate',
        'twitch',
        'unban',
        'unicode',
        'upload',
        'urbandictionary',
        'user',
        'uuid',
        'version',
        'warn',
        'weather',
        'whois',
        'wikipedia',
        'xkcd',
        'yify',
        'yomama',
        'youtube'
    },
    ['redis'] = { -- Configurable options for connecting the bot to redis. Do NOT modify these settings if you don't know what you're doing!
        ['host'] = '127.0.0.1',
        ['port'] = 6379,
        ['password'] = nil,
        ['db'] = 2
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
        ['githubfeed'] = '', -- https://github.com/settings/tokens/new
        ['news'] = '', -- https://newsapi.org/
        ['witai'] = '', -- https://wit.ai/
        ['twitch'] = '', -- https://twitchapps.com/tmi/
        ['pastebin'] = '', -- https://pastebin.com/api
        ['dictionary'] = {  -- https://developer.oxforddictionaries.com/
            ['id'] = '',
            ['key'] = ''
        },
        ['adfly'] = { -- https://login.adf.ly/login
            ['apikey'] = '',
            ['userid'] = ''
        },
        ['pasteee'] = '', -- https://paste.ee/
        ['google'] = { -- https://console.developers.google.com/apis
            ['api_key'] = '',
            ['cse_key'] = ''
        },
        ['steam'] = '' -- https://steamcommunity.com/dev/apikey
    },
    ['errors'] = { -- Messages to provide a more user-friendly approach to errors.
        ['connection'] = 'The connection timed out, perhaps there is a fault with an external API this feature is dependent on?',
        ['results'] = 'I couldn\'t find any results for that.',
        ['supergroup'] = 'This command can only be used in supergroups.',
        ['admin'] = 'You need to be a moderator or an administrator in this chat in order to use this!',
        ['unknown'] = 'I don\'t recognise that user. If you would like to teach me who they are, forward a message from them into any chat that I\'m in.',
        ['generic'] = 'An unexpected error occured. Please report this error using /br.'
    },
    ['dice'] = {
        ['max_range'] = 200,
        ['max_count'] = 200,
        ['min_range'] = 2
    },
    ['administration'] = {
        ['warnings'] = {
            ['maximum'] = 10,
            ['minimum'] = 2
        }
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
        ['specs'] = 'ᒡ◯ᵔ◯ᒢ',
        ['sigh'] = '( ._.)'
    },
    ['stickers'] = {
        ['ban'] = {
            'CAADBAADzwIAAlAYNw1h7nezc1nH7gI',
            'CAADBAAD0AIAAlAYNw13TaMgAYaXywI'
        },
        ['warn'] = {
            'CAADBAAD0QIAAlAYNw1wPS6g_arjDgI',
            'CAADBAAD0gIAAlAYNw2-pLQLQonbCQI'
        },
        ['kick'] = {
            'CAADBAAD0wIAAlAYNw3KIKm0bVviWwI'
        }
    }
} -- End of configuration, you're good to go. Use ./launch.sh to start the bot.