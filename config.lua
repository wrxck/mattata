return {
    bot_api_key = '', -- insert your bot API token you received from BotFather
    admin = , -- the numerical ID of the owner, presumably you
    lang = 'en', -- two digit language code
    log_chat = , -- the numerical ID of the chat you wish to log any errors to
    cli_port = 4569, -- the port to use for CLI 
    about_text = [[
I am mattata, a multi-purpose Telegram bot.

Send /help to get started.
    ]],
    cmd_pat = '/',
    drua_block_on_blacklist = false,
    bing_api_key = '',
    google_api_key = '',
    google_cse_key = '',
    owm_api_key = '',
    lastfm_api_key = '',
    biblia_api_key = '',
    thecatapi_key = '',
    nasa_api_key = '',
    yandex_key = '',
    lyricsnmusic_key = '',
    errors = {
        generic = 'Error.',
        connection = 'Connection error.',
        results = 'No results found.',
        argument = 'Invalid argument.',
        syntax = 'Invalid syntax.',
    },
    mattata = {
        cleverbot_api = 'https://brawlbot.tk/apis/chatter-bot-api/cleverbot.php?text=',
        connection = 'I don\'t feel like talking right now.',
        response = 'I don\'t know what to say to that.'
    },
    plugins = {
        'control',
        'administration',
        'blacklist',
        'about',
        'id',
        'nick',
        'bandersnatch',
        'autoresponses',
        'wikipedia',
        'simplewikipedia',
        'remind',
        'ping',
        'calc',
        'urbandictionary',
        'pokemon-go',
        'dice',
        'imdb',
        'patterns',
        'me',
        'shout',
        'slap',
        'time',
        'translate',
        'preview',
        'reddit',
        'channel',
        'pokego-calculator',
        'commit',
        'pun',
        'cats',
        'catfact',
        'currency',
        'pokedex',
        'echo',
        'fortune',
        'isup',
        'chuck',
        'loremipsum',
        'baconipsum',
        'skateipsum',
        'starwars',
        'lua',
        'cleverbot',
        'setandget',
        'reactions',
        '9gag',
        'lyrics',
        'fact',
        'help',
        'autoresponses'
    }
}