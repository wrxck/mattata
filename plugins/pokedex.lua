local pokedex = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function pokedex:init(configuration)
	pokedex.arguments = 'pokedex <query>'
	pokedex.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pokedex'):c('dex').table
	pokedex.help = configuration.commandPrefix .. 'pokedex <query> - Returns a Pokedex entry from pokeapi.co. Alias: ' .. configuration.commandPrefix .. 'dex.'
end

function pokedex:onMessageReceive(message, configuration)
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, pokedex.help, nil, true, false, message.message_id, nil)
		return
	end
	local url = configuration.apis.pokedex .. input
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local name = jdat.name:gsub('^%l', string.upper)
	local id = '#' .. jdat.national_id
	local desc_url = 'http://pokeapi.co' .. jdat.descriptions[math.random(#jdat.descriptions)].resource_uri
	local desc_jstr, desc_res = HTTP.request(desc_url)
	if desc_res ~= 200 then
		mattata.sendMessage(message.chat.id, configuration.errors.connection, nil, true, false, message.message_id, nil)
		return
	end
	local desc_jdat = JSON.decode(desc_jstr)
	local description = desc_jdat.description:gsub('POKMON', 'Pokémon'):gsub('Pokmon', 'Pokémon'):gsub('Pokemon', 'Pokémon')
	local poke_type
	for _, v in ipairs(jdat.types) do
		local type_name = v.name:gsub('^%l', string.upper)
		if not poke_type then
			poke_type = type_name
		else
			poke_type = poke_type .. ' / ' .. type_name
		end
	end
	poke_type = poke_type .. ' type'
	local output = 'Name: ' .. name .. '\nID: ' .. id .. '\nType: ' .. poke_type .. '\nDescription: ' .. description
	mattata.sendPhoto(message.chat.id, 'https://img.pokemondb.net/artwork/' .. name:gsub('^%u', string.lower) .. '.jpg', nil, false, message.message_id, nil)
end

return pokedex