local pokedex = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local telegram_api = require('telegram_api')
local functions = require('functions')
function pokedex:init(configuration)
	pokedex.command = 'pokedex <query>'
	pokedex.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('pokedex', true):t('dex', true).table
	pokedex.documentation = configuration.command_prefix .. 'pokedex <query> - Returns a Pokedex entry from pokeapi.co. Alias: ' .. configuration.command_prefix .. 'dex.'
end
function pokedex:action(msg, configuration)
	telegram_api.sendChatAction( { chat_id = msg.chat.id, action = 'typing' } )
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
	local desc_url = url .. jdat.descriptions[math.random(#jdat.descriptions)].resource_uri
	local desc_jstr, _ = HTTP.request(desc_url)
	if res ~= 200 then
		functions.send_reply(msg, configuration.errors.connection)
		return
	end
	local desc_jdat = JSON.decode(desc_jstr)
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
	local output = '*' .. jdat.name .. '*\n#' .. jdat.national_id .. ' | ' .. poke_type .. '\n_' .. jdat.description:gsub('POKMON', 'Pokémon'):gsub('Pokmon', 'Pokémon') .. '_'
	functions.send_reply(msg, output, true)
end
return pokedex