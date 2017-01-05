return { -- rename this file to configuration.lua for mattata to work
    bot_token = '', -- In order for your copy of mattata to actually work, you MUST insert the Telegram bot API token you received from @BotFather.
    admins = {  -- Here you need to specify the numerical ID of the users who shall have FULL control over mattata, this includes access to server files via the lua and shell plugins.
        nil
    },
    language = 'en', -- two character locale, this is the default language for all users who haven't adjusted their language
    log_chat = nil, -- This needs to be the numerical identifier of the chat you wish to log errors into. If it's not a private chat it should begin with a '-' symbol.
    log_admin_actions = true,
    log_channel = nil,
    command_prefix = '/', -- the symbol bot commands will be executed with ('/' by default)
	download_location = '/tmp/', -- the location to save all downloaded media to
    process_message_edits = true, -- change this to false to stop mattata from processing message edits
    respond_to_memes = true, -- This setting determines whether your copy of mattata will respond to certain memes. It MUST be a boolean value.
    respond_to_lyrics = true, -- This value determines whether your copy of mattata will respond to certain lyrics. Like the 'respond_to_memes' setting, it MUST be a boolean value.
    maximum_copypasta_length = 300, -- the maximum number of characters a message can have to be parsed through /copypasta
    debug = true,
    plugins = { -- This table lists the plugins which your copy of mattata will load upon each instance.
        'control',
        -- To allow things to work properly, you MUST place all new plugins BELOW this line. It is recommended to keep the list clean by ensuring it keeps its alphabetical order.
        'apod',
        'appstore',
        'author',
        'base64',
        'bash',
        'binary',
        'bing',
        'calc',
        'canitrust',
        'catfact',
        'cats',
        'channel',
        'chuck',
        'coinflip',
        'copypasta',
        'currency',
        'dice',
        'dictionary',
        'dns',
        'doge',
        'doggo',
        'echo',
        'eightball',
        'emoji',
        'exec',
        'facebook',
        'faces',
        'fact',
        'flickr',
        'giphy',
        'github',
        'githubfeed',
        'hackernews',
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
        'lmgtfy',
        'location',
        'loremipsum',
        'lua',
        'lyrics',
        'minecraft',
        'nick',
        'ninegag',
        'paste',
        'ping',
        'plugins',
        'pokedex',
        'prime',
        'pun',
        'qr',
        'randomword',
        'reddit',
        'rss',
        'sed',
        'setlang',
        'setloc',
        'shorten',
        'shout',
        'spotify',
        'statistics',
        'synonym',
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
        'youtube',
        'help'
    },
    administration = { -- This table lists the administration plugins which your copy of mattata will load upon each instance.
        'admins',
        'antispam',
        'ban',
        'blacklist',
        'buttons',
        'gblacklist',
        'groups',
        'kick',
        'link',
        'msglink',
        'report',
        'rules',
        'unban',
        'warn',
        'welcome',
        'whitelist'
    },
    groups = { -- A table of groups that will be sorted and displayed upon execution of the groups plugin.
        ['mattata support'] = 'https://telegram.me/joinchat/DTcYUD7ELOondGVro-8PZQ',
        ['mattata development'] = 'https://telegram.me/joinchat/DTcYUEDWD1IgrvQDrkKH0w',
        ['Bot Playground'] = 'https://telegram.me/joinchat/DTcYUD8dZJvnclwDArucnQ',
        ['Off-Topic Geeks'] = 'https://telegram.me/OffTopicGeeks',
        ['DevTalk'] = 'https://telegram.me/DevTalk',
        ['Music'] = 'https://telegram.me/MusicChat',
        ['Cancer'] = 'https://telegram.me/CancerChat',
        ['Rextesters'] = 'https://telegram.me/Rextesters'
    },
    redis = { -- Configurable options for binding your copy of mattata to Redis. Do NOT modify these settings if you don't know what you're doing!
        host = '127.0.0.1',
        port = 6379,
        use_password = false,
        password = '',
        database = 2
    },
    keys = { -- API keys needed for the full functionality of several plugins.
        cats = '', -- http://thecatapi.com/api-key-registration.html
        translate = '', -- https://tech.yandex.com/keys/get/?service=trnsl
        lyrics = '', -- https://developer.musixmatch.com/admin/applications
        canitrust = '', -- https://www.mywot.com/en/signup
        apod = '', -- https://api.nasa.gov/index.html#apply-for-an-api-key
        synonym = '', -- https://tech.yandex.com/keys/get/?service=dict
        lastfm = '', -- http://www.last.fm/api/account/create
        weather = '', -- https://openweathermap.org/api
        google = '', -- https://console.developers.google.com/apis
        bing = '', -- https://datamarket.azure.com/account/keys
        flickr = '', -- https://www.flickr.com/services/apps/create/noncommercial/?
        githubfeed = '',
        news = '',
        witai = '',
        twitch = '',
        pastebin = '',
        dictionary = {
            id = '',
            key = ''
        },
        adfly = {
            apikey = '',
            userid = ''
        },
        pasteee = ''
    },
    errors = { -- Messages to provide a more user-friendly approach to instances of errors.
        generic = 'I\'m afraid an error has occured!',
        connection = 'I\'m sorry, but there was an error whilst I was processing your request, please try again later.',
        results = 'I\'m sorry, but I couldn\'t find any results for that.'
    },
    dice = {
        max_range = 200,
        max_count = 200,
        min_range = 2
    },
    eightball = {
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
    faces = { -- Expressive emoticon faces which can be triggered with /<name>.
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
}

--[[

    Well, it looks like you've reached the end of the configuration file, so you're good to go!
    Make sure this file is called 'configuration.lua'; then you can run ./launch.sh and have fun!
    
    :^)
    
]]--