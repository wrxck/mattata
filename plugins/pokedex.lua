--[[
    Based on a plugin by topkecleon.
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local pokedex = {}

local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')

function pokedex:init()
    pokedex.commands = mattata.commands(
        self.info.username
    ):command('pokedex')
     :command('dex').table
    pokedex.help = [[/pokedex <query> - Returns a Pokedex entry from pokeapi.co. Alias: /dex.]]
end

function pokedex:on_message(message)
    local input = mattata.input(message.text:lower())
    if not input then
        return mattata.send_reply(
            message,
            pokedex.help
        )
    end
    local jstr, res = http.request('http://pokeapi.co/api/v1/pokemon/' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    local name = jdat.name:gsub('^%l', string.upper)
    local id = '#' .. jdat.national_id
    local description_url = 'http://pokeapi.co' .. jdat.descriptions[math.random(#jdat.descriptions)].resource_uri
    local description_jstr, description_res = http.request(description_url)
    if description_res ~= 200 then
        return mattata.send_reply(
            message,
            configuration.errors.connection
        )
    end
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    local description_jdat = json.decode(description_jstr)
    local description = description_jdat.description:gsub('POKMON', 'Pokémon'):gsub('Pokmon', 'Pokémon'):gsub('Pokemon', 'Pokémon')
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
    return mattata.send_photo(
        message.chat.id,
        'https://img.pokemondb.net/artwork/' .. name:gsub('^%u', string.lower) .. '.jpg',
        'Name: ' .. name .. '\nID: ' .. id .. '\nType: ' .. poke_type .. '\nDescription: ' .. description
    )
end

return pokedex