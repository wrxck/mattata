local deadbaby = {}
local mattata = require('mattata')

function deadbaby:init(configuration)
	deadbaby.arguments = 'deadbaby'
	deadbaby.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('deadbaby').table
	deadbaby.help = configuration.commandPrefix .. 'deadbaby - Generates a random dead baby joke.'
end

local jokes = {
	'*What is funnier than a dead baby?*\nA dead baby in a clown costume.',
	'*What is the difference between a baby and a onion?*\nNo one cries when you chop up the baby.',
	'*What is the difference between a dead baby and a watermelon?*\nOne\'s fun to hit with a sledgehammer, the other one\'s a watermelon.',
	'*What is the difference between a baby and a dart-board?*\nDart-boards don\'t bleed.',
	'*What is the difference between a baby and a Mars bar?*\nAbout 500 calories.',
	'*Why did the family take the dead baby along on the cookout?*\nSo they could light it and toast their marshmallows.',
	'*Why was the dead baby kept in the kitchen drawer?*\nThe family used it to crack nuts.',
	'*Why do people keep dead babies in the recreation room?*\nSo they can cut off one leg and use it as a ping-pong paddle.',
	'*Why do you put babies into blenders feet first?*\nSo you can see the expression on their faces.',
	'*Why do people boil water when a baby is being born?*\nSo that if it\'s born dead they can make soup!',
	'*Why did the baby cross the road?*\nIt was stapled to the chicken, that\'s why!',
	'*How many babies does it take to make a bottle of baby oil?*\nIt depends on how hard you squeeze them.',
	'*How many babies can fit in a blender?*\nIt depends on how powerful the blender is.',
	'*How do you know when a baby is dead?*\nIt doesn\'t cry if you nail its feet to the ceiling.',
	'*How do you find a live baby in a pile of dead ones?*\nJab \'em all with a pitchfork.',
	'*How do you save a drowning baby?*\nHarpoon it.',
	'*How do you turn a baby into a dog?*\nPour gas over it and light a match.\n_Woof._',
	'*How do you turn a baby into a cat?*\nFreeze it solid, then run it through a bandsaw.\n_Meow._',
	'*How do you get 100 babies into a single bucket?*\nWith a blender.\n*How do you get them out again?*\nBy using them as a dip for your Doritos.',
	'*How do you make a dead baby float?*\nTake your foot off of its head.',
	'*How do you make a dead baby float?*\n1 glass of soda water and 2 scoops of baby.',
	'*What do you call two abortions in a bucket?*\nBlood brothers.',
	'*What is red and creeps up your leg?*\nAn abortion with homesickness.',
	'*What is a foot long and can make a woman scream?*\nStillbirth.',
	'*What is a foot long, blue, and makes women scream in the morning?*\nCrib death.',
	'*What do you call a dead baby pinned to your wall?*\nArt.',
	'*What is red, bubbles, and scratches at the window before exploding?*\nA baby in a microwave.',
	'*What is blue, yellow and sits at the bottom of the pool?*\nA baby with punctured floaties.',
	'*What is red, yellow and floats at the top of the pool?*\nFloaties with a punctured baby.',
	'*What is red and hangs around trees?*\nA baby that has been hit by a snow blower.',
	'*What is green and hangs around trees?*\nA baby that has been hit by a snow blower, and found 3 weeks later.',
	'*What is pink, red, silver and crawls into walls?*\nA baby with forks in its eyes.',
	'*What is pink and goes black with a \'hiss\'?*\nA baby being thrown into a furnace.',
	'*What is brown and gurgles?*\nA baby in a casserole.',
	'*What is purple, lavished in blood and squeals?*\nA peeled baby in a bag of salt.',
	'*What is black and goes up and down?*\nA baby in a toaster.',
	'*What is red and hangs out of the back of a train?*\nA miscarriage.',
	'*What is red and goes round and round?*\nA baby in a garbage disposal.',
	'*What is red and swings back and forth?*\nA baby on a meat hook.',
	'*What is red, screams, and goes around in circles?*\nA baby nailed to the floor.',
	'*What is red and sits in the corner?*\nA baby with razor blades.',
	'*What is blue and sits in the corner?*\nA baby in a baggie.',
	'*What is black and sits in a corner?*\nA baby with it\'s finger in a power socket.',
	'*What is green and sits in the corner?*\nA baby with it\'s finger in a power socket, found 2 weeks later.',
	'*What is black and charred?*\nA baby chewing on an extension cord.',
	'*What is black and white, runs around the room, and smokes?*\nA baby with his hair on fire.',
	'*What is blue and flies around the room at high speeds?*\nA baby with a punctured lung.',
	'*What is cold, blue and doesn\'t move?*\nA baby in your freezer.',
	'*What is pink, flies and squeals?*\nA baby fired from a catapult.\n*What do you call the baby when it lands?*\nFree pizza.',
	'*What is red and has more brains than the baby you just shot?*\nThe wall behind it.',
	'*What is white and glows pink?*\nA dead baby with an electrode up its ass.',
	'*What is more fun than nailing a baby to a wall?*\nRipping it off again.',
	'*What is more fun than throwing a baby off the cliff?*\nCatching it with a pitchfork.',
	'*What is more fun than swinging babies around on a clothesline?*\nStopping them with a shovel.',
	'*What is more fun than shoveling dead babies off your porch?*\nDoing it with a snow blower.',
	'*What sits in the kitchen and keeps getting smaller and smaller?*\nA baby combing it\'s hair with a potato peeler.',
	'*What bounces up and down at 100mph?*\nA baby tied to the back of a truck.',
	'*What goes plop, plop, fizz, fizz?*\nTwins in an acid bath.',
	'*What is red and pink and can\'t turn around in a corridor?*\nA baby with a javelin through its throat.',
	'*What is little, but can\'t fit through a door?*\nA baby with a spear in its head.',
	'*What is the definition of fun?*\nPlaying fetch with a pitbull and a baby.',
	'*What has 4 legs and one arm?*\nA doberman on a children\'s playground.',
	'*What has 4 legs, 10 arms and blood all over it?*\nA pitbull in front of a pile of dead babies.',
	'*What is red and pink and hanging out of your dog\'s mouth?*\nYour baby\'s leg, LOL!',
	'*What should you get for a dead baby for its birthday?*\nA dead puppy.',
	'*What is grosser than ten dead babies nailed to a tree?*\nOne dead baby nailed to ten trees.',
	'*What is worse than a dead baby in a trash can?*\n100 dead babies in a trash can.\n*You know what is worse than that?*\nThere\'s a live one at the bottom.\n*You know what is worse than that?*It eats its way out.\n*You know what is even worse than that?*\nIt comes back for seconds.',
	'*You know what\'s gross?*\nRunning over a baby with a truck.\n*You know what\'s worse?*\nSkidding on it.\n*You know what\'s worse than that?*\nPeeling it off of the tires.',
	'*What is the worst part about killing a baby?*\nGetting blood on your clown outfit.'
}

function deadbaby:onMessageReceive(message, configuration)
	mattata.sendMessage(message.chat.id, jokes[math.random(#jokes)], 'Markdown', true, false, message.message_id)
end

return deadbaby
