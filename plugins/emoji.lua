--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local emoji = {}

local mattata = require('mattata')
local utf8 = require('lua-utf8')

function emoji:init(configuration)
    emoji.arguments = 'emoji <emoji>'
    emoji.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('emoji').table
    emoji.help = configuration.command_prefix .. 'emoji <emoji> - Sends information about the given emoji.'
end

local emoji_list = { -- Sourced from https://github.com/github/gemoji/blob/master/db/emoji.json
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😀',
        ['description'] = 'grinning face',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😃',
        ['description'] = 'smiling face with open mouth',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😄',
        ['description'] = 'smiling face with open mouth & smiling eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😁',
        ['description'] = 'grinning face with smiling eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😆',
        ['description'] = 'smiling face with open mouth & closed eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😅',
        ['description'] = 'smiling face with open mouth & cold sweat',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😂',
        ['description'] = 'face with tears of joy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤣',
        ['description'] = 'rolling on the floor laughing',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '☺️',
        ['description'] = 'smiling face',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😊',
        ['description'] = 'smiling face with smiling eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😇',
        ['description'] = 'smiling face with halo',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🙂',
        ['description'] = 'slightly smiling face',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🙃',
        ['description'] = 'upside-down face',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😉',
        ['description'] = 'winking face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😌',
        ['description'] = 'relieved face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😍',
        ['description'] = 'smiling face with heart-eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😘',
        ['description'] = 'face blowing a kiss',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😗',
        ['description'] = 'kissing face',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😙',
        ['description'] = 'kissing face with smiling eyes',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😚',
        ['description'] = 'kissing face with closed eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😋',
        ['description'] = 'face savouring delicious food',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😜',
        ['description'] = 'face with stuck-out tongue & winking eye',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😝',
        ['description'] = 'face with stuck-out tongue & closed eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😛',
        ['description'] = 'face with stuck-out tongue',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🤑',
        ['description'] = 'money-mouth face',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🤗',
        ['description'] = 'hugging face',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🤓',
        ['description'] = 'nerd face',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😎',
        ['description'] = 'smiling face with sunglasses',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤡',
        ['description'] = 'clown face',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤠',
        ['description'] = 'cowboy hat face',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😏',
        ['description'] = 'smirking face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😒',
        ['description'] = 'unamused face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😞',
        ['description'] = 'disappointed face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😔',
        ['description'] = 'pensive face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😟',
        ['description'] = 'worried face',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😕',
        ['description'] = 'confused face',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🙁',
        ['description'] = 'slightly frowning face',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☹️',
        ['description'] = 'frowning face',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😣',
        ['description'] = 'persevering face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😖',
        ['description'] = 'confounded face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😫',
        ['description'] = 'tired face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😩',
        ['description'] = 'weary face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😤',
        ['description'] = 'face with steam from nose',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😠',
        ['description'] = 'angry face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😡',
        ['description'] = 'pouting face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😶',
        ['description'] = 'face without mouth',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😐',
        ['description'] = 'neutral face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😑',
        ['description'] = 'expressionless face',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😯',
        ['description'] = 'hushed face',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😦',
        ['description'] = 'frowning face with open mouth',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😧',
        ['description'] = 'anguished face',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😮',
        ['description'] = 'face with open mouth',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😲',
        ['description'] = 'astonished face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😵',
        ['description'] = 'dizzy face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😳',
        ['description'] = 'flushed face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😱',
        ['description'] = 'face screaming in fear',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😨',
        ['description'] = 'fearful face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😰',
        ['description'] = 'face with open mouth & cold sweat',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😢',
        ['description'] = 'crying face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😥',
        ['description'] = 'disappointed but relieved face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤤',
        ['description'] = 'drooling face',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😭',
        ['description'] = 'loudly crying face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😓',
        ['description'] = 'face with cold sweat',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😪',
        ['description'] = 'sleepy face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😴',
        ['description'] = 'sleeping face',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🙄',
        ['description'] = 'face with rolling eyes',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🤔',
        ['description'] = 'thinking face',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤥',
        ['description'] = 'lying face',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😬',
        ['description'] = 'grimacing face',
        ['unicode_version'] = '6.1',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🤐',
        ['description'] = 'zipper-mouth face',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤢',
        ['description'] = 'nauseated face',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤧',
        ['description'] = 'sneezing face',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😷',
        ['description'] = 'face with medical mask',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🤒',
        ['description'] = 'face with thermometer',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🤕',
        ['description'] = 'face with head-bandage',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😈',
        ['description'] = 'smiling face with horns',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👿',
        ['description'] = 'angry face with horns',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👹',
        ['description'] = 'ogre',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👺',
        ['description'] = 'goblin',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💩',
        ['description'] = 'pile of poo',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👻',
        ['description'] = 'ghost',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💀',
        ['description'] = 'skull',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☠️',
        ['description'] = 'skull and crossbones',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👽',
        ['description'] = 'alien',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👾',
        ['description'] = 'alien monster',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🤖',
        ['description'] = 'robot face',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎃',
        ['description'] = 'jack-o-lantern',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😺',
        ['description'] = 'smiling cat face with open mouth',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😸',
        ['description'] = 'grinning cat face with smiling eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😹',
        ['description'] = 'cat face with tears of joy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😻',
        ['description'] = 'smiling cat face with heart-eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😼',
        ['description'] = 'cat face with wry smile',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😽',
        ['description'] = 'kissing cat face with closed eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙀',
        ['description'] = 'weary cat face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😿',
        ['description'] = 'crying cat face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '😾',
        ['description'] = 'pouting cat face',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👐',
        ['description'] = 'open hands',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙌',
        ['description'] = 'raising hands',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👏',
        ['description'] = 'clapping hands',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙏',
        ['description'] = 'folded hands',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤝',
        ['description'] = 'handshake',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👍',
        ['description'] = 'thumbs up',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👎',
        ['description'] = 'thumbs down',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👊',
        ['description'] = 'oncoming fist',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✊',
        ['description'] = 'raised fist',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤛',
        ['description'] = 'left-facing fist',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤜',
        ['description'] = 'right-facing fist',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤞',
        ['description'] = 'crossed fingers',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✌️',
        ['description'] = 'victory hand',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🤘',
        ['description'] = 'sign of the horns',
        ['unicode_version'] = '8.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👌',
        ['description'] = 'OK hand',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👈',
        ['description'] = 'backhand index pointing left',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👉',
        ['description'] = 'backhand index pointing right',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👆',
        ['description'] = 'backhand index pointing up',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👇',
        ['description'] = 'backhand index pointing down',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '☝️',
        ['description'] = 'index pointing up',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✋',
        ['description'] = 'raised hand',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤚',
        ['description'] = 'raised back of hand',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖐',
        ['description'] = 'raised hand with fingers splayed',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🖖',
        ['description'] = 'vulcan salute',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👋',
        ['description'] = 'waving hand',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤙',
        ['description'] = 'call me hand',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💪',
        ['description'] = 'flexed biceps',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖕',
        ['description'] = 'middle finger',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '✍️',
        ['description'] = 'writing hand',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤳',
        ['description'] = 'selfie',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💅',
        ['description'] = 'nail polish',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💍',
        ['description'] = 'ring',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💄',
        ['description'] = 'lipstick',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💋',
        ['description'] = 'kiss mark',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👄',
        ['description'] = 'mouth',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👅',
        ['description'] = 'tongue',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👂',
        ['description'] = 'ear',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👃',
        ['description'] = 'nose',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👣',
        ['description'] = 'footprints',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '👁',
        ['description'] = 'eye',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👀',
        ['description'] = 'eyes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗣',
        ['description'] = 'speaking head',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👤',
        ['description'] = 'bust in silhouette',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👥',
        ['description'] = 'busts in silhouette',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👶',
        ['description'] = 'baby',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👦',
        ['description'] = 'boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👧',
        ['description'] = 'girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👨',
        ['description'] = 'man',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👩',
        ['description'] = 'woman',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👱‍♀️',
        ['description'] = 'blond-haired woman',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👱',
        ['description'] = 'blond-haired person',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👴',
        ['description'] = 'old man',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👵',
        ['description'] = 'old woman',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👲',
        ['description'] = 'man with Chinese cap',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👳‍♀️',
        ['description'] = 'woman wearing turban',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👳',
        ['description'] = 'person wearing turban',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👮‍♀️',
        ['description'] = 'woman police officer',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👮',
        ['description'] = 'police officer',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👷‍♀️',
        ['description'] = 'woman construction worker',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👷',
        ['description'] = 'construction worker',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '💂‍♀️',
        ['description'] = 'woman guard',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💂',
        ['description'] = 'guard',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🕵️‍♀️',
        ['description'] = 'woman detective',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕵️',
        ['description'] = 'detective',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍⚕️',
        ['description'] = 'woman health worker',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍⚕️',
        ['description'] = 'man health worker',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🌾',
        ['description'] = 'woman farmer',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🌾',
        ['description'] = 'man farmer',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🍳',
        ['description'] = 'woman cook',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🍳',
        ['description'] = 'man cook',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🎓',
        ['description'] = 'woman student',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🎓',
        ['description'] = 'man student',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🎤',
        ['description'] = 'woman singer',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🎤',
        ['description'] = 'man singer',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🏫',
        ['description'] = 'woman teacher',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🏫',
        ['description'] = 'man teacher',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🏭',
        ['description'] = 'woman factory worker',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🏭',
        ['description'] = 'man factory worker',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍💻',
        ['description'] = 'woman technologist',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍💻',
        ['description'] = 'man technologist',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍💼',
        ['description'] = 'woman office worker',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍💼',
        ['description'] = 'man office worker',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🔧',
        ['description'] = 'woman mechanic',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🔧',
        ['description'] = 'man mechanic',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🔬',
        ['description'] = 'woman scientist',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🔬',
        ['description'] = 'man scientist',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🎨',
        ['description'] = 'woman artist',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🎨',
        ['description'] = 'man artist',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🚒',
        ['description'] = 'woman firefighter',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🚒',
        ['description'] = 'man firefighter',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍✈️',
        ['description'] = 'woman pilot',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍✈️',
        ['description'] = 'man pilot',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍🚀',
        ['description'] = 'woman astronaut',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍🚀',
        ['description'] = 'man astronaut',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👩‍⚖️',
        ['description'] = 'woman judge',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '👨‍⚖️',
        ['description'] = 'man judge',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤶',
        ['description'] = 'Mrs. Claus',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎅',
        ['description'] = 'Santa Claus',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👸',
        ['description'] = 'princess',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤴',
        ['description'] = 'prince',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👰',
        ['description'] = 'bride with veil',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤵',
        ['description'] = 'man in tuxedo',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👼',
        ['description'] = 'baby angel',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤰',
        ['description'] = 'pregnant woman',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🙇‍♀️',
        ['description'] = 'woman bowing',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙇',
        ['description'] = 'person bowing',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💁',
        ['description'] = 'person tipping hand',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '💁‍♂️',
        ['description'] = 'man tipping hand',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙅',
        ['description'] = 'person gesturing NO',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🙅‍♂️',
        ['description'] = 'man gesturing NO',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙆',
        ['description'] = 'person gesturing OK',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🙆‍♂️',
        ['description'] = 'man gesturing OK',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙋',
        ['description'] = 'person raising hand',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🙋‍♂️',
        ['description'] = 'man raising hand',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤦‍♀️',
        ['description'] = 'woman facepalming',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤦‍♂️',
        ['description'] = 'man facepalming',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤷‍♀️',
        ['description'] = 'woman shrugging',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤷‍♂️',
        ['description'] = 'man shrugging',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙎',
        ['description'] = 'person pouting',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🙎‍♂️',
        ['description'] = 'man pouting',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙍',
        ['description'] = 'person frowning',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🙍‍♂️',
        ['description'] = 'man frowning',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💇',
        ['description'] = 'person getting haircut',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '💇‍♂️',
        ['description'] = 'man getting haircut',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💆',
        ['description'] = 'person getting massage',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '💆‍♂️',
        ['description'] = 'man getting massage',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕴',
        ['description'] = 'man in business suit levitating',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💃',
        ['description'] = 'woman dancing',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🕺',
        ['description'] = 'man dancing',
        ['unicode_version'] = '9.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👯',
        ['description'] = 'people with bunny ears partying',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👯‍♂️',
        ['description'] = 'men with bunny ears partying',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🚶‍♀️',
        ['description'] = 'woman walking',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚶',
        ['description'] = 'person walking',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🏃‍♀️',
        ['description'] = 'woman running',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏃',
        ['description'] = 'person running',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👫',
        ['description'] = 'man and woman holding hands',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👭',
        ['description'] = 'two women holding hands',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👬',
        ['description'] = 'two men holding hands',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💑',
        ['description'] = 'couple with heart',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👩‍❤️‍👩',
        ['description'] = 'couple with heart: woman, woman',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍❤️‍👨',
        ['description'] = 'couple with heart: man, man',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💏',
        ['description'] = 'kiss',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👩‍❤️‍💋‍👩',
        ['description'] = 'kiss: woman, woman',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍❤️‍💋‍👨',
        ['description'] = 'kiss: man, man',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👪',
        ['description'] = 'family',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍👩‍👧',
        ['description'] = 'family: man, woman, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍👩‍👧‍👦',
        ['description'] = 'family: man, woman, girl, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍👩‍👦‍👦',
        ['description'] = 'family: man, woman, boy, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍👩‍👧‍👧',
        ['description'] = 'family: man, woman, girl, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👩‍👩‍👦',
        ['description'] = 'family: woman, woman, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👩‍👩‍👧',
        ['description'] = 'family: woman, woman, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👩‍👩‍👧‍👦',
        ['description'] = 'family: woman, woman, girl, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👩‍👩‍👦‍👦',
        ['description'] = 'family: woman, woman, boy, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👩‍👩‍👧‍👧',
        ['description'] = 'family: woman, woman, girl, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍👨‍👦',
        ['description'] = 'family: man, man, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍👨‍👧',
        ['description'] = 'family: man, man, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍👨‍👧‍👦',
        ['description'] = 'family: man, man, girl, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍👨‍👦‍👦',
        ['description'] = 'family: man, man, boy, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '👨‍👨‍👧‍👧',
        ['description'] = 'family: man, man, girl, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👩‍👦',
        ['description'] = 'family: woman, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👩‍👧',
        ['description'] = 'family: woman, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👩‍👧‍👦',
        ['description'] = 'family: woman, girl, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👩‍👦‍👦',
        ['description'] = 'family: woman, boy, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👩‍👧‍👧',
        ['description'] = 'family: woman, girl, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👨‍👦',
        ['description'] = 'family: man, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👨‍👧',
        ['description'] = 'family: man, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👨‍👧‍👦',
        ['description'] = 'family: man, girl, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👨‍👦‍👦',
        ['description'] = 'family: man, boy, boy',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '👨‍👧‍👧',
        ['description'] = 'family: man, girl, girl',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👚',
        ['description'] = 'woman’s clothes',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👕',
        ['description'] = 't-shirt',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👖',
        ['description'] = 'jeans',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👔',
        ['description'] = 'necktie',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👗',
        ['description'] = 'dress',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👙',
        ['description'] = 'bikini',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👘',
        ['description'] = 'kimono',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👠',
        ['description'] = 'high-heeled shoe',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👡',
        ['description'] = 'woman’s sandal',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👢',
        ['description'] = 'woman’s boot',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👞',
        ['description'] = 'man’s shoe',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👟',
        ['description'] = 'running shoe',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👒',
        ['description'] = 'woman’s hat',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎩',
        ['description'] = 'top hat',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎓',
        ['description'] = 'graduation cap',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👑',
        ['description'] = 'crown',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛑',
        ['description'] = 'rescue worker’s helmet',
        ['unicode_version'] = '5.2',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎒',
        ['description'] = 'school backpack',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👝',
        ['description'] = 'clutch bag',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👛',
        ['description'] = 'purse',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👜',
        ['description'] = 'handbag',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💼',
        ['description'] = 'briefcase',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '👓',
        ['description'] = 'glasses',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕶',
        ['description'] = 'sunglasses',
        ['unicode_version'] = '7.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌂',
        ['description'] = 'closed umbrella',
        ['unicode_version'] = '6.0',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☂️',
        ['description'] = 'umbrella',
        ['unicode_version'] = '',
        ['category'] = 'People'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐶',
        ['description'] = 'dog face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐱',
        ['description'] = 'cat face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐭',
        ['description'] = 'mouse face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐹',
        ['description'] = 'hamster face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐰',
        ['description'] = 'rabbit face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦊',
        ['description'] = 'fox face',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐻',
        ['description'] = 'bear face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐼',
        ['description'] = 'panda face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐨',
        ['description'] = 'koala',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐯',
        ['description'] = 'tiger face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🦁',
        ['description'] = 'lion face',
        ['unicode_version'] = '8.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐮',
        ['description'] = 'cow face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐷',
        ['description'] = 'pig face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐽',
        ['description'] = 'pig nose',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐸',
        ['description'] = 'frog face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐵',
        ['description'] = 'monkey face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙈',
        ['description'] = 'see-no-evil monkey',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙉',
        ['description'] = 'hear-no-evil monkey',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🙊',
        ['description'] = 'speak-no-evil monkey',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐒',
        ['description'] = 'monkey',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐔',
        ['description'] = 'chicken',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐧',
        ['description'] = 'penguin',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐦',
        ['description'] = 'bird',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐤',
        ['description'] = 'baby chick',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐣',
        ['description'] = 'hatching chick',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐥',
        ['description'] = 'front-facing baby chick',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦆',
        ['description'] = 'duck',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦅',
        ['description'] = 'eagle',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦉',
        ['description'] = 'owl',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦇',
        ['description'] = 'bat',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐺',
        ['description'] = 'wolf face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐗',
        ['description'] = 'boar',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐴',
        ['description'] = 'horse face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🦄',
        ['description'] = 'unicorn face',
        ['unicode_version'] = '8.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐝',
        ['description'] = 'honeybee',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐛',
        ['description'] = 'bug',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦋',
        ['description'] = 'butterfly',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐌',
        ['description'] = 'snail',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐚',
        ['description'] = 'spiral shell',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐞',
        ['description'] = 'lady beetle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐜',
        ['description'] = 'ant',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕷',
        ['description'] = 'spider',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕸',
        ['description'] = 'spider web',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐢',
        ['description'] = 'turtle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐍',
        ['description'] = 'snake',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦎',
        ['description'] = 'lizard',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🦂',
        ['description'] = 'scorpion',
        ['unicode_version'] = '8.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🦀',
        ['description'] = 'crab',
        ['unicode_version'] = '8.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦑',
        ['description'] = 'squid',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐙',
        ['description'] = 'octopus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦐',
        ['description'] = 'shrimp',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐠',
        ['description'] = 'tropical fish',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐟',
        ['description'] = 'fish',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐡',
        ['description'] = 'blowfish',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐬',
        ['description'] = 'dolphin',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦈',
        ['description'] = 'shark',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐳',
        ['description'] = 'spouting whale',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐋',
        ['description'] = 'whale',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐊',
        ['description'] = 'crocodile',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐆',
        ['description'] = 'leopard',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐅',
        ['description'] = 'tiger',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐃',
        ['description'] = 'water buffalo',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐂',
        ['description'] = 'ox',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐄',
        ['description'] = 'cow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦌',
        ['description'] = 'deer',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐪',
        ['description'] = 'camel',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐫',
        ['description'] = 'two-hump camel',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐘',
        ['description'] = 'elephant',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦏',
        ['description'] = 'rhinoceros',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🦍',
        ['description'] = 'gorilla',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐎',
        ['description'] = 'horse',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐖',
        ['description'] = 'pig',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐐',
        ['description'] = 'goat',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐏',
        ['description'] = 'ram',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐑',
        ['description'] = 'sheep',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐕',
        ['description'] = 'dog',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐩',
        ['description'] = 'poodle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐈',
        ['description'] = 'cat',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐓',
        ['description'] = 'rooster',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🦃',
        ['description'] = 'turkey',
        ['unicode_version'] = '8.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕊',
        ['description'] = 'dove',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐇',
        ['description'] = 'rabbit',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐁',
        ['description'] = 'mouse',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐀',
        ['description'] = 'rat',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🐿',
        ['description'] = 'chipmunk',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐾',
        ['description'] = 'paw prints',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐉',
        ['description'] = 'dragon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🐲',
        ['description'] = 'dragon face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌵',
        ['description'] = 'cactus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎄',
        ['description'] = 'Christmas tree',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌲',
        ['description'] = 'evergreen tree',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌳',
        ['description'] = 'deciduous tree',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌴',
        ['description'] = 'palm tree',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌱',
        ['description'] = 'seedling',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌿',
        ['description'] = 'herb',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☘️',
        ['description'] = 'shamrock',
        ['unicode_version'] = '4.1',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍀',
        ['description'] = 'four leaf clover',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎍',
        ['description'] = 'pine decoration',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎋',
        ['description'] = 'tanabata tree',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍃',
        ['description'] = 'leaf fluttering in wind',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍂',
        ['description'] = 'fallen leaf',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍁',
        ['description'] = 'maple leaf',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍄',
        ['description'] = 'mushroom',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌾',
        ['description'] = 'sheaf of rice',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💐',
        ['description'] = 'bouquet',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌷',
        ['description'] = 'tulip',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌹',
        ['description'] = 'rose',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥀',
        ['description'] = 'wilted flower',
        ['unicode_version'] = '9.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌻',
        ['description'] = 'sunflower',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌼',
        ['description'] = 'blossom',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌸',
        ['description'] = 'cherry blossom',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌺',
        ['description'] = 'hibiscus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌎',
        ['description'] = 'globe showing Americas',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌍',
        ['description'] = 'globe showing Europe-Africa',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌏',
        ['description'] = 'globe showing Asia-Australia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌕',
        ['description'] = 'full moon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌖',
        ['description'] = 'waning gibbous moon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌗',
        ['description'] = 'last quarter moon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌘',
        ['description'] = 'waning crescent moon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌑',
        ['description'] = 'new moon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌒',
        ['description'] = 'waxing crescent moon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌓',
        ['description'] = 'first quarter moon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌔',
        ['description'] = 'waxing gibbous moon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌚',
        ['description'] = 'new moon face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌝',
        ['description'] = 'full moon with face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌞',
        ['description'] = 'sun with face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌛',
        ['description'] = 'first quarter moon with face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌜',
        ['description'] = 'last quarter moon with face',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌙',
        ['description'] = 'crescent moon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💫',
        ['description'] = 'dizzy',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⭐️',
        ['description'] = 'white medium star',
        ['unicode_version'] = '5.1',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌟',
        ['description'] = 'glowing star',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✨',
        ['description'] = 'sparkles',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⚡️',
        ['description'] = 'high voltage',
        ['unicode_version'] = '4.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔥',
        ['description'] = 'fire',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💥',
        ['description'] = 'collision',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☄️',
        ['description'] = 'comet',
        ['unicode_version'] = '',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '☀️',
        ['description'] = 'sun',
        ['unicode_version'] = '',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌤',
        ['description'] = 'sun behind small cloud',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛅️',
        ['description'] = 'sun behind cloud',
        ['unicode_version'] = '5.2',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌥',
        ['description'] = 'sun behind large cloud',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌦',
        ['description'] = 'sun behind rain cloud',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌈',
        ['description'] = 'rainbow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '☁️',
        ['description'] = 'cloud',
        ['unicode_version'] = '',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌧',
        ['description'] = 'cloud with rain',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛈',
        ['description'] = 'cloud with lightning and rain',
        ['unicode_version'] = '5.2',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌩',
        ['description'] = 'cloud with lightning',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌨',
        ['description'] = 'cloud with snow',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☃️',
        ['description'] = 'snowman',
        ['unicode_version'] = '',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛄️',
        ['description'] = 'snowman without snow',
        ['unicode_version'] = '5.2',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '❄️',
        ['description'] = 'snowflake',
        ['unicode_version'] = '',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌬',
        ['description'] = 'wind face',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💨',
        ['description'] = 'dashing away',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌪',
        ['description'] = 'tornado',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌫',
        ['description'] = 'fog',
        ['unicode_version'] = '7.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌊',
        ['description'] = 'water wave',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💧',
        ['description'] = 'droplet',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💦',
        ['description'] = 'sweat droplets',
        ['unicode_version'] = '6.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '☔️',
        ['description'] = 'umbrella with rain drops',
        ['unicode_version'] = '4.0',
        ['category'] = 'Nature'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍏',
        ['description'] = 'green apple',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍎',
        ['description'] = 'red apple',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍐',
        ['description'] = 'pear',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍊',
        ['description'] = 'tangerine',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍋',
        ['description'] = 'lemon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍌',
        ['description'] = 'banana',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍉',
        ['description'] = 'watermelon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍇',
        ['description'] = 'grapes',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍓',
        ['description'] = 'strawberry',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍈',
        ['description'] = 'melon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍒',
        ['description'] = 'cherries',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍑',
        ['description'] = 'peach',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍍',
        ['description'] = 'pineapple',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥝',
        ['description'] = 'kiwi fruit',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥑',
        ['description'] = 'avocado',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍅',
        ['description'] = 'tomato',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍆',
        ['description'] = 'eggplant',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥒',
        ['description'] = 'cucumber',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥕',
        ['description'] = 'carrot',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌽',
        ['description'] = 'ear of corn',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌶',
        ['description'] = 'hot pepper',
        ['unicode_version'] = '7.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥔',
        ['description'] = 'potato',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍠',
        ['description'] = 'roasted sweet potato',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌰',
        ['description'] = 'chestnut',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥜',
        ['description'] = 'peanuts',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍯',
        ['description'] = 'honey pot',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥐',
        ['description'] = 'croissant',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍞',
        ['description'] = 'bread',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥖',
        ['description'] = 'baguette bread',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🧀',
        ['description'] = 'cheese wedge',
        ['unicode_version'] = '8.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥚',
        ['description'] = 'egg',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍳',
        ['description'] = 'cooking',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥓',
        ['description'] = 'bacon',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥞',
        ['description'] = 'pancakes',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍤',
        ['description'] = 'fried shrimp',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍗',
        ['description'] = 'poultry leg',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍖',
        ['description'] = 'meat on bone',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍕',
        ['description'] = 'pizza',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌭',
        ['description'] = 'hot dog',
        ['unicode_version'] = '8.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍔',
        ['description'] = 'hamburger',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍟',
        ['description'] = 'french fries',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥙',
        ['description'] = 'stuffed flatbread',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌮',
        ['description'] = 'taco',
        ['unicode_version'] = '8.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌯',
        ['description'] = 'burrito',
        ['unicode_version'] = '8.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥗',
        ['description'] = 'green salad',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥘',
        ['description'] = 'shallow pan of food',
        ['unicode_version'] = '',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍝',
        ['description'] = 'spaghetti',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍜',
        ['description'] = 'steaming bowl',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍲',
        ['description'] = 'pot of food',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍥',
        ['description'] = 'fish cake with swirl',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍣',
        ['description'] = 'sushi',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍱',
        ['description'] = 'bento box',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍛',
        ['description'] = 'curry rice',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍚',
        ['description'] = 'cooked rice',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍙',
        ['description'] = 'rice ball',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍘',
        ['description'] = 'rice cracker',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍢',
        ['description'] = 'oden',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍡',
        ['description'] = 'dango',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍧',
        ['description'] = 'shaved ice',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍨',
        ['description'] = 'ice cream',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍦',
        ['description'] = 'soft ice cream',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍰',
        ['description'] = 'shortcake',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎂',
        ['description'] = 'birthday cake',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍮',
        ['description'] = 'custard',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍭',
        ['description'] = 'lollipop',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍬',
        ['description'] = 'candy',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍫',
        ['description'] = 'chocolate bar',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🍿',
        ['description'] = 'popcorn',
        ['unicode_version'] = '8.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍩',
        ['description'] = 'doughnut',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍪',
        ['description'] = 'cookie',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥛',
        ['description'] = 'glass of milk',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍼',
        ['description'] = 'baby bottle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '☕️',
        ['description'] = 'hot beverage',
        ['unicode_version'] = '4.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍵',
        ['description'] = 'teacup without handle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍶',
        ['description'] = 'sake',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍺',
        ['description'] = 'beer mug',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍻',
        ['description'] = 'clinking beer mugs',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥂',
        ['description'] = 'clinking glasses',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍷',
        ['description'] = 'wine glass',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥃',
        ['description'] = 'tumbler glass',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍸',
        ['description'] = 'cocktail glass',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍹',
        ['description'] = 'tropical drink',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🍾',
        ['description'] = 'bottle with popping cork',
        ['unicode_version'] = '8.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥄',
        ['description'] = 'spoon',
        ['unicode_version'] = '9.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🍴',
        ['description'] = 'fork and knife',
        ['unicode_version'] = '6.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🍽',
        ['description'] = 'fork and knife with plate',
        ['unicode_version'] = '7.0',
        ['category'] = 'Foods'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⚽️',
        ['description'] = 'soccer ball',
        ['unicode_version'] = '5.2',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏀',
        ['description'] = 'basketball',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏈',
        ['description'] = 'american football',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⚾️',
        ['description'] = 'baseball',
        ['unicode_version'] = '5.2',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎾',
        ['description'] = 'tennis',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏐',
        ['description'] = 'volleyball',
        ['unicode_version'] = '8.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏉',
        ['description'] = 'rugby football',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎱',
        ['description'] = 'pool 8 ball',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏓',
        ['description'] = 'ping pong',
        ['unicode_version'] = '8.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏸',
        ['description'] = 'badminton',
        ['unicode_version'] = '8.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥅',
        ['description'] = 'goal net',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏒',
        ['description'] = 'ice hockey',
        ['unicode_version'] = '8.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏑',
        ['description'] = 'field hockey',
        ['unicode_version'] = '8.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏏',
        ['description'] = 'cricket',
        ['unicode_version'] = '8.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛳️',
        ['description'] = 'flag in hole',
        ['unicode_version'] = '5.2',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏹',
        ['description'] = 'bow and arrow',
        ['unicode_version'] = '8.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎣',
        ['description'] = 'fishing pole',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥊',
        ['description'] = 'boxing glove',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥋',
        ['description'] = 'martial arts uniform',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛸',
        ['description'] = 'ice skate',
        ['unicode_version'] = '5.2',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎿',
        ['description'] = 'skis',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛷',
        ['description'] = 'skier',
        ['unicode_version'] = '5.2',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏂',
        ['description'] = 'snowboarder',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🏋️‍♀️',
        ['description'] = 'woman lifting weights',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏋️',
        ['description'] = 'person lifting weights',
        ['unicode_version'] = '7.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤺',
        ['description'] = 'person fencing',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤼‍♀️',
        ['description'] = 'women wrestling',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤼‍♂️',
        ['description'] = 'men wrestling',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤸‍♀️',
        ['description'] = 'woman cartwheeling',
        ['unicode_version'] = '',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤸‍♂️',
        ['description'] = 'man cartwheeling',
        ['unicode_version'] = '',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '⛹️‍♀️',
        ['description'] = 'woman bouncing ball',
        ['unicode_version'] = '7.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛹️',
        ['description'] = 'person bouncing ball',
        ['unicode_version'] = '5.2',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤾‍♀️',
        ['description'] = 'woman playing handball',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤾‍♂️',
        ['description'] = 'man playing handball',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🏌️‍♀️',
        ['description'] = 'woman golfing',
        ['unicode_version'] = '',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏌️',
        ['description'] = 'person golfing',
        ['unicode_version'] = '7.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🏄‍♀️',
        ['description'] = 'woman surfing',
        ['unicode_version'] = '7.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏄',
        ['description'] = 'person surfing',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🏊‍♀️',
        ['description'] = 'woman swimming',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏊',
        ['description'] = 'person swimming',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤽‍♀️',
        ['description'] = 'woman playing water polo',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤽‍♂️',
        ['description'] = 'man playing water polo',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🚣‍♀️',
        ['description'] = 'woman rowing boat',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚣',
        ['description'] = 'person rowing boat',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏇',
        ['description'] = 'horse racing',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🚴‍♀️',
        ['description'] = 'woman biking',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚴',
        ['description'] = 'person biking',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🚵‍♀️',
        ['description'] = 'woman mountain biking',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚵',
        ['description'] = 'person mountain biking',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎽',
        ['description'] = 'running shirt',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏅',
        ['description'] = 'sports medal',
        ['unicode_version'] = '7.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🎖',
        ['description'] = 'military medal',
        ['unicode_version'] = '7.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥇',
        ['description'] = '1st place medal',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥈',
        ['description'] = '2nd place medal',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥉',
        ['description'] = '3rd place medal',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏆',
        ['description'] = 'trophy',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏵',
        ['description'] = 'rosette',
        ['unicode_version'] = '7.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🎗',
        ['description'] = 'reminder ribbon',
        ['unicode_version'] = '7.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎫',
        ['description'] = 'ticket',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🎟',
        ['description'] = 'admission tickets',
        ['unicode_version'] = '7.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎪',
        ['description'] = 'circus tent',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤹‍♀️',
        ['description'] = 'woman juggling',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🤹‍♂️',
        ['description'] = 'man juggling',
        ['unicode_version'] = '9.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎭',
        ['description'] = 'performing arts',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎨',
        ['description'] = 'artist palette',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎬',
        ['description'] = 'clapper board',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎤',
        ['description'] = 'microphone',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎧',
        ['description'] = 'headphone',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎼',
        ['description'] = 'musical score',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎹',
        ['description'] = 'musical keyboard',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🥁',
        ['description'] = 'drum',
        ['unicode_version'] = '',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎷',
        ['description'] = 'saxophone',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎺',
        ['description'] = 'trumpet',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎸',
        ['description'] = 'guitar',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎻',
        ['description'] = 'violin',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎲',
        ['description'] = 'game die',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎯',
        ['description'] = 'direct hit',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎳',
        ['description'] = 'bowling',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎮',
        ['description'] = 'video game',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎰',
        ['description'] = 'slot machine',
        ['unicode_version'] = '6.0',
        ['category'] = 'Activity'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚗',
        ['description'] = 'automobile',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚕',
        ['description'] = 'taxi',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚙',
        ['description'] = 'sport utility vehicle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚌',
        ['description'] = 'bus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚎',
        ['description'] = 'trolleybus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏎',
        ['description'] = 'racing car',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚓',
        ['description'] = 'police car',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚑',
        ['description'] = 'ambulance',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚒',
        ['description'] = 'fire engine',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚐',
        ['description'] = 'minibus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚚',
        ['description'] = 'delivery truck',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚛',
        ['description'] = 'articulated lorry',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚜',
        ['description'] = 'tractor',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🛴',
        ['description'] = 'kick scooter',
        ['unicode_version'] = '9.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚲',
        ['description'] = 'bicycle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🛵',
        ['description'] = 'motor scooter',
        ['unicode_version'] = '9.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏍',
        ['description'] = 'motorcycle',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚨',
        ['description'] = 'police car light',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚔',
        ['description'] = 'oncoming police car',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚍',
        ['description'] = 'oncoming bus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚘',
        ['description'] = 'oncoming automobile',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚖',
        ['description'] = 'oncoming taxi',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚡',
        ['description'] = 'aerial tramway',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚠',
        ['description'] = 'mountain cableway',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚟',
        ['description'] = 'suspension railway',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚃',
        ['description'] = 'railway car',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚋',
        ['description'] = 'tram car',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚞',
        ['description'] = 'mountain railway',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚝',
        ['description'] = 'monorail',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚄',
        ['description'] = 'high-speed train',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚅',
        ['description'] = 'high-speed train with bullet nose',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚈',
        ['description'] = 'light rail',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚂',
        ['description'] = 'locomotive',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚆',
        ['description'] = 'train',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚇',
        ['description'] = 'metro',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚊',
        ['description'] = 'tram',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚉',
        ['description'] = 'station',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚁',
        ['description'] = 'helicopter',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛩',
        ['description'] = 'small airplane',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✈️',
        ['description'] = 'airplane',
        ['unicode_version'] = '',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛫',
        ['description'] = 'airplane departure',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛬',
        ['description'] = 'airplane arrival',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚀',
        ['description'] = 'rocket',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛰',
        ['description'] = 'satellite',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💺',
        ['description'] = 'seat',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🛶',
        ['description'] = 'canoe',
        ['unicode_version'] = '9.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛵️',
        ['description'] = 'sailboat',
        ['unicode_version'] = '5.2',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛥',
        ['description'] = 'motor boat',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚤',
        ['description'] = 'speedboat',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛳',
        ['description'] = 'passenger ship',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛴',
        ['description'] = 'ferry',
        ['unicode_version'] = '5.2',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚢',
        ['description'] = 'ship',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⚓️',
        ['description'] = 'anchor',
        ['unicode_version'] = '4.1',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚧',
        ['description'] = 'construction',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛽️',
        ['description'] = 'fuel pump',
        ['unicode_version'] = '5.2',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚏',
        ['description'] = 'bus stop',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚦',
        ['description'] = 'vertical traffic light',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚥',
        ['description'] = 'horizontal traffic light',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗺',
        ['description'] = 'world map',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🗿',
        ['description'] = 'moai',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🗽',
        ['description'] = 'Statue of Liberty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛲️',
        ['description'] = 'fountain',
        ['unicode_version'] = '5.2',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🗼',
        ['description'] = 'Tokyo tower',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏰',
        ['description'] = 'castle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏯',
        ['description'] = 'Japanese castle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏟',
        ['description'] = 'stadium',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎡',
        ['description'] = 'ferris wheel',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎢',
        ['description'] = 'roller coaster',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎠',
        ['description'] = 'carousel horse',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛱',
        ['description'] = 'umbrella on ground',
        ['unicode_version'] = '5.2',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏖',
        ['description'] = 'beach with umbrella',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏝',
        ['description'] = 'desert island',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛰',
        ['description'] = 'mountain',
        ['unicode_version'] = '5.2',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏔',
        ['description'] = 'snow-capped mountain',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🗻',
        ['description'] = 'mount fuji',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌋',
        ['description'] = 'volcano',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏜',
        ['description'] = 'desert',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏕',
        ['description'] = 'camping',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛺️',
        ['description'] = 'tent',
        ['unicode_version'] = '5.2',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛤',
        ['description'] = 'railway track',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛣',
        ['description'] = 'motorway',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏗',
        ['description'] = 'building construction',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏭',
        ['description'] = 'factory',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏠',
        ['description'] = 'house',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏡',
        ['description'] = 'house with garden',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏘',
        ['description'] = 'house',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏚',
        ['description'] = 'derelict house',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏢',
        ['description'] = 'office building',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏬',
        ['description'] = 'department store',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏣',
        ['description'] = 'Japanese post office',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏤',
        ['description'] = 'post office',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏥',
        ['description'] = 'hospital',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏦',
        ['description'] = 'bank',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏨',
        ['description'] = 'hotel',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏪',
        ['description'] = 'convenience store',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏫',
        ['description'] = 'school',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏩',
        ['description'] = 'love hotel',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💒',
        ['description'] = 'wedding',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏛',
        ['description'] = 'classical building',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛪️',
        ['description'] = 'church',
        ['unicode_version'] = '5.2',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕌',
        ['description'] = 'mosque',
        ['unicode_version'] = '8.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕍',
        ['description'] = 'synagogue',
        ['unicode_version'] = '8.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕋',
        ['description'] = 'kaaba',
        ['unicode_version'] = '8.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛩',
        ['description'] = 'shinto shrine',
        ['unicode_version'] = '5.2',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🗾',
        ['description'] = 'map of Japan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎑',
        ['description'] = 'moon viewing ceremony',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏞',
        ['description'] = 'national park',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌅',
        ['description'] = 'sunrise',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌄',
        ['description'] = 'sunrise over mountains',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌠',
        ['description'] = 'shooting star',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎇',
        ['description'] = 'sparkler',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎆',
        ['description'] = 'fireworks',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌇',
        ['description'] = 'sunset',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌆',
        ['description'] = 'cityscape at dusk',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏙',
        ['description'] = 'cityscape',
        ['unicode_version'] = '7.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌃',
        ['description'] = 'night with stars',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌌',
        ['description'] = 'milky way',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌉',
        ['description'] = 'bridge at night',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌁',
        ['description'] = 'foggy',
        ['unicode_version'] = '6.0',
        ['category'] = 'Places'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⌚️',
        ['description'] = 'watch',
        ['unicode_version'] = '',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📱',
        ['description'] = 'mobile phone',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📲',
        ['description'] = 'mobile phone with arrow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💻',
        ['description'] = 'laptop computer',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⌨️',
        ['description'] = 'keyboard',
        ['unicode_version'] = '',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖥',
        ['description'] = 'desktop computer',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖨',
        ['description'] = 'printer',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖱',
        ['description'] = 'computer mouse',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖲',
        ['description'] = 'trackball',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕹',
        ['description'] = 'joystick',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗜',
        ['description'] = 'clamp',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💽',
        ['description'] = 'computer disk',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💾',
        ['description'] = 'floppy disk',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💿',
        ['description'] = 'optical disk',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📀',
        ['description'] = 'dvd',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📼',
        ['description'] = 'videocassette',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📷',
        ['description'] = 'camera',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '📸',
        ['description'] = 'camera with flash',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📹',
        ['description'] = 'video camera',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎥',
        ['description'] = 'movie camera',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '📽',
        ['description'] = 'film projector',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🎞',
        ['description'] = 'film frames',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📞',
        ['description'] = 'telephone receiver',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '☎️',
        ['description'] = 'telephone',
        ['unicode_version'] = '',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📟',
        ['description'] = 'pager',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📠',
        ['description'] = 'fax machine',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📺',
        ['description'] = 'television',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📻',
        ['description'] = 'radio',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🎙',
        ['description'] = 'studio microphone',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🎚',
        ['description'] = 'level slider',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🎛',
        ['description'] = 'control knobs',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⏱',
        ['description'] = 'stopwatch',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⏲',
        ['description'] = 'timer clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⏰',
        ['description'] = 'alarm clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕰',
        ['description'] = 'mantelpiece clock',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⌛️',
        ['description'] = 'hourglass',
        ['unicode_version'] = '',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⏳',
        ['description'] = 'hourglass with flowing sand',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📡',
        ['description'] = 'satellite antenna',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔋',
        ['description'] = 'battery',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔌',
        ['description'] = 'electric plug',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💡',
        ['description'] = 'light bulb',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔦',
        ['description'] = 'flashlight',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕯',
        ['description'] = 'candle',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗑',
        ['description'] = 'wastebasket',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛢',
        ['description'] = 'oil drum',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💸',
        ['description'] = 'money with wings',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💵',
        ['description'] = 'dollar banknote',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💴',
        ['description'] = 'yen banknote',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💶',
        ['description'] = 'euro banknote',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💷',
        ['description'] = 'pound banknote',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💰',
        ['description'] = 'money bag',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💳',
        ['description'] = 'credit card',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💎',
        ['description'] = 'gem stone',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⚖️',
        ['description'] = 'balance scale',
        ['unicode_version'] = '4.1',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔧',
        ['description'] = 'wrench',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔨',
        ['description'] = 'hammer',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⚒',
        ['description'] = 'hammer and pick',
        ['unicode_version'] = '4.1',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛠',
        ['description'] = 'hammer and wrench',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛏',
        ['description'] = 'pick',
        ['unicode_version'] = '5.2',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔩',
        ['description'] = 'nut and bolt',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⚙️',
        ['description'] = 'gear',
        ['unicode_version'] = '4.1',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⛓',
        ['description'] = 'chains',
        ['unicode_version'] = '5.2',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔫',
        ['description'] = 'pistol',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💣',
        ['description'] = 'bomb',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔪',
        ['description'] = 'kitchen knife',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗡',
        ['description'] = 'dagger',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⚔️',
        ['description'] = 'crossed swords',
        ['unicode_version'] = '4.1',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛡',
        ['description'] = 'shield',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚬',
        ['description'] = 'cigarette',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⚰️',
        ['description'] = 'coffin',
        ['unicode_version'] = '4.1',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⚱️',
        ['description'] = 'funeral urn',
        ['unicode_version'] = '4.1',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏺',
        ['description'] = 'amphora',
        ['unicode_version'] = '8.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔮',
        ['description'] = 'crystal ball',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '📿',
        ['description'] = 'prayer beads',
        ['unicode_version'] = '8.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💈',
        ['description'] = 'barber pole',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⚗️',
        ['description'] = 'alembic',
        ['unicode_version'] = '4.1',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔭',
        ['description'] = 'telescope',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔬',
        ['description'] = 'microscope',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕳',
        ['description'] = 'hole',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💊',
        ['description'] = 'pill',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💉',
        ['description'] = 'syringe',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🌡',
        ['description'] = 'thermometer',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚽',
        ['description'] = 'toilet',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚰',
        ['description'] = 'potable water',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚿',
        ['description'] = 'shower',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🛁',
        ['description'] = 'bathtub',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🛀',
        ['description'] = 'person taking bath',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛎',
        ['description'] = 'bellhop bell',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔑',
        ['description'] = 'key',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗝',
        ['description'] = 'old key',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚪',
        ['description'] = 'door',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛋',
        ['description'] = 'couch and lamp',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛏',
        ['description'] = 'bed',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛌',
        ['description'] = 'person in bed',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖼',
        ['description'] = 'framed picture',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛍',
        ['description'] = 'shopping bags',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🛒',
        ['description'] = 'shopping cart',
        ['unicode_version'] = '9.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎁',
        ['description'] = 'wrapped gift',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎈',
        ['description'] = 'balloon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎏',
        ['description'] = 'carp streamer',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎀',
        ['description'] = 'ribbon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎊',
        ['description'] = 'confetti ball',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎉',
        ['description'] = 'party popper',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎎',
        ['description'] = 'Japanese dolls',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏮',
        ['description'] = 'red paper lantern',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎐',
        ['description'] = 'wind chime',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✉️',
        ['description'] = 'envelope',
        ['unicode_version'] = '',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📩',
        ['description'] = 'envelope with arrow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📨',
        ['description'] = 'incoming envelope',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📧',
        ['description'] = 'e-mail',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💌',
        ['description'] = 'love letter',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📥',
        ['description'] = 'inbox tray',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📤',
        ['description'] = 'outbox tray',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📦',
        ['description'] = 'package',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏷',
        ['description'] = 'label',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📪',
        ['description'] = 'closed mailbox with lowered flag',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📫',
        ['description'] = 'closed mailbox with raised flag',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📬',
        ['description'] = 'open mailbox with raised flag',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📭',
        ['description'] = 'open mailbox with lowered flag',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📮',
        ['description'] = 'postbox',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📯',
        ['description'] = 'postal horn',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📜',
        ['description'] = 'scroll',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📃',
        ['description'] = 'page with curl',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📄',
        ['description'] = 'page facing up',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📑',
        ['description'] = 'bookmark tabs',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📊',
        ['description'] = 'bar chart',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📈',
        ['description'] = 'chart increasing',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📉',
        ['description'] = 'chart decreasing',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗒',
        ['description'] = 'spiral notepad',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗓',
        ['description'] = 'spiral calendar',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📆',
        ['description'] = 'tear-off calendar',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📅',
        ['description'] = 'calendar',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📇',
        ['description'] = 'card index',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗃',
        ['description'] = 'card file box',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗳',
        ['description'] = 'ballot box with ballot',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗄',
        ['description'] = 'file cabinet',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📋',
        ['description'] = 'clipboard',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📁',
        ['description'] = 'file folder',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📂',
        ['description'] = 'open file folder',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗂',
        ['description'] = 'card index dividers',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗞',
        ['description'] = 'rolled-up newspaper',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📰',
        ['description'] = 'newspaper',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📓',
        ['description'] = 'notebook',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📔',
        ['description'] = 'notebook with decorative cover',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📒',
        ['description'] = 'ledger',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📕',
        ['description'] = 'closed book',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📗',
        ['description'] = 'green book',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📘',
        ['description'] = 'blue book',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📙',
        ['description'] = 'orange book',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📚',
        ['description'] = 'books',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📖',
        ['description'] = 'open book',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔖',
        ['description'] = 'bookmark',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔗',
        ['description'] = 'link',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📎',
        ['description'] = 'paperclip',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖇',
        ['description'] = 'linked paperclips',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📐',
        ['description'] = 'triangular ruler',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📏',
        ['description'] = 'straight ruler',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📌',
        ['description'] = 'pushpin',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📍',
        ['description'] = 'round pushpin',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✂️',
        ['description'] = 'scissors',
        ['unicode_version'] = '',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖊',
        ['description'] = 'pen',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖋',
        ['description'] = 'fountain pen',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✒️',
        ['description'] = 'black nib',
        ['unicode_version'] = '',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖌',
        ['description'] = 'paintbrush',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🖍',
        ['description'] = 'crayon',
        ['unicode_version'] = '7.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📝',
        ['description'] = 'memo',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✏️',
        ['description'] = 'pencil',
        ['unicode_version'] = '',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔍',
        ['description'] = 'left-pointing magnifying glass',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔎',
        ['description'] = 'right-pointing magnifying glass',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔏',
        ['description'] = 'locked with pen',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔐',
        ['description'] = 'locked with key',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔒',
        ['description'] = 'locked',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔓',
        ['description'] = 'unlocked',
        ['unicode_version'] = '6.0',
        ['category'] = 'Objects'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '❤️',
        ['description'] = 'red heart',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💛',
        ['description'] = 'yellow heart',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💚',
        ['description'] = 'green heart',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💙',
        ['description'] = 'blue heart',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💜',
        ['description'] = 'purple heart',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🖤',
        ['description'] = 'black heart',
        ['unicode_version'] = '9.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💔',
        ['description'] = 'broken heart',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '❣️',
        ['description'] = 'heavy heart exclamation',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💕',
        ['description'] = 'two hearts',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💞',
        ['description'] = 'revolving hearts',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💓',
        ['description'] = 'beating heart',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💗',
        ['description'] = 'growing heart',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💖',
        ['description'] = 'sparkling heart',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💘',
        ['description'] = 'heart with arrow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💝',
        ['description'] = 'heart with ribbon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💟',
        ['description'] = 'heart decoration',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☮️',
        ['description'] = 'peace symbol',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '✝️',
        ['description'] = 'latin cross',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☪️',
        ['description'] = 'star and crescent',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕉',
        ['description'] = 'om',
        ['unicode_version'] = '7.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☸️',
        ['description'] = 'wheel of dharma',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '✡️',
        ['description'] = 'star of David',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔯',
        ['description'] = 'dotted six-pointed star',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🕎',
        ['description'] = 'menorah',
        ['unicode_version'] = '8.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☯️',
        ['description'] = 'yin yang',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☦️',
        ['description'] = 'orthodox cross',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🛐',
        ['description'] = 'place of worship',
        ['unicode_version'] = '8.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛎',
        ['description'] = 'Ophiuchus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♈️',
        ['description'] = 'Aries',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♉️',
        ['description'] = 'Taurus',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♊️',
        ['description'] = 'Gemini',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♋️',
        ['description'] = 'Cancer',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♌️',
        ['description'] = 'Leo',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♍️',
        ['description'] = 'Virgo',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♎️',
        ['description'] = 'Libra',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♏️',
        ['description'] = 'Scorpius',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♐️',
        ['description'] = 'Sagittarius',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♑️',
        ['description'] = 'Capricorn',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♒️',
        ['description'] = 'Aquarius',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♓️',
        ['description'] = 'Pisces',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆔',
        ['description'] = 'ID button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⚛️',
        ['description'] = 'atom symbol',
        ['unicode_version'] = '4.1',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🉑',
        ['description'] = 'Japanese “acceptable” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☢️',
        ['description'] = 'radioactive',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '☣️',
        ['description'] = 'biohazard',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📴',
        ['description'] = 'mobile phone off',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📳',
        ['description'] = 'vibration mode',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈶',
        ['description'] = 'Japanese “not free of charge” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈚️',
        ['description'] = 'Japanese “free of charge” button',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈸',
        ['description'] = 'Japanese “application” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈺',
        ['description'] = 'Japanese “open for business” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈷️',
        ['description'] = 'Japanese “monthly amount” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✴️',
        ['description'] = 'eight-pointed star',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆚',
        ['description'] = 'VS button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💮',
        ['description'] = 'white flower',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🉐',
        ['description'] = 'Japanese “bargain” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '㊙️',
        ['description'] = 'Japanese “secret” button',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '㊗️',
        ['description'] = 'Japanese “congratulations” button',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈴',
        ['description'] = 'Japanese “passing grade” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈵',
        ['description'] = 'Japanese “no vacancy” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈹',
        ['description'] = 'Japanese “discount” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈲',
        ['description'] = 'Japanese “prohibited” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🅰️',
        ['description'] = 'A button (blood type)',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🅱️',
        ['description'] = 'B button (blood type)',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆎',
        ['description'] = 'AB button (blood type)',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆑',
        ['description'] = 'CL button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🅾️',
        ['description'] = 'O button (blood type)',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆘',
        ['description'] = 'SOS button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '❌',
        ['description'] = 'cross mark',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⭕️',
        ['description'] = 'heavy large circle',
        ['unicode_version'] = '5.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '10.2',
        ['emoji'] = '🛑',
        ['description'] = 'stop sign',
        ['unicode_version'] = '9.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⛔️',
        ['description'] = 'no entry',
        ['unicode_version'] = '5.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📛',
        ['description'] = 'name badge',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚫',
        ['description'] = 'prohibited',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💯',
        ['description'] = 'hundred points',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💢',
        ['description'] = 'anger symbol',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♨️',
        ['description'] = 'hot springs',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚷',
        ['description'] = 'no pedestrians',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚯',
        ['description'] = 'no littering',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚳',
        ['description'] = 'no bicycles',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚱',
        ['description'] = 'non-potable water',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔞',
        ['description'] = 'no one under eighteen',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📵',
        ['description'] = 'no mobile phones',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚭',
        ['description'] = 'no smoking',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '❗️',
        ['description'] = 'exclamation mark',
        ['unicode_version'] = '5.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '❕',
        ['description'] = 'white exclamation mark',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '❓',
        ['description'] = 'question mark',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '❔',
        ['description'] = 'white question mark',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '‼️',
        ['description'] = 'double exclamation mark',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⁉️',
        ['description'] = 'exclamation question mark',
        ['unicode_version'] = '3.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔅',
        ['description'] = 'dim button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔆',
        ['description'] = 'bright button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '〽️',
        ['description'] = 'part alternation mark',
        ['unicode_version'] = '3.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⚠️',
        ['description'] = 'warning',
        ['unicode_version'] = '4.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚸',
        ['description'] = 'children crossing',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔱',
        ['description'] = 'trident emblem',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⚜️',
        ['description'] = 'fleur-de-lis',
        ['unicode_version'] = '4.1',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔰',
        ['description'] = 'Japanese symbol for beginner',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♻️',
        ['description'] = 'recycling symbol',
        ['unicode_version'] = '3.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✅',
        ['description'] = 'white heavy check mark',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈯️',
        ['description'] = 'Japanese “reserved” button',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💹',
        ['description'] = 'chart increasing with yen',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '❇️',
        ['description'] = 'sparkle',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✳️',
        ['description'] = 'eight-spoked asterisk',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '❎',
        ['description'] = 'cross mark button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌐',
        ['description'] = 'globe with meridians',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💠',
        ['description'] = 'diamond with a dot',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = 'Ⓜ️',
        ['description'] = 'circled M',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🌀',
        ['description'] = 'cyclone',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💤',
        ['description'] = 'zzz',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏧',
        ['description'] = 'ATM sign',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚾',
        ['description'] = 'water closet',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♿️',
        ['description'] = 'wheelchair symbol',
        ['unicode_version'] = '4.1',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🅿️',
        ['description'] = 'P button',
        ['unicode_version'] = '5.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈳',
        ['description'] = 'Japanese “vacancy” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈂️',
        ['description'] = 'Japanese “service charge” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🛂',
        ['description'] = 'passport control',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🛃',
        ['description'] = 'customs',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🛄',
        ['description'] = 'baggage claim',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🛅',
        ['description'] = 'left luggage',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚹',
        ['description'] = 'men’s room',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚺',
        ['description'] = 'women’s room',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚼',
        ['description'] = 'baby symbol',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚻',
        ['description'] = 'restroom',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚮',
        ['description'] = 'litter in bin sign',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎦',
        ['description'] = 'cinema',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📶',
        ['description'] = 'antenna bars',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🈁',
        ['description'] = 'Japanese “here” button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔣',
        ['description'] = 'input symbols',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = 'ℹ️',
        ['description'] = 'information',
        ['unicode_version'] = '3.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔤',
        ['description'] = 'input latin letters',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔡',
        ['description'] = 'input latin lowercase',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔠',
        ['description'] = 'input latin uppercase',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆖',
        ['description'] = 'NG button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆗',
        ['description'] = 'OK button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆙',
        ['description'] = 'UP! button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆒',
        ['description'] = 'COOL button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆕',
        ['description'] = 'NEW button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🆓',
        ['description'] = 'FREE button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '0️⃣',
        ['description'] = 'keycap: 0',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '1️⃣',
        ['description'] = 'keycap: 1',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '2️⃣',
        ['description'] = 'keycap: 2',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '3️⃣',
        ['description'] = 'keycap: 3',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '4️⃣',
        ['description'] = 'keycap: 4',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '5️⃣',
        ['description'] = 'keycap: 5',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '6️⃣',
        ['description'] = 'keycap: 6',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '7️⃣',
        ['description'] = 'keycap: 7',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '8️⃣',
        ['description'] = 'keycap: 8',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '9️⃣',
        ['description'] = 'keycap: 9',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔟',
        ['description'] = 'keycap 10',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔢',
        ['description'] = 'input numbers',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '#️⃣',
        ['description'] = 'keycap: #',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '*️⃣',
        ['description'] = 'keycap: *',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = 'Next →️',
        ['description'] = 'play button',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⏸',
        ['description'] = 'pause button',
        ['unicode_version'] = '7.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⏯',
        ['description'] = 'play or pause button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⏹',
        ['description'] = 'stop button',
        ['unicode_version'] = '7.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⏺',
        ['description'] = 'record button',
        ['unicode_version'] = '7.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⏭',
        ['description'] = 'next track button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '⏮',
        ['description'] = 'last track button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⏩',
        ['description'] = 'fast-forward button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⏪',
        ['description'] = 'fast reverse button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⏫',
        ['description'] = 'fast up button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⏬',
        ['description'] = 'fast down button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '← Previous',
        ['description'] = 'reverse button',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔼',
        ['description'] = 'up button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔽',
        ['description'] = 'down button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '➡️',
        ['description'] = 'right arrow',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⬅️',
        ['description'] = 'left arrow',
        ['unicode_version'] = '4.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⬆️',
        ['description'] = 'up arrow',
        ['unicode_version'] = '4.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⬇️',
        ['description'] = 'down arrow',
        ['unicode_version'] = '4.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '↗️',
        ['description'] = 'up-right arrow',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '↘️',
        ['description'] = 'down-right arrow',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '↙️',
        ['description'] = 'down-left arrow',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '↖️',
        ['description'] = 'up-left arrow',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '↕️',
        ['description'] = 'up-down arrow',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '↔️',
        ['description'] = 'left-right arrow',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '↪️',
        ['description'] = 'left arrow curving right',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '↩️',
        ['description'] = 'right arrow curving left',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⤴️',
        ['description'] = 'right arrow curving up',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⤵️',
        ['description'] = 'right arrow curving down',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔀',
        ['description'] = 'shuffle tracks button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔁',
        ['description'] = 'repeat button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔂',
        ['description'] = 'repeat single button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔄',
        ['description'] = 'anticlockwise arrows button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔃',
        ['description'] = 'clockwise vertical arrows',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎵',
        ['description'] = 'musical note',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎶',
        ['description'] = 'musical notes',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '➕',
        ['description'] = 'heavy plus sign',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '➖',
        ['description'] = 'heavy minus sign',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '➗',
        ['description'] = 'heavy division sign',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✖️',
        ['description'] = 'heavy multiplication x',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💲',
        ['description'] = 'heavy dollar sign',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💱',
        ['description'] = 'currency exchange',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '™️',
        ['description'] = 'trade mark',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '©️',
        ['description'] = 'copyright',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '®️',
        ['description'] = 'registered',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '〰️',
        ['description'] = 'wavy dash',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '➰',
        ['description'] = 'curly loop',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '➿',
        ['description'] = 'double curly loop',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔚',
        ['description'] = 'END arrow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔙',
        ['description'] = 'BACK arrow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔛',
        ['description'] = 'ON! arrow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔝',
        ['description'] = 'TOP arrow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔜',
        ['description'] = 'SOON arrow',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '✔️',
        ['description'] = 'heavy check mark',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '☑️',
        ['description'] = 'ballot box with check',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔘',
        ['description'] = 'radio button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⚪️',
        ['description'] = 'white circle',
        ['unicode_version'] = '4.1',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⚫️',
        ['description'] = 'black circle',
        ['unicode_version'] = '4.1',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔴',
        ['description'] = 'red circle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔵',
        ['description'] = 'blue circle',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔺',
        ['description'] = 'red triangle pointed up',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔻',
        ['description'] = 'red triangle pointed down',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔸',
        ['description'] = 'small orange diamond',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔹',
        ['description'] = 'small blue diamond',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔶',
        ['description'] = 'large orange diamond',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔷',
        ['description'] = 'large blue diamond',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔳',
        ['description'] = 'white square button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔲',
        ['description'] = 'black square button',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '▪️',
        ['description'] = 'black small square',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '▫️',
        ['description'] = 'white small square',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '◾️',
        ['description'] = 'black medium-small square',
        ['unicode_version'] = '3.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '◽️',
        ['description'] = 'white medium-small square',
        ['unicode_version'] = '3.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '◼️',
        ['description'] = 'black medium square',
        ['unicode_version'] = '3.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '◻️',
        ['description'] = 'white medium square',
        ['unicode_version'] = '3.2',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⬛️',
        ['description'] = 'black large square',
        ['unicode_version'] = '5.1',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '⬜️',
        ['description'] = 'white large square',
        ['unicode_version'] = '5.1',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔈',
        ['description'] = 'speaker low volume',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔇',
        ['description'] = 'muted speaker',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔉',
        ['description'] = 'speaker medium volume',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔊',
        ['description'] = 'speaker high volume',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔔',
        ['description'] = 'bell',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🔕',
        ['description'] = 'bell with slash',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📣',
        ['description'] = 'megaphone',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '📢',
        ['description'] = 'loudspeaker',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '👁‍🗨',
        ['description'] = 'eye in speech bubble',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💬',
        ['description'] = 'speech balloon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '💭',
        ['description'] = 'thought balloon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🗯',
        ['description'] = 'right anger bubble',
        ['unicode_version'] = '7.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♠️',
        ['description'] = 'spade suit',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♣️',
        ['description'] = 'club suit',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♥️',
        ['description'] = 'heart suit',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '♦️',
        ['description'] = 'diamond suit',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🃏',
        ['description'] = 'joker',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎴',
        ['description'] = 'flower playing cards',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🀄️',
        ['description'] = 'mahjong red dragon',
        ['unicode_version'] = '',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕐',
        ['description'] = 'one o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕑',
        ['description'] = 'two o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕒',
        ['description'] = 'three o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕓',
        ['description'] = 'four o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕔',
        ['description'] = 'five o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕕',
        ['description'] = 'six o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕖',
        ['description'] = 'seven o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕗',
        ['description'] = 'eight o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕘',
        ['description'] = 'nine o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕙',
        ['description'] = 'ten o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕚',
        ['description'] = 'eleven o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕛',
        ['description'] = 'twelve o’clock',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕜',
        ['description'] = 'one-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕝',
        ['description'] = 'two-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕞',
        ['description'] = 'three-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕟',
        ['description'] = 'four-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕠',
        ['description'] = 'five-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕡',
        ['description'] = 'six-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕢',
        ['description'] = 'seven-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕣',
        ['description'] = 'eight-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕤',
        ['description'] = 'nine-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕥',
        ['description'] = 'ten-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕦',
        ['description'] = 'eleven-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🕧',
        ['description'] = 'twelve-thirty',
        ['unicode_version'] = '6.0',
        ['category'] = 'Symbols'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏳️',
        ['description'] = 'white flag',
        ['unicode_version'] = '7.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🏴',
        ['description'] = 'black flag',
        ['unicode_version'] = '7.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🏁',
        ['description'] = 'chequered flag',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🚩',
        ['description'] = 'triangular flag',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '10.0',
        ['emoji'] = '🏳️‍🌈',
        ['description'] = 'rainbow flag',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇫',
        ['description'] = 'Afghanistan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇦🇽',
        ['description'] = 'Åland Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇱',
        ['description'] = 'Albania',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇩🇿',
        ['description'] = 'Algeria',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇸',
        ['description'] = 'American Samoa',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇩',
        ['description'] = 'Andorra',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇴',
        ['description'] = 'Angola',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇮',
        ['description'] = 'Anguilla',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇦🇶',
        ['description'] = 'Antarctica',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇬',
        ['description'] = 'Antigua & Barbuda',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇷',
        ['description'] = 'Argentina',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇲',
        ['description'] = 'Armenia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇼',
        ['description'] = 'Aruba',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇺',
        ['description'] = 'Australia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇹',
        ['description'] = 'Austria',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇿',
        ['description'] = 'Azerbaijan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇸',
        ['description'] = 'Bahamas',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇭',
        ['description'] = 'Bahrain',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇩',
        ['description'] = 'Bangladesh',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇧',
        ['description'] = 'Barbados',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇾',
        ['description'] = 'Belarus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇪',
        ['description'] = 'Belgium',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇿',
        ['description'] = 'Belize',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇯',
        ['description'] = 'Benin',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇲',
        ['description'] = 'Bermuda',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇹',
        ['description'] = 'Bhutan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇴',
        ['description'] = 'Bolivia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇧🇶',
        ['description'] = 'Caribbean Netherlands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇦',
        ['description'] = 'Bosnia & Herzegovina',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇼',
        ['description'] = 'Botswana',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇷',
        ['description'] = 'Brazil',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇮🇴',
        ['description'] = 'British Indian Ocean Territory',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇻🇬',
        ['description'] = 'British Virgin Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇳',
        ['description'] = 'Brunei',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇬',
        ['description'] = 'Bulgaria',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇫',
        ['description'] = 'Burkina Faso',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇧🇮',
        ['description'] = 'Burundi',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇻',
        ['description'] = 'Cape Verde',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇭',
        ['description'] = 'Cambodia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇲',
        ['description'] = 'Cameroon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇦',
        ['description'] = 'Canada',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇮🇨',
        ['description'] = 'Canary Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇾',
        ['description'] = 'Cayman Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇫',
        ['description'] = 'Central African Republic',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇹🇩',
        ['description'] = 'Chad',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇱',
        ['description'] = 'Chile',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇨🇳',
        ['description'] = 'China',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇨🇽',
        ['description'] = 'Christmas Island',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇨🇨',
        ['description'] = 'Cocos (Keeling) Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇴',
        ['description'] = 'Colombia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇲',
        ['description'] = 'Comoros',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇬',
        ['description'] = 'Congo - Brazzaville',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇩',
        ['description'] = 'Congo - Kinshasa',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇰',
        ['description'] = 'Cook Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇷',
        ['description'] = 'Costa Rica',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇮',
        ['description'] = 'Côte d’Ivoire',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇭🇷',
        ['description'] = 'Croatia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇺',
        ['description'] = 'Cuba',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇼',
        ['description'] = 'Curaçao',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇾',
        ['description'] = 'Cyprus',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇿',
        ['description'] = 'Czech Republic',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇩🇰',
        ['description'] = 'Denmark',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇩🇯',
        ['description'] = 'Djibouti',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇩🇲',
        ['description'] = 'Dominica',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇩🇴',
        ['description'] = 'Dominican Republic',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇪🇨',
        ['description'] = 'Ecuador',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇪🇬',
        ['description'] = 'Egypt',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇻',
        ['description'] = 'El Salvador',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇶',
        ['description'] = 'Equatorial Guinea',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇪🇷',
        ['description'] = 'Eritrea',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇪🇪',
        ['description'] = 'Estonia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇪🇹',
        ['description'] = 'Ethiopia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇪🇺',
        ['description'] = 'European Union',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇫🇰',
        ['description'] = 'Falkland Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇫🇴',
        ['description'] = 'Faroe Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇫🇯',
        ['description'] = 'Fiji',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇫🇮',
        ['description'] = 'Finland',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇫🇷',
        ['description'] = 'France',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇫',
        ['description'] = 'French Guiana',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇵🇫',
        ['description'] = 'French Polynesia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇫',
        ['description'] = 'French Southern Territories',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇦',
        ['description'] = 'Gabon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇲',
        ['description'] = 'Gambia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇪',
        ['description'] = 'Georgia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇩🇪',
        ['description'] = 'Germany',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇭',
        ['description'] = 'Ghana',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇮',
        ['description'] = 'Gibraltar',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇷',
        ['description'] = 'Greece',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇬🇱',
        ['description'] = 'Greenland',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇩',
        ['description'] = 'Grenada',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇬🇵',
        ['description'] = 'Guadeloupe',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇺',
        ['description'] = 'Guam',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇹',
        ['description'] = 'Guatemala',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇬🇬',
        ['description'] = 'Guernsey',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇳',
        ['description'] = 'Guinea',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇼',
        ['description'] = 'Guinea-Bissau',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇬🇾',
        ['description'] = 'Guyana',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇭🇹',
        ['description'] = 'Haiti',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇭🇳',
        ['description'] = 'Honduras',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇭🇰',
        ['description'] = 'Hong Kong SAR China',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇭🇺',
        ['description'] = 'Hungary',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇮🇸',
        ['description'] = 'Iceland',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇮🇳',
        ['description'] = 'India',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇮🇩',
        ['description'] = 'Indonesia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇮🇷',
        ['description'] = 'Iran',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇮🇶',
        ['description'] = 'Iraq',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇮🇪',
        ['description'] = 'Ireland',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇮🇲',
        ['description'] = 'Isle of Man',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇮🇱',
        ['description'] = 'Israel',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇮🇹',
        ['description'] = 'Italy',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇯🇲',
        ['description'] = 'Jamaica',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇯🇵',
        ['description'] = 'Japan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🎌',
        ['description'] = 'crossed flags',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇯🇪',
        ['description'] = 'Jersey',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇯🇴',
        ['description'] = 'Jordan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇿',
        ['description'] = 'Kazakhstan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇪',
        ['description'] = 'Kenya',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇮',
        ['description'] = 'Kiribati',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇽🇰',
        ['description'] = 'Kosovo',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇼',
        ['description'] = 'Kuwait',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇬',
        ['description'] = 'Kyrgyzstan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇦',
        ['description'] = 'Laos',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇻',
        ['description'] = 'Latvia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇧',
        ['description'] = 'Lebanon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇸',
        ['description'] = 'Lesotho',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇷',
        ['description'] = 'Liberia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇾',
        ['description'] = 'Libya',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇮',
        ['description'] = 'Liechtenstein',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇹',
        ['description'] = 'Lithuania',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇺',
        ['description'] = 'Luxembourg',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇴',
        ['description'] = 'Macau SAR China',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇰',
        ['description'] = 'Macedonia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇬',
        ['description'] = 'Madagascar',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇼',
        ['description'] = 'Malawi',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇾',
        ['description'] = 'Malaysia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇻',
        ['description'] = 'Maldives',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇱',
        ['description'] = 'Mali',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇹',
        ['description'] = 'Malta',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇲🇭',
        ['description'] = 'Marshall Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇲🇶',
        ['description'] = 'Martinique',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇷',
        ['description'] = 'Mauritania',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇲🇺',
        ['description'] = 'Mauritius',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇾🇹',
        ['description'] = 'Mayotte',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇽',
        ['description'] = 'Mexico',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇫🇲',
        ['description'] = 'Micronesia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇩',
        ['description'] = 'Moldova',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇲🇨',
        ['description'] = 'Monaco',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇳',
        ['description'] = 'Mongolia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇪',
        ['description'] = 'Montenegro',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇸',
        ['description'] = 'Montserrat',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇦',
        ['description'] = 'Morocco',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇿',
        ['description'] = 'Mozambique',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇲',
        ['description'] = 'Myanmar (Burma)',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇦',
        ['description'] = 'Namibia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇳🇷',
        ['description'] = 'Nauru',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇵',
        ['description'] = 'Nepal',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇱',
        ['description'] = 'Netherlands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇨',
        ['description'] = 'New Caledonia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇿',
        ['description'] = 'New Zealand',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇮',
        ['description'] = 'Nicaragua',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇪',
        ['description'] = 'Niger',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇬',
        ['description'] = 'Nigeria',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇺',
        ['description'] = 'Niue',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇳🇫',
        ['description'] = 'Norfolk Island',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇲🇵',
        ['description'] = 'Northern Mariana Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇵',
        ['description'] = 'North Korea',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇳🇴',
        ['description'] = 'Norway',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇴🇲',
        ['description'] = 'Oman',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇰',
        ['description'] = 'Pakistan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇼',
        ['description'] = 'Palau',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇸',
        ['description'] = 'Palestinian Territories',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇦',
        ['description'] = 'Panama',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇬',
        ['description'] = 'Papua New Guinea',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇾',
        ['description'] = 'Paraguay',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇪',
        ['description'] = 'Peru',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇭',
        ['description'] = 'Philippines',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇵🇳',
        ['description'] = 'Pitcairn Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇱',
        ['description'] = 'Poland',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇹',
        ['description'] = 'Portugal',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇵🇷',
        ['description'] = 'Puerto Rico',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇶🇦',
        ['description'] = 'Qatar',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇷🇪',
        ['description'] = 'Réunion',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇷🇴',
        ['description'] = 'Romania',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇷🇺',
        ['description'] = 'Russia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇷🇼',
        ['description'] = 'Rwanda',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇧🇱',
        ['description'] = 'St. Barthélemy',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇸🇭',
        ['description'] = 'St. Helena',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇰🇳',
        ['description'] = 'St. Kitts & Nevis',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇨',
        ['description'] = 'St. Lucia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇵🇲',
        ['description'] = 'St. Pierre & Miquelon',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇻🇨',
        ['description'] = 'St. Vincent & Grenadines',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇼🇸',
        ['description'] = 'Samoa',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇲',
        ['description'] = 'San Marino',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇹',
        ['description'] = 'São Tomé & Príncipe',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇦',
        ['description'] = 'Saudi Arabia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇳',
        ['description'] = 'Senegal',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇷🇸',
        ['description'] = 'Serbia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇨',
        ['description'] = 'Seychelles',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇱',
        ['description'] = 'Sierra Leone',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇬',
        ['description'] = 'Singapore',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇽',
        ['description'] = 'Sint Maarten',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇰',
        ['description'] = 'Slovakia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇮',
        ['description'] = 'Slovenia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇧',
        ['description'] = 'Solomon Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇴',
        ['description'] = 'Somalia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇿🇦',
        ['description'] = 'South Africa',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇬🇸',
        ['description'] = 'South Georgia & South Sandwich Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇰🇷',
        ['description'] = 'South Korea',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇸',
        ['description'] = 'South Sudan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇪🇸',
        ['description'] = 'Spain',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇱🇰',
        ['description'] = 'Sri Lanka',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇩',
        ['description'] = 'Sudan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇷',
        ['description'] = 'Suriname',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇿',
        ['description'] = 'Swaziland',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇪',
        ['description'] = 'Sweden',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇨🇭',
        ['description'] = 'Switzerland',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇸🇾',
        ['description'] = 'Syria',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇹🇼',
        ['description'] = 'Taiwan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇯',
        ['description'] = 'Tajikistan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇿',
        ['description'] = 'Tanzania',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇭',
        ['description'] = 'Thailand',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇱',
        ['description'] = 'Timor-Leste',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇬',
        ['description'] = 'Togo',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇹🇰',
        ['description'] = 'Tokelau',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇴',
        ['description'] = 'Tonga',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇹',
        ['description'] = 'Trinidad & Tobago',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇳',
        ['description'] = 'Tunisia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.1',
        ['emoji'] = '🇹🇷',
        ['description'] = 'Turkey',
        ['unicode_version'] = '8.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇲',
        ['description'] = 'Turkmenistan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇨',
        ['description'] = 'Turks & Caicos Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇹🇻',
        ['description'] = 'Tuvalu',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇺🇬',
        ['description'] = 'Uganda',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇺🇦',
        ['description'] = 'Ukraine',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇦🇪',
        ['description'] = 'United Arab Emirates',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇬🇧',
        ['description'] = 'United Kingdom',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '6.0',
        ['emoji'] = '🇺🇸',
        ['description'] = 'United States',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇻🇮',
        ['description'] = 'U.S. Virgin Islands',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇺🇾',
        ['description'] = 'Uruguay',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇺🇿',
        ['description'] = 'Uzbekistan',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇻🇺',
        ['description'] = 'Vanuatu',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇻🇦',
        ['description'] = 'Vatican City',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇻🇪',
        ['description'] = 'Venezuela',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇻🇳',
        ['description'] = 'Vietnam',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇼🇫',
        ['description'] = 'Wallis & Futuna',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '9.0',
        ['emoji'] = '🇪🇭',
        ['description'] = 'Western Sahara',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇾🇪',
        ['description'] = 'Yemen',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇿🇲',
        ['description'] = 'Zambia',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    },
    {
        ['ios_version'] = '8.3',
        ['emoji'] = '🇿🇼',
        ['description'] = 'Zimbabwe',
        ['unicode_version'] = '6.0',
        ['category'] = 'Flags'
    }
}

function emoji:on_message(message, configuration)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(
            message, emoji.help
        )
    end
    for i = 1, #emoji_list do
        if utf8.byte(input) == utf8.byte(emoji_list[i].emoji) then
            local output = {}
            table.insert(
                output,
                'Emoji: ' .. emoji_list[i].emoji
            )
            table.insert(
                output,
                'Description: ' .. emoji_list[i].description
            )
            table.insert(
                output,
                'Unicode version: ' .. emoji_list[i].unicode_version
            )
            table.insert(
                output,
                'iOS version: ' .. emoji_list[i].ios_version
            )
            table.insert(
                output,
                'Category: ' .. emoji_list[i].category
            )
            return mattata.send_message(
                message.chat.id,
                table.concat(
                    output,
                    '\n'
                )
            )
        end
    end
    return mattata.send_reply(
        message,
        'No results found.'
    )
end

return emoji