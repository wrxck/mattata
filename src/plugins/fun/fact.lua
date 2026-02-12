--[[
    mattata v2.0 - Fact Plugin
    Returns a random (fake) humorous "fact".
]]

local plugin = {}
plugin.name = 'fact'
plugin.category = 'fun'
plugin.description = 'Get a random fake fact'
plugin.commands = { 'fact' }
plugin.help = '/fact - Get a random (definitely real) fact.'

local FACTS = {
    'The average person walks the equivalent of five times around the Earth in a lifetime. The rest is by Uber.',
    'Honey never spoils. Archaeologists have found 3,000-year-old honey that still had a "best before" sticker on it.',
    'Bananas are berries, but strawberries aren\'t. Botanists are just chaotic people.',
    'A group of flamingos is called a "flamboyance." They named themselves.',
    'Octopuses have three hearts, which is two more than your ex.',
    'It takes 364 licks to get to the centre of a Tootsie Pop. Scientists counted instead of doing real science.',
    'The inventor of the Pringles can is buried in one. His family chose sour cream and onion.',
    'A jiffy is an actual unit of time: 1/100th of a second. So when someone says "be there in a jiffy," hold them to it.',
    'The original name for the butterfly was "flutterby." Someone had a speech impediment and it just stuck.',
    'Cows have best friends and get stressed when separated. They also have terrible taste in music.',
    'The dot over the letters "i" and "j" is called a "tittle." This is not one of the fake facts.',
    'The unicorn is the national animal of Scotland. They take their myths very seriously.',
    'Pigeons can do maths. They just choose not to because they don\'t have student loans.',
    'An octopus has a doughnut-shaped brain. Which explains why they look so confused all the time.',
    'Sloths can hold their breath longer than dolphins. They just can\'t be bothered to brag about it.',
    'Humans share 60% of their DNA with bananas. The other 40% is anxiety.',
    'A bolt of lightning contains enough energy to toast 100,000 slices of bread. Nobody has tested this.',
    'Astronauts grow up to 2 inches taller in space. NASA calls this a "stretch goal."',
    'There are more possible iterations of a game of chess than there are atoms in the observable universe. And you still lost.',
    'Cats can\'t taste sweetness. This explains their personality.',
    'The longest English word without a vowel is "rhythms." Welsh people consider this a short word.',
    'A cloud can weigh more than a million pounds. And yet it floats. Show-off.',
    'Sharks are older than trees. They also have much better dental records.',
    'Wombat poop is cube-shaped. Evolution is weird.',
    'A day on Venus is longer than a year on Venus. Scheduling meetings there is a nightmare.',
    'An ostrich\'s eye is bigger than its brain. This explains their life choices.',
    'Your brain uses 20% of your body\'s total energy. The other 80% goes to worrying about emails.',
    'The average person produces enough saliva in their lifetime to fill two swimming pools. You\'re welcome.',
    'A flock of crows is called a murder. They knew what they were doing when they picked that name.',
    'In Switzerland, it is illegal to own just one guinea pig. They get lonely. It\'s the law.',
    'Dolphins sleep with one eye open. Trust issues, apparently.',
    'The shortest war in history lasted 38 to 45 minutes. The losing side forgot to set their alarm.',
    'Cleopatra lived closer to the invention of the iPhone than to the building of the Great Pyramid. Time is weird.',
    'A snail can sleep for three years. Goals.',
    'Oxford University is older than the Aztec Empire. They still haven\'t updated the WiFi password.',
    'Sea otters hold hands while they sleep so they don\'t drift apart. They\'re better than most people.',
    'Vending machines are more deadly than sharks. Watch your back at the office.',
    'An average cumulus cloud weighs about 1.1 million pounds. And you thought you had a heavy week.',
    'Honey badgers can withstand bee stings, porcupine quills, and even snake venom. They just don\'t care.',
    'A group of pugs is called a "grumble." Accurate.',
    'The fingerprints of koalas are virtually indistinguishable from those of humans. Koalas could frame you for a crime.',
    'You can\'t hum while holding your nose. You just tried it.',
    'Turtles can breathe through their bums. Don\'t ask how they found this out.',
    'The inventor of the fire hydrant is unknown because the patent was destroyed in a fire. Irony at its finest.',
    'A teaspoon of neutron star weighs about 6 billion tonnes. Definitely not dishwasher safe.',
    'Cows produce more milk when listening to slow music. Heavy metal makes them nervous.',
    'It rains diamonds on Jupiter and Saturn. Estate agents there must be thrilled.',
    'Banging your head against a wall burns 150 calories an hour. This is not medical advice.',
    'The Twitter bird\'s official name is Larry. He\'s doing fine.',
    'There\'s a species of jellyfish that is immortal. It still can\'t get a mortgage though.',
    'If you lift a kangaroo\'s tail off the ground, it can\'t hop. This is a terrible party trick.',
    'The average person will spend six months of their life waiting for red lights to turn green. The other half is spent refreshing social media.',
}

function plugin.on_message(api, message, ctx)
    math.randomseed(os.time() + os.clock() * 1000)
    local fact = FACTS[math.random(#FACTS)]
    return api.send_message(message.chat.id, fact)
end

return plugin
