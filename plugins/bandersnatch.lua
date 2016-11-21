--[[

    Based on bandersnatch.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local bandersnatch = {}
local mattata = require('mattata')

function bandersnatch:init(configuration)
	bandersnatch.arguments = 'bandersnatch'
	bandersnatch.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('bandersnatch').table
	bandersnatch.inlineCommands = bandersnatch.commands
	bandersnatch.help = configuration.commandPrefix .. 'bandersnatch - Generates a fun, tongue-twisting name.'
end

local fullNames = {
	'Wimbledon Tennismatch',
	'Rinkydink Curdlesnoot',
	'Butawhiteboy Cantbekhan',
	'Benadryl Claritin',
	'Bombadil Rivendell',
	'Wanda Crotchfruit',
	'Biblical Concubine',
	'Syphilis Cankersore',
	'Buckminster Fullerene',
	'Bourgeoisie Capitalist'
}

local firstNames = {
	'Bumblebee',
	'Bandersnatch',
	'Broccoli',
	'Rinkydink',
	'Bombadil',
	'Boilerdang',
	'Bandicoot',
	'Fragglerock',
	'Muffintop',
	'Congleton',
	'Blubberdick',
	'Buffalo',
	'Benadryl',
	'Butterfree',
	'Burberry',
	'Whippersnatch',
	'Buttermilk',
	'Beezlebub',
	'Budapest',
	'Boilerdang',
	'Blubberwhale',
	'Bumberstump',
	'Bulbasaur',
	'Cogglesnatch',
	'Liverswort',
	'Bodybuild',
	'Johnnycash',
	'Bendydick',
	'Burgerking',
	'Bonaparte',
	'Bunsenburner',
	'Billiardball',
	'Bukkake',
	'Baseballmitt',
	'Blubberbutt',
	'Baseballbat',
	'Rumblesack',
	'Barister',
	'Danglerack',
	'Rinkydink',
	'Bombadil',
	'Honkytonk',
	'Billyray',
	'Bumbleshack',
	'Snorkeldink',
	'Anglerfish',
	'Beetlejuice',
	'Bedlington',
	'Bandicoot',
	'Boobytrap',
	'Blenderdick',
	'Bentobox',
	'Anallube',
	'Pallettown',
	'Wimbledon',
	'Buttercup',
	'Blasphemy',
	'Snorkeldink',
	'Brandenburg',
	'Barbituate',
	'Snozzlebert',
	'Tiddleywomp',
	'Bouillabaisse',
	'Wellington',
	'Benetton',
	'Bendandsnap',
	'Timothy',
	'Brewery',
	'Bentobox',
	'Brandybuck',
	'Benjamin',
	'Buckminster',
	'Bourgeoisie',
	'Bakery',
	'Oscarbait',
	'Buckyball',
	'Bourgeoisie',
	'Burlington',
	'Buckingham',
	'Barnoldswick'
}

local lastNames = {
	'Coddleswort',
	'Crumplesack',
	'Curdlesnoot',
	'Calldispatch',
	'Humperdinck',
	'Rivendell',
	'Cuttlefish',
	'Lingerie',
	'Vegemite',
	'Ampersand',
	'Cumberbund',
	'Candycrush',
	'Clombyclomp',
	'Cragglethatch',
	'Nottinghill',
	'Cabbagepatch',
	'Camouflage',
	'Creamsicle',
	'Curdlemilk',
	'Upperclass',
	'Frumblesnatch',
	'Crumplehorn',
	'Talisman',
	'Candlestick',
	'Chesterfield',
	'Bumbersplat',
	'Scratchnsniff',
	'Snugglesnatch',
	'Charizard',
	'Carrotstick',
	'Cumbercooch',
	'Crackerjack',
	'Crucifix',
	'Cuckatoo',
	'Cockletit',
	'Collywog',
	'Capncrunch',
	'Covergirl',
	'Cumbersnatch',
	'Countryside',
	'Coggleswort',
	'Splishnsplash',
	'Copperwire',
	'Animorph',
	'Curdledmilk',
	'Cheddarcheese',
	'Cottagecheese',
	'Crumplehorn',
	'Snickersbar',
	'Banglesnatch',
	'Stinkyrash',
	'Cameltoe',
	'Chickenbroth',
	'Concubine',
	'Candygram',
	'Moldyspore',
	'Chuckecheese',
	'Cankersore',
	'Crimpysnitch',
	'Wafflesmack',
	'Chowderpants',
	'Toodlesnoot',
	'Clavichord',
	'Cuckooclock',
	'Oxfordshire',
	'Cumbersome',
	'Chickenstrips',
	'Battleship',
	'Commonwealth',
	'Cunningsnatch',
	'Custardbath',
	'Kryptonite',
	'Curdlesnoot',
	'Cummerbund',
	'Coochyrash',
	'Crackerdong',
	'Curdledong',
	'Crackersprout',
	'Crumplebutt',
	'Colonist',
	'Coochierash',
	'Thundersnatch'
}

function bandersnatch:onInlineCallback(inline_query)
	local output
	if math.random(10) == 10 then
		output = fullNames[math.random(#fullNames)]
	else
		output = firstNames[math.random(#firstNames)] .. ' ' .. lastNames[math.random(#lastNames)]
	end
	mattata.answerInlineQuery(inline_query.id, '[' .. mattata.generateInlineArticle(1, output, output, 'Markdown', false, 'Click to send your new name!') .. ']', 0)
end

function bandersnatch:onChannelPostReceive(channel_post)
	local output
	if math.random(10) == 10 then
		output = fullNames[math.random(#fullNames)]
	else
		output = firstNames[math.random(#firstNames)] .. ' ' .. lastNames[math.random(#lastNames)]
	end
	mattata.sendMessage(channel_post.chat.id, output, nil, true, false, channel_post.message_id)
end

function bandersnatch:onMessageReceive(message)
	local output
	if math.random(10) == 10 then
		output = fullNames[math.random(#fullNames)]
	else
		output = firstNames[math.random(#firstNames)] .. ' ' .. lastNames[math.random(#lastNames)]
	end
	mattata.sendMessage(message.chat.id, output, nil, true, false, message.message_id)
end

return bandersnatch