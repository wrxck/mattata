return { -- when you're translating, do NOT translate the things in CAPS!
    locale = 'ru',
    join_messages = {
        'Добро пожаловать, NAME!',
        'Привет, NAME!',
        'Наслаждайся группой, NAME!',
        'Как хорошо что ты зашёл, NAME!',
        'Хей, NAME!',
        'Хай, NAME!'
    },
    user_added_bot = 'Привет! Спасибо что добавил меня, NAME!',
    left_messages = {
        'RIP NAME.',
        'Rest in peace, NAME!',
        'Я очень надеюсь, что NAME понравилась группа!',
        'Я что-то сказал не так, NAME?',
        'Мы только начали узнавать друг друга, NAME...',
        'Боже, NAME - неужели я НАСТОЛЬКО плох?',
        'Это большая потеря, NAME.',
        'Возвращайся поскорее, NAME!',
        'Пока, NAME!',
        'Увидимся, NAME.',
        'Счастливо оставаться, NAME.'
    },
    errors = {
        generic = 'К сожалению произошла ошибка!',
        connection = 'К сожалению произошла ошибка при обработке вашего запро, попробуйте позже.',
        results = 'К сожалению мне не вышло найти резльтатов для этого.'
    },
    ['ai'] = {
        ['57'] = 'Мои слова: NAME, для всего есть время и место, но не сейчас!'
    },
    specify_blacklisted_user = 'Пожалуйста используйте ID чтоб передать мне пользователя.',
    user_now_blacklisted = 'Этот пользователь теперь в моём чёрном списке.',
    user_now_whitelisted = 'Этот пользователь был удалён из чёрного списка.',
    message_sent_to_channel = 'Ваше сообщение было отправлено!',
    unable_to_send_to_channel = 'К сожалению я не смог отправить ваше сообщение.',
    enter_message_to_send_to_channel = 'Пожалуйста введите сообщение. Поддерживается орматирование с использованием markdown.',
    not_channel_admin = 'К сожалению вы не администратор этого канала/группы.',
    unable_to_retrieve_channel_admins = 'К сожалению я не мог получить список администраторов этого канала/группы.\n',
    ['copypasta'] = {
        ['45'] = 'Пожалуйста ответьте на сообщение с меньшим количеством символов, чем MAXIMUM.'
    },
    found_one_pwned_account = 'Этот аккаунт был найден в 1 утечке.',
    account_found_multiple_leaks = 'Этот аккаунт был найден в X утечках',
    official_links = 'Here are some official links that you may find useful!',
    help_introduction = '*Hello, NAME!*\nMy name is MATTATA and I\'m an intelligent bot written with precision. There are many things I can do - try clicking the \'Commands\' button below to see what I can do for you.\n\n*Oh, and I work well in groups, too!*\nYou can enable and disable plugins in your group(s) using /plugins.\nI also feature a multilingual mode (currently in beta), try using /setlang <language> to adjust your language. That way, when you have a conversation with me, I\'ll make sure to always respond in your language!',
    help_confused = '*Confused?*\nDon\'t worry, I was programmed to help! Try using /help <command> to get help with a specific plugin and its usage.\n\nI\'m also an innovative example of artificial intelligence - yes, that\'s right; I can learn from you! Try speaking to me right here, or mention me by my name in a group. I can also describe images sent in response to messages I send.\n\nYou can also use me inline, try mentioning my username from any group and discover what else I can do!',
    no_documented_help = 'I\'m sorry, but I\'m afraid there is no help documented for that plugin at this moment in time. If you believe this is a mistake, please don\'t hesitate to contact [my developer](https://telegram.me/wrxck).',
    help_about = 'I\'m a bot written in Lua, and built to take advantage of the brilliant Bot API which Telegram offers.\n\nMy creator (and primary maintainer) is @wrxck.\nHe believes that anybody who enjoys programming should be able to work with the code of which I was compiled from, so I\'m proud to say that I am an open source project, which you can discover more about on [GitHub](https://github.com/matthewhesketh/mattata).',
    please_message_me = 'Please [message me in a private chat](http://telegram.me/MATTATA?start=help) to get started.',
    sent_private_message = 'I have sent you a private message containing the requested information.',
	['setlang'] = {
		['112'] = 'You can only use this command in private chat!'
	}
}