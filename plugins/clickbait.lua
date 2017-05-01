--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local clickbait = {}
local mattata = require('mattata')
local json = require('dkjson')

function clickbait:init()
    clickbait.commands = mattata.commands(self.info.username):command('clickbait').table
    clickbait.help = '/clickbait - Generates a random, click-bait article headline.'
end

function clickbait.get_keyboard(language)
    return mattata.inline_keyboard():row(
        mattata.row():callback_data_button(
            language['clickbait']['1'],
            'clickbait:new'
        )
    )
end

function clickbait.generate()
    local prep = {
        'From Beyonce\'s New Album',
        'In The World',
        'In America',
        'From Christmas Songs',
        'From "The Lion King"',
        'From "Forrest Gump"',
        'From The Ocean Floor',
        'In South America',
        'In A Burrito',
        'In Space',
        'In Your Family Tree',
        'On Mars',
        'From "The Avengers"',
        'From LOST',
        'From Breaking Bad',
        'From Around The World',
        'From "Home Alone"',
        'From National Geographic\'s History',
        'From Last Night\'s "Saturday Night Live"',
        'From Politicians in 2013',
        'From Webcomics',
        'From Britney Spears\' Upcoming Documentary',
        'On The Moon',
        'From the National Hockey League',
        'From "The Daily Show"',
        'From Congress',
        'From One Direction Songs',
        'From "Duck Dynasty"',
        'From The "Doctor Who" 50th Anniversary',
        'In The History Of Cute',
        'In Ryan Gosling\'s 33 Years On Earth',
        'From The NYC Marathon'
    }
    local noun_desc = {
        '\'00s Teens Will Never Wear Again',
        '2000s Teens Loved',
        'Are Way More Important Than Work Right Now',
        'Every Twentysomething Needs',
        'Look Like Channing Tatum',
        'Look Like Miley Cyrus',
        'Never Stop Being Awkward',
        'Only Eldest Siblings Know',
        'Prove Cats Have Hearts Of Gold',
        'Prove Pugs Always Win At Halloween',
        'Prove The World Isn\'t Such A Bad Place',
        'Prove You And Your Mother Are The Same Person',
        'Scream World Domination',
        'Should Be Illegal',
        'Should Exist But Don\'t',
        'Will Haunt Your Dreams',
        'Will Help You Get Through The Week',
        'Will Make You Feel Filthy',
        'Will Make You Laugh Every Time',
        'Will Make You Spunk EVERYWHERE',
        'Will Make You Want To Fall In Love',
        'Will Make Your Skin Crawl',
        'Will Restore Your Faith In The Internet',
        'You\'ll Want To Keep For Yourself'
    }
    local people_desc = {
        'Are Too Clever For Their Own Good',
        'Completely Screwed Up Their One Job',
        'Had A Worse Year Than You',
        'Have No Idea What They Are Doing',
        'Are Only Famous To People Who Live In New York',
        'Are Having A Really Rough Day',
        'Will Make You Cum In Your Pants',
        'Need To Be Banned From Celebrating Halloween',
        'Tried To Find An Original Way To Go As Miley Cyrus For Halloween',
        'Are Clearly Being Raised Right',
        'Have Performed For Dictators',
        'Have Sucked Off Their Own Family Members',
        'Will Make You Feel Like A Genius',
        'Absolutely Nailed It In 2013'
    }
    local people = {
        'Architects',
        'Cats',
        'Video Game Characters',
        'Advertising Executives',
        'Teachers',
        'Doctors',
        'Nurse Practictioners',
        'Bodybuilders',
        'NFL Linebackers',
        'Porn Stars',
        'Prostitutes',
        'World Leaders',
        'Swimmers',
        'Wolves',
        'Sentient Humanoids',
        'Muggles',
        'Whales',
        'Comedians',
        'NBA Players',
        'Background Actors',
        'Celebrities',
        'People',
        'Nonces',
        '\'90s Kids',
        'Music Stars',
        'Tattoo Artists',
        'Oscar Winners',
        'Snapchat Billionaires',
        'Members of Limp Bizkit',
        'Avril Lavigne Fans',
        'Male Models',
        'Card Sharks',
        'Miners',
        'Investigative Journalists',
        'Smurfs',
        'Wimbledon Ballboys',
        'Aziz Ansari Impersonators',
        'People With Jetlag',
        'Parents',
        'Diplomats',
        'Atlanta Falcons',
        'Cowboys',
        'Justin Timberlake Fans',
        'Lazy People',
        'Commentators',
        'Twats',
        'News Anchors',
        'Olympic Medalists',
        'Superheroes',
        'Comic Book Villains',
        'Real Estate Moguls',
        'Disney Princesses',
        'Mad Men Characters',
        'Game of Thrones Characters',
        'Celebrity Impersonators',
        'Kardashians',
        'Deal or No Deal Models',
        'Cover Bands',
        'Former SNL Castmembers'
    }
    local adjest = {
        'Best',
        'Coolest',
        'Cutest',
        'Creepiest',
        'Worst',
        'Ugliest',
        'Greatest',
        'Cheesiest',
        'Funniest',
        'Illest',
        'Ghastliest',
        'Biggest',
        'Sexiest',
        'Slowest',
        'Most Delicate',
        'Most Picturesque',
        'Most Arrogant',
        'Most Confusing',
        'Most Beautiful',
        'Most Courageous',
        'Most Successful',
        'Most Tasteless',
        'Most Jizz-Worthy',
        'Most Inspirational',
        'Most Important',
        'Most Awkward',
        'Most Clickbait-like',
        'Most Disturbing',
        'Most Popular',
        'Most Beloved',
        'Most Wanted',
        'Most Adorable',
        'Most Unbelievably Flawless And Life-Changing'
    }
    local noun = {
        'Halloween Costumes',
        'Christmas Stock Photos',
        'Gifts',
        'Costumes',
        'Charts',
        'Emojis',
        'Facts',
        'Gowns',
        'Dildos',
        'GIFs',
        'Things',
        'Horses',
        'Items Of Clothing',
        'Moments',
        'Photographs',
        'Pictures',
        'Potatoes',
        'Pug Puppies',
        'Puns',
        'Ways To Eat A Burrito',
        'Easter Eggs',
        'Stories',
        'Things',
        'Sex Toys',
        'Truths',
        'Salads',
        'Cars',
        'Water Bottles',
        'Computer Mouses',
        'Punctuation Marks',
        'Christmas Foods',
        'Snapchat Filters',
        'Husky Puppies',
        'Series Finales',
        'Movie Scenes',
        'Country Songs',
        'Tweets',
        'Condoms',
        'VH1 Specials',
        'Investment Bankers',
        'SAT Words',
        'Autocorrects',
        'Memes',
        'Instagrams',
        'Snapchats',
        'Wedding Rings',
        'Fragrances',
        'Optical Illusions',
        'Advertisements',
        'Vegetables',
        'Cocks',
        'Animals',
        'Minerals',
        'Cheeses',
        'Pedophiles',
        'iPhone Apps',
        'Frat Houses',
        'Oprah-Grams',
        'Corporations',
        'Government Departments',
        'Doge Memes',
        'Pastries',
        'HBO Shows'
    }
    local time = {
        'All Time',
        'Your Childhood',
        '2013',
        'The Last 10 Years',
        'The \'80s',
        'Last Summer',
        'This Summer',
        'This Holiday Season',
        'The \'90s',
        'The Year You Were Born',
        'This Year',
        'Last Year',
        'This Century',
        'The Post-Y2K Era'
    }
    local combinations = {
        string.format(
            '%s Problems Only %s Will Understand',
            math.random(
                10,
                50
            ),
            people[math.random(#people)]
        ),
        string.format(
            'The %s %s %s Of %s',
            math.random(
                10,
                50
            ),
            adjest[math.random(#adjest)],
            noun[math.random(#noun)],
            time[math.random(#time)]
        ),
        string.format(
            'The %s %s %s %s',
            math.random(
                10,
                50
            ),
            adjest[math.random(#adjest)],
            noun[math.random(#noun)],
            prep[math.random(#prep)]
        ),
        string.format(
            '%s %s Who %s',
            math.random(
                10,
                50
            ),
            people[math.random(#people)],
            people_desc[math.random(#people_desc)]
        )
    }
    return combinations[math.random(#combinations)]
end

function clickbait:on_callback_query(callback_query, message, configuration, language)
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        clickbait.generate(),
        nil,
        true,
        clickbait.get_keyboard(language)
    )
end

function clickbait:on_message(message, configuration, language)
    return mattata.send_message(
        message.chat.id,
        clickbait.generate(),
        nil,
        true,
        false,
        message.message_id,
        clickbait.get_keyboard(language)
    )
end

return clickbait