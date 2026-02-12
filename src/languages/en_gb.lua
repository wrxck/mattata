--[[
    mattata v2.0 - English (GB) Language File
]]

return {
    errors = {
        connection = 'Connection error.',
        results = 'I couldn\'t find any results for that.',
        supergroup = 'This command can only be used in supergroups.',
        admin = 'You need to be a moderator or an administrator to use this command.',
        unknown = 'I don\'t recognise that user. Forward a message from them to any chat I\'m in.',
        generic = 'An unexpected error occurred.',
        private = 'You can only use this command in private chat.'
    },
    help = {
        greeting = 'Hey %s! I\'m <b>%s</b>, a feature-rich Telegram bot.',
        no_results = 'No commands found matching "%s".',
        page_info = 'Page %d of %d',
        commands = 'Commands',
        admin_help = 'Admin Help',
        links = 'Links',
        settings = 'Settings',
        back = 'Back',
        next_page = 'Next',
        prev_page = 'Previous'
    },
    afk = {
        no_username = 'This feature requires a public @username.',
        returned = '%s has returned after being AFK for %s!',
        now_afk = '%s is now AFK.%s',
        is_afk = '%s is currently AFK!',
        note = '\nNote: %s'
    },
    weather = {
        no_location = 'Please specify a location, or set your default with /setloc.',
        format = 'Temperature: %s (feels like %s)\nConditions: %s\nWind: %s km/h\nHumidity: %s%%\nLocation: %s'
    },
    ban = {
        specify = 'Please specify the user to ban.',
        is_admin = 'I can\'t ban an admin or moderator.',
        already_banned = 'That user is already banned.',
        no_permission = 'I don\'t have permission to ban users.',
        success = '%s has banned %s.',
        log = '%s [%s] has banned %s [%s] from %s [%s]%s.'
    },
    warn = {
        specify = 'Please specify the user to warn.',
        success = '%s has warned %s%s. [%d/%d]',
        threshold = '%d/%d warnings reached - user has been banned.',
        reset = 'Warnings reset by %s!',
        removed = 'Warning removed by %s! [%s/%s]'
    },
    kick = {
        specify = 'Please specify the user to kick.',
        not_in_chat = 'That user is not in this chat.',
        success = '%s has kicked %s.'
    },
    mute = {
        specify = 'Please specify the user to mute.',
        success = '%s has muted %s%s.'
    },
    unmute = {
        success = '%s has unmuted %s.'
    },
    rules = {
        no_rules = 'No rules have been set for this group. Admins can set them with /setrules.',
        header = '<b>Rules for %s:</b>\n\n%s'
    },
    welcome = {
        default = 'Welcome to the group, {NAME}!',
        set = 'Welcome message has been updated.',
        current = 'Current welcome message:\n%s'
    },
    statistics = {
        header = '<b>Message statistics for %s:</b>\n\n',
        no_stats = 'No statistics available for this group.',
        total = '\n<b>Total: %d messages</b>',
        reset = 'Statistics have been reset.'
    },
    setlang = {
        header = 'Select your preferred language:',
        set = 'Language has been set to %s.'
    },
    setloc = {
        no_input = 'Please specify a location.',
        set = 'Your location has been set to: %s',
        not_found = 'I couldn\'t find that location.'
    },
    remind = {
        no_input = 'Please specify a duration and message. Example: /remind 2h Take out the bins',
        set = 'Reminder set! I\'ll remind you in %s.',
        fired = 'Reminder for %s: %s',
        max_reached = 'You can only have %d active reminders per chat.',
        list_header = '<b>Active reminders:</b>\n',
        none = 'You have no active reminders.'
    },
    translate = {
        no_input = 'Please provide text to translate, or reply to a message.',
        result = '<b>Translation (%s):</b>\n%s'
    },
    nick = {
        set = 'Your nickname has been set to: %s',
        removed = 'Your nickname has been removed.',
        current = 'Your current nickname is: %s',
        too_long = 'Nicknames can\'t be longer than 128 characters.'
    },
    currency = {
        no_input = 'Please use the format: /currency <amount> <FROM> to <TO>',
        result = '%s %s = <b>%s %s</b>'
    },
    format_time = {
        second = 'second', seconds = 'seconds',
        minute = 'minute', minutes = 'minutes',
        hour = 'hour', hours = 'hours',
        day = 'day', days = 'days',
        week = 'week', weeks = 'weeks'
    }
}
