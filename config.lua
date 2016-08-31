return {
    bot_api_key = '', -- insert the bot API token you received from BotFather
    admin = , -- the numerical ID of the owner, who is presumably you
    lang = 'en', -- two digit locale
    log_chat = , -- the numerical ID of the chat you wish to log errors/private messages to, you can add telegram.me/groupinfobot to your group to view this information, if necessary
    about_text = [[
I am mattata, a multi-purpose Telegram bot.

Send /help to get started.
    ]],
    command_prefix = '/',
    thecatapi_key = '', -- you can get one of these by heading to http://thecatapi.com/api-key-registration.html
    yandex_key = '', -- you can get one of these by heading to https://tech.yandex.com/keys/get/?service=trnsl
    lyricsnmusic_key = '', -- you can get one of these by heading to http://www.lyricsnmusic.com/api_keys/new
    baconipsum_api = 'https://baconipsum.com/api/?type=all-meat&sentences=3&start-with-lorem=1&format=text' -- removing this will break baconipsum.lua and may result in further errors or even a consequental loss of data
    calc_api = 'https://api.mathjs.org/v1/?expr='
    errors = {
        generic = 'WELP. That\'s an error!',
        connection = 'I\'m sorry, but there was a connection error whilst processing your request, please try again later.',
        results = 'I\'m sorry, but I couldn\'t find any results for that.',
        argument = 'I\'m sorry, but the given arguments were either invalid or non-existent.',
        syntax = 'Error. Invalid syntax.',
    },
    messaging = {
        api_url = 'https://brawlbot.tk/apis/chatter-bot-api/cleverbot.php?text=',
        connection_error = 'Rowan\'s words echoed: There\'s a time and place for everything! But not now.',
        response_error = 'I\'m not sure how to answer that...'
    },
    plugins = {
        'control',
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
        'setandget',
        'reactions',
        '9gag',
        'lyrics',
        'fact',
        'help',
        'autoresponses',
        'messaging'
    }
}
