--[[
    mattata v2.0 - Pun Plugin
    Returns a random pun from a curated list.
]]

local plugin = {}
plugin.name = 'pun'
plugin.category = 'fun'
plugin.description = 'Get a random pun'
plugin.commands = { 'pun' }
plugin.help = '/pun - Get a random pun.'

local PUNS = {
    'I\'m reading a book about anti-gravity. It\'s impossible to put down.',
    'I used to hate facial hair, but then it grew on me.',
    'Did you hear about the claustrophobic astronaut? He just needed a little space.',
    'I\'m on a seafood diet. I see food and I eat it.',
    'Why don\'t scientists trust atoms? Because they make up everything.',
    'I told my wife she was drawing her eyebrows too high. She looked surprised.',
    'What do you call a fake noodle? An impasta.',
    'Why did the scarecrow win an award? He was outstanding in his field.',
    'I used to be a banker, but I lost interest.',
    'What do you call a bear with no teeth? A gummy bear.',
    'Why don\'t eggs tell jokes? They\'d crack each other up.',
    'I\'m afraid of elevators, so I\'m taking steps to avoid them.',
    'What do you call a dinosaur that crashes their car? Tyrannosaurus Wrecks.',
    'I got a job at a bakery because I kneaded dough.',
    'What do you call a sleeping dinosaur? A dino-snore.',
    'I used to play piano by ear, but now I use my hands.',
    'Why did the bicycle fall over? Because it was two-tired.',
    'What do you call a factory that makes okay products? A satisfactory.',
    'I tried to catch fog yesterday. Mist.',
    'What do you call a pile of cats? A meowtain.',
    'Why did the math book look so sad? Because it had too many problems.',
    'What do you call a belt made of watches? A waist of time.',
    'I don\'t trust stairs. They\'re always up to something.',
    'What do you call a can opener that doesn\'t work? A can\'t opener.',
    'Why couldn\'t the bicycle stand up by itself? It was two-tired.',
    'What did the ocean say to the beach? Nothing, it just waved.',
    'Why do cows have hooves instead of feet? Because they lactose.',
    'I once ate a clock. It was very time-consuming.',
    'What do you call a fish without eyes? A fsh.',
    'Why did the golfer bring two pairs of pants? In case he got a hole in one.',
    'What do you call a dog that does magic? A Labracadabrador.',
    'I used to be addicted to soap, but I\'m clean now.',
    'What do you call a bear in the rain? A drizzly bear.',
    'Why don\'t some couples go to the gym? Because some relationships don\'t work out.',
    'What did the grape do when it got stepped on? It let out a little wine.',
    'I\'m terrified of lifts. I\'m going to start taking steps to avoid them.',
    'What do you call a cow with no legs? Ground beef.',
    'Why did the tomato turn red? Because it saw the salad dressing.',
    'What do you call an alligator wearing a vest? An investigator.',
    'I told a chemistry joke. There was no reaction.',
    'What do you call a snowman with a six-pack? An abdominal snowman.',
    'Why did the coffee file a police report? It got mugged.',
    'What do you call a boomerang that doesn\'t come back? A stick.',
    'I used to be a shoe salesman, till they gave me the boot.',
    'What do lawyers wear to court? Lawsuits.',
    'What do you get when you cross a snowman with a vampire? Frostbite.',
    'Why did the stadium get hot after the game? All the fans left.',
    'What do you call a deer with no eyes? No idea.',
    'I wanted to be a doctor, but I didn\'t have the patience.',
    'What did the fish say when it hit a wall? Dam.',
    'Why don\'t skeletons fight each other? They don\'t have the guts.',
    'What did the janitor say when he jumped out of the cupboard? Supplies!',
    'I just got a job at a calendar factory. I can\'t wait to get a few days off.',
}

function plugin.on_message(api, message, ctx)
    math.randomseed(os.time() + os.clock() * 1000)
    local pun = PUNS[math.random(#PUNS)]
    return api.send_message(message.chat.id, pun)
end

return plugin
