local pokedex = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function pokedex:init(configuration)
	pokedex.arguments = 'pokedex <query>'
	pokedex.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('pokedex'):command('dex').table
	pokedex.help = configuration.commandPrefix .. 'pokedex <query> - Returns a Pokedex entry from pokeapi.co. Alias: ' .. configuration.commandPrefix .. 'dex.'
end

function pokedex:onMessage(message, language)
	local input = mattata.input(message.text_lower)
	if not input then mattata.sendMessage(message.chat.id, pokedex.help, nil, true, false, message.message_id); return end
	local jstr, res = http.request('http://pokeapi.co/api/v1/pokemon/' .. url.escape(input))
	if res ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id); return end
	local jdat = json.decode(jstr)
	local name = jdat.name:gsub('^%l', string.upper)
	local id = '#' .. jdat.national_id
	local descriptionUrl = 'http://pokeapi.co' .. jdat.descriptions[math.random(#jdat.descriptions)].resource_uri
	local descriptionJstr, descriptionRes = http.request(descriptionUrl)
	if descriptionRes ~= 200 then mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id); return end
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	local descriptionJdat = json.decode(descriptionJstr)
	local description = descriptionJdat.description:gsub('POKMON', 'Pokémon'):gsub('Pokmon', 'Pokémon'):gsub('Pokemon', 'Pokémon')
	local pokeType
	for _, v in ipairs(jdat.types) do
		local typeName = v.name:gsub('^%l', string.upper)
		if not pokeType then pokeType = typeName else pokeType = pokeType .. ' / ' .. typeName end
	end
	pokeType = pokeType .. ' type'
	mattata.sendPhoto(message.chat.id, 'https://img.pokemondb.net/artwork/' .. name:gsub('^%u', string.lower) .. '.jpg', 'Name: ' .. name .. '\nID: ' .. id .. '\nType: ' .. pokeType .. '\nDescription: ' .. description, false, message.message_id)
end

return pokedex