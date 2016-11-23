--[[

    Based on pokedex.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local pokedex = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function pokedex:init(configuration)
	pokedex.arguments = 'pokedex <query>'
	pokedex.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('pokedex'):c('dex').table
	pokedex.help = configuration.commandPrefix .. 'pokedex <query> - Returns a Pokedex entry from pokeapi.co. Alias: ' .. configuration.commandPrefix .. 'dex.'
end

function pokedex:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, pokedex.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTP.request('http://pokeapi.co/api/v1/pokemon/' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local name = jdat.name:gsub('^%l', string.upper)
	local id = '#' .. jdat.national_id
	local descriptionUrl = 'http://pokeapi.co' .. jdat.descriptions[math.random(#jdat.descriptions)].resource_uri
	local descriptionJstr, descriptionRes = HTTP.request(descriptionUrl)
	if descriptionRes ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local descriptionJdat = JSON.decode(descriptionJstr)
	local description = descriptionJdat.description:gsub('POKMON', 'Pokémon'):gsub('Pokmon', 'Pokémon'):gsub('Pokemon', 'Pokémon')
	local pokeType
	for _, v in ipairs(jdat.types) do
		local typeName = v.name:gsub('^%l', string.upper)
		if not pokeType then
			pokeType = typeName
		else
			pokeType = pokeType .. ' / ' .. typeName
		end
	end
	pokeType = pokeType .. ' type'
	mattata.sendPhoto(channel_post.chat.id, 'https://img.pokemondb.net/artwork/' .. name:gsub('^%u', string.lower) .. '.jpg', 'Name: ' .. name .. '\nID: ' .. id .. '\nType: ' .. pokeType .. '\nDescription: ' .. description, false, channel_post.message_id)
end

function pokedex:onMessage(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, pokedex.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://pokeapi.co/api/v1/pokemon/' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	local name = jdat.name:gsub('^%l', string.upper)
	local id = '#' .. jdat.national_id
	local descriptionUrl = 'http://pokeapi.co' .. jdat.descriptions[math.random(#jdat.descriptions)].resource_uri
	local descriptionJstr, descriptionRes = HTTP.request(descriptionUrl)
	if descriptionRes ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	mattata.sendChatAction(message.chat.id, 'upload_photo')
	local descriptionJdat = JSON.decode(descriptionJstr)
	local description = descriptionJdat.description:gsub('POKMON', 'Pokémon'):gsub('Pokmon', 'Pokémon'):gsub('Pokemon', 'Pokémon')
	local pokeType
	for _, v in ipairs(jdat.types) do
		local typeName = v.name:gsub('^%l', string.upper)
		if not pokeType then
			pokeType = typeName
		else
			pokeType = pokeType .. ' / ' .. typeName
		end
	end
	pokeType = pokeType .. ' type'
	mattata.sendPhoto(message.chat.id, 'https://img.pokemondb.net/artwork/' .. name:gsub('^%u', string.lower) .. '.jpg', 'Name: ' .. name .. '\nID: ' .. id .. '\nType: ' .. pokeType .. '\nDescription: ' .. description, false, message.message_id)
end

return pokedex