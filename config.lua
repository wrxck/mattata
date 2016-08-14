return {
    bot_api_key = '', -- Insert the bot API token you received from @BotFather
    admin = 00000000, -- Replace 00000000 with your numerical user ID
    lang = 'en',
    log_chat = -00000000, -- Replace -00000000 with the numerical ID of the group you wish mattata to print information from the console
    cli_port = 4569, -- If you change this, make sure you also change the port in tg-launch.sh
    about_text = [[
I am mattata, a multi-purpose Telegram bot.

Send /help to get started.
    ]],
    cmd_pat = '/', -- The symbol to start a command with, usually '/'
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
    errors = {
        generic = 'Error.',
        connection = 'Connection error.',
        results = 'No results found.',
        argument = 'Invalid argument.',
        syntax = 'Invalid syntax.',
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
-- Enter any new plugins above this line
        'help',
        'autoresponses'
    }
}