local pokedex = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('functions')
function pokedex:init(configuration)
	pokedex.command = 'pokedex <query>'
	pokedex.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('pokedex', true):t('dex', true).table
	pokedex.documentation = configuration.command_prefix .. 'pokedex <query> - Returns a Pokedex entry from pokeapi.co. Alias: ' .. configuration.command_prefix .. 'dex.'
end
function pokedex:action(msg, configuration)
	functions.send_action(msg.chat.id, 'upload_photo')
	local input = functions.input(msg.text)
	if not input then
		functions.send_reply(msg, pokedex.documentation)
		return
	end
	local url = configuration.apis.pokedex .. input
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local jdat = JSON.decode(jstr)
	local name = jdat.name:gsub('^%l', string.upper)
	local id = '#' .. jdat.national_id
	local desc_url = 'http://pokeapi.co' .. jdat.descriptions[math.random(#jdat.descriptions)].resource_uri
	local desc_jstr, desc_res = HTTP.request(desc_url)
	if desc_res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
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
	functions.send_photo(msg.chat.id, functions.download_to_file('https://img.pokemondb.net/artwork/' .. name:gsub('^%u', string.lower) .. '.jpg'), output, msg.message_id)
end
return pokedex