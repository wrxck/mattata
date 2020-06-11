--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local meme = {}
local mattata = require('mattata')

function meme:init()
    meme.commands = mattata.commands(self.info.username)
    :command('meme')
    :command('memegen').table
    meme.help = '/meme <top line> | <bottom line> - Generates an image macro with the given text, on your choice of the available selection of templates. This command can only be used inline. Alias: /memegen.'
end

function meme.escape(str)
    if not str
    or type(str) ~= 'string'
    then
        return str
    end
    str = str:lower()
    return str
    :gsub('%s', '_')
    :gsub('%?', '~q')
    :gsub('%%', '~p')
    :gsub('#', '~h')
    :gsub('/', '~s')
    :gsub('"', '\'\'')
end

meme.memes = {
    'ggg',
    'elf',
    'fwp',
    'yuno',
    'aag',
    'badchoice',
    'happening',
    'scc',
    'sad-obama',
    'fbf',
    'ants',
    'ive',
    'biw',
    'crazypills',
    'remembers',
    'oag',
    'ski',
    'oprah',
    'wonka',
    'regret',
    'fa',
    'keanu',
    'kermit',
    'both',
    'awkward',
    'dodgson',
    'bad',
    'mmm',
    'ch',
    'live',
    'firsttry',
    'noidea',
    'sad-biden',
    'buzz',
    'blb',
    'fry',
    'morpheus',
    'cbg',
    'xy',
    'rollsafe',
    'yodawg',
    'fetch',
    'sarcasticbear',
    'cb',
    'hipster',
    'success',
    'bd',
    'bender',
    'fine',
    'bs',
    'toohigh',
    'mw',
    'money',
    'interesting',
    'sb',
    'doge',
    'ermg',
    'fmr',
    'sparta',
    'older',
    'philosoraptor',
    'awkward-awesome',
    'awesome',
    'chosen',
    'alwaysonbeat',
    'ackbar',
    'sadfrog',
    'sohot',
    'imsorry',
    'tenguy',
    'winter',
    'red',
    'awesome-awkward',
    'jw',
    'sf',
    'ss',
    'patrick',
    'center',
    'boat',
    'saltbae',
    'tried',
    'mb',
    'hagrid',
    'mordor',
    'snek',
    'sad-bush',
    'nice',
    'sad-clinton',
    'afraid',
    'stew',
    'icanhas',
    'away',
    'dwight',
    'facepalm',
    'yallgot',
    'jetpack',
    'captain',
    'inigo',
    'iw',
    'dsm',
    'sad-boehner',
    'll',
    'joker',
    'sohappy',
    'officespace'
}

meme.meme_info = {
    ['tenguy'] = {
        ['width'] = 600,
        ['height'] = 544
    },
    ['afraid'] = {
        ['width'] = 600,
        ['height'] = 588
    },
    ['older'] = {
        ['width'] = 600,
        ['height'] = 255
    },
    ['aag'] = {
        ['width'] = 600,
        ['height'] = 502
    },
    ['tried'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['biw'] = {
        ['width'] = 600,
        ['height'] = 450
    },
    ['stew'] = {
        ['width'] = 600,
        ['height'] = 448
    },
    ['blb'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['kermit'] = {
        ['width'] = 600,
        ['height'] = 421
    },
    ['bd'] = {
        ['width'] = 600,
        ['height'] = 597
    },
    ['ch'] = {
        ['width'] = 600,
        ['height'] = 450
    },
    ['cbg'] = {
        ['width'] = 600,
        ['height'] = 368
    },
    ['wonka'] = {
        ['width'] = 600,
        ['height'] = 431
    },
    ['cb'] = {
        ['width'] = 600,
        ['height'] = 626
    },
    ['keanu'] = {
        ['width'] = 600,
        ['height'] = 597
    },
    ['dsm'] = {
        ['width'] = 600,
        ['height'] = 900
    },
    ['live'] = {
        ['width'] = 600,
        ['height'] = 405
    },
    ['ants'] = {
        ['width'] = 600,
        ['height'] = 551
    },
    ['doge'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['alwaysonbeat'] = {
        ['width'] = 600,
        ['height'] = 337
    },
    ['ermg'] = {
        ['width'] = 600,
        ['height'] = 901
    },
    ['facepalm'] = {
        ['width'] = 600,
        ['height'] = 529
    },
    ['firsttry'] = {
        ['width'] = 600,
        ['height'] = 440
    },
    ['fwp'] = {
        ['width'] = 600,
        ['height'] = 423
    },
    ['fa'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['fbf'] = {
        ['width'] = 600,
        ['height'] = 597
    },
    ['fmr'] = {
        ['width'] = 600,
        ['height'] = 385
    },
    ['fry'] = {
        ['width'] = 600,
        ['height'] = 449
    },
    ['ggg'] = {
        ['width'] = 600,
        ['height'] = 375
    },
    ['hipster'] = {
        ['width'] = 600,
        ['height'] = 899
    },
    ['icanhas'] = {
        ['width'] = 600,
        ['height'] = 874
    },
    ['crazypills'] = {
        ['width'] = 600,
        ['height'] = 408
    },
    ['mw'] = {
        ['width'] = 600,
        ['height'] = 441
    },
    ['noidea'] = {
        ['width'] = 600,
        ['height'] = 382
    },
    ['regret'] = {
        ['width'] = 600,
        ['height'] = 536
    },
    ['boat'] = {
        ['width'] = 600,
        ['height'] = 441
    },
    ['hagrid'] = {
        ['width'] = 600,
        ['height'] = 446
    },
    ['sohappy'] = {
        ['width'] = 600,
        ['height'] = 700
    },
    ['captain'] = {
        ['width'] = 600,
        ['height'] = 439
    },
    ['bender'] = {
        ['width'] = 600,
        ['height'] = 445
    },
    ['inigo'] = {
        ['width'] = 600,
        ['height'] = 326
    },
    ['iw'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['ackbar'] = {
        ['width'] = 600,
        ['height'] = 777
    },
    ['happening'] = {
        ['width'] = 600,
        ['height'] = 364
    },
    ['joker'] = {
        ['width'] = 600,
        ['height'] = 554
    },
    ['ive'] = {
        ['width'] = 600,
        ['height'] = 505
    },
    ['ll'] = {
        ['width'] = 600,
        ['height'] = 399
    },
    ['away'] = {
        ['width'] = 600,
        ['height'] = 337
    },
    ['morpheus'] = {
        ['width'] = 600,
        ['height'] = 363
    },
    ['mb'] = {
        ['width'] = 600,
        ['height'] = 534
    },
    ['badchoice'] = {
        ['width'] = 600,
        ['height'] = 478
    },
    ['mmm'] = {
        ['width'] = 600,
        ['height'] = 800
    },
    ['jetpack'] = {
        ['width'] = 600,
        ['height'] = 450
    },
    ['imsorry'] = {
        ['width'] = 600,
        ['height'] = 337
    },
    ['red'] = {
        ['width'] = 600,
        ['height'] = 557
    },
    ['mordor'] = {
        ['width'] = 600,
        ['height'] = 353
    },
    ['oprah'] = {
        ['width'] = 600,
        ['height'] = 449
    },
    ['oag'] = {
        ['width'] = 600,
        ['height'] = 450
    },
    ['remembers'] = {
        ['width'] = 600,
        ['height'] = 458
    },
    ['philosoraptor'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['jw'] = {
        ['width'] = 600,
        ['height'] = 401
    },
    ['patrick'] = {
        ['width'] = 600,
        ['height'] = 1056
    },
    ['rollsafe'] = {
        ['width'] = 600,
        ['height'] = 335
    },
    ['sad-obama'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['sad-clinton'] = {
        ['width'] = 600,
        ['height'] = 542
    },
    ['sadfrog'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['sad-bush'] = {
        ['width'] = 600,
        ['height'] = 455
    },
    ['sad-biden'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['sad-boehner'] = {
        ['width'] = 600,
        ['height'] = 479
    },
    ['saltbae'] = {
        ['width'] = 600,
        ['height'] = 603
    },
    ['sarcasticbear'] = {
        ['width'] = 600,
        ['height'] = 450
    },
    ['dwight'] = {
        ['width'] = 600,
        ['height'] = 393
    },
    ['sb'] = {
        ['width'] = 600,
        ['height'] = 421
    },
    ['ss'] = {
        ['width'] = 600,
        ['height'] = 604
    },
    ['sf'] = {
        ['width'] = 600,
        ['height'] = 376
    },
    ['dodgson'] = {
        ['width'] = 600,
        ['height'] = 559
    },
    ['money'] = {
        ['width'] = 600,
        ['height'] = 337
    },
    ['snek'] = {
        ['width'] = 600,
        ['height'] = 513
    },
    ['sohot'] = {
        ['width'] = 600,
        ['height'] = 480
    },
    ['nice'] = {
        ['width'] = 600,
        ['height'] = 432
    },
    ['awesome-awkward'] = {
        ['width'] = 600,
        ['height'] = 601
    },
    ['awesome'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['awkward-awesome'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['awkward'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['fetch'] = {
        ['width'] = 600,
        ['height'] = 450
    },
    ['success'] = {
        ['width'] = 600,
        ['height'] = 578
    },
    ['scc'] = {
        ['width'] = 600,
        ['height'] = 326
    },
    ['ski'] = {
        ['width'] = 600,
        ['height'] = 404
    },
    ['officespace'] = {
        ['width'] = 600,
        ['height'] = 501
    },
    ['interesting'] = {
        ['width'] = 600,
        ['height'] = 759
    },
    ['toohigh'] = {
        ['width'] = 600,
        ['height'] = 408
    },
    ['bs'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['fine'] = {
        ['width'] = 600,
        ['height'] = 582
    },
    ['sparta'] = {
        ['width'] = 600,
        ['height'] = 316
    },
    ['center'] = {
        ['width'] = 600,
        ['height'] = 370
    },
    ['both'] = {
        ['width'] = 600,
        ['height'] = 600
    },
    ['winter'] = {
        ['width'] = 600,
        ['height'] = 460
    },
    ['xy'] = {
        ['width'] = 600,
        ['height'] = 455
    },
    ['buzz'] = {
        ['width'] = 600,
        ['height'] = 455
    },
    ['yodawg'] = {
        ['width'] = 600,
        ['height'] = 399
    },
    ['yuno'] = {
        ['width'] = 600,
        ['height'] = 450
    },
    ['yallgot'] = {
        ['width'] = 600,
        ['height'] = 470
    },
    ['bad'] = {
        ['width'] = 600,
        ['height'] = 450
    },
    ['elf'] = {
        ['width'] = 600,
        ['height'] = 369
    },
    ['chosen'] = {
        ['width'] = 600,
        ['height'] = 342
    }
}

function meme.get_memes(offset, first_line, last_line)
    local first = (
        offset
        and type(offset) == 'number'
    )
    and offset + 1
    or 1
    local last = first + 49
    if first >= last
    then
        return
    elseif last > #meme.memes
    then
        last = #meme.memes
    end
    local output = {}
    local id = first
    for i = first, last
    do
        local image = 'https://memegen.link/' .. meme.memes[i] .. '/' .. meme.escape(first_line)
        if last_line
        then
            image = image .. '/' .. meme.escape(last_line)
        end
        image = image .. '.jpg?font=impact'
        table.insert(
            output,
            mattata.inline_result()
            :type('photo')
            :id(
                tostring(id)
            )
            :photo_url(image)
            :thumb_url(image)
            :photo_width(
                tostring(meme.meme_info[meme.memes[i]]['width'])
            )
            :photo_height(
                tostring(meme.meme_info[meme.memes[i]]['height'])
            )
        )
        id = id + 1
    end
    if last == #meme.memes
    then
        last = false
    end
    return output, last
end

function meme:on_inline_query(inline_query)
    local input = mattata.input(inline_query.query)
    if not input
    then
        return false
    end
    input = input:gsub('\n', ' | ')
    local first_line, last_line = input, false
    if input:match('^.- | .-$')
    then
        first_line, last_line = input:match('^(.-) | (.-)$')
    end
    first_line = first_line:gsub(' | ', ' ')
    if last_line
    then
        last_line = last_line:gsub(' | ', ' ')
    end
    local offset = inline_query.offset
    and tonumber(inline_query.offset)
    or 0
    local output, next_offset = meme.get_memes(
        offset,
        first_line,
        last_line
    )
    return mattata.answer_inline_query(
        inline_query.id,
        output,
        0,
        false,
        next_offset
        and tostring(next_offset)
        or nil
    )
end

function meme:on_message(message)
    return mattata.send_message(
        message.chat.id,
        'This command can only be used inline!'
    )
end

return meme