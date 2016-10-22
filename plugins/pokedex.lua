local pokedex = {}
local HTTP = require('dependencies.socket.http')
local JSON = require('dependencies.dkjson')
local mattata = require('mattata')

function pokedex:init(configuration)
	pokedex.arguments = 'pokedex <query>'
	pokedex.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pokedex', true):c('dex', true).table
	pokedex.help = configuration.commandPrefix .. 'pokedex <query> - Returns a Pokedex entry from pokeapi.co. Alias: ' .. configuration.commandPrefix .. 'dex.'
end

function pokedex:onMessageReceive(msg, configuration)
	mattata.sendChatAction(msg.chat.id, 'upload_photo')
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, pokedex.help, nil, true, false, msg.message_id, nil)
		return
	end
	local url = configuration.apis.pokedex .. input
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local name = jdat.name:gsub('^%l', string.upper)
	local id = '#' .. jdat.national_id
	local desc_url = 'http://pokeapi.co' .. jdat.descriptions[math.random(#jdat.descriptions)].resource_uri
	local desc_jstr, desc_res = HTTP.request(desc_url)
	if desc_res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
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
	mattata.sendPhoto(msg.chat.id, 'https://img.pokemondb.net/artwork/' .. name:gsub('^%u', string.lower) .. '.jpg', nil, false, msg.message_id, nil)
end

return pokedex