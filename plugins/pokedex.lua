--[[
    Based on a plugin by topkecleon. Licensed under GNU AGPLv3
    https://github.com/topkecleon/otouto/blob/master/LICENSE.
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local pokedex = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function pokedex:init()
    pokedex.commands = mattata.commands(self.info.username):command('pokedex'):command('pokemon'):command('dex').table
    pokedex.help = '/pokedex [name|ID] - If no input is given, an interactive Pokédex is sent. If input is given, information about the given Pokémon (either specified by name or ID) is returned. Results are provided by PokéAPI. Aliases: /pokemon, /dex.'
end

function pokedex.get_next_chain(evolution)
    if not evolution then
        return false
    end
    return evolution.species.name:gsub('^l', string.upper), evolution.evolves_to[1]
end

function pokedex.get_chain(id)
    local jstr, res = https.request('https://pokeapi.co/api/v2/pokemon-species/' .. id)
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    if not jdat.evolution_chain then
        return '<em>This Pokémon doesn\'t evolve to/from anything...</em>'
    end
    jstr, res = https.request(jdat.evolution_chain.url)
    if res ~= 200 then
        return false
    end
    jdat = json.decode(jstr)
    local name, evolves_to = pokedex.get_next_chain(jdat.chain)
    local chain = name
    repeat
        name, evolves_to = pokedex.get_next_chain(evolves_to)
        if name then
            chain = chain .. string.format(' %s %s', mattata.symbols.next, name)
        end
    until not name
    if not chain:match(mattata.symbols.next) then
        return '<em>This Pokémon doesn\'t evolve to/from anything...</em>'
    end
    return 'Evolution chain: <code>' .. chain .. '</code>'
end

function pokedex.get_keyboard(page, columns, per_page)
    page = page or 1
    local offset = math.floor((page - 1) * per_page)
    local jstr, res = https.request('https://pokeapi.co/api/v2/pokemon?offset=' .. offset .. '&limit=' .. per_page)
    if res ~= 200 then
        return false
    end
    local jdat = json.decode(jstr)
    local all = jdat.results
    local page_count = math.floor(jdat.count / per_page)
    if page_count < jdat.count / per_page then
        page_count = page_count + 1
    end
    if page < 1 then
        page = page_count
    elseif page > page_count then
        page = 1
    end
    local start_res = 1
    local end_res = per_page
    if end_res > #all then
        end_res = #all
    end
    local pokemon = 0
    local output = {}
    for _, v in pairs(all) do
        v.name = v.name:lower()
        pokemon = pokemon + 1
        if pokemon >= start_res and pokemon <= end_res then
            table.insert(output, {
                ['name'] = v.name,
                ['id'] = v.url:match('pokemon/(%d*)/$')
            })
        end
    end
    local keyboard = {
        ['inline_keyboard'] = {{}}
    }
    local rows_per_page = math.floor(#output / columns)
    if rows_per_page < (#output / columns) then
        rows_per_page = rows_per_page + 1
    end
    local columns_per_page = math.floor(#output / rows_per_page)
    if columns_per_page < (#output / rows_per_page) then
        columns_per_page = columns_per_page + 1
    end
    local current_row = 1
    local count = 0
    for n in pairs(output) do
        count = count + 1
        if count == (columns_per_page * current_row) + 1 then
            current_row = current_row + 1
            table.insert(keyboard.inline_keyboard, {})
        end
        table.insert(keyboard.inline_keyboard[current_row], {
            ['text'] = '#' .. output[n].id .. ': ' .. output[n].name:gsub('^.', string.upper),
            ['callback_data'] = string.format('pokedex:%s:%s', output[n].name, page)
        })
    end
    local previous_page = page - 1
    if previous_page < 1 then
        previous_page = page_count
    end
    local next_page = page + 1
    if next_page > page_count then
        next_page = 1
    end
    table.insert(keyboard.inline_keyboard, {{
        ['text'] = utf8.char(8592) .. ' Previous',
        ['callback_data'] = string.format('pokedex:page:%s', previous_page)
    }, {
        ['text'] = string.format('%s/%s', page, page_count),
        ['callback_data'] = 'pokedex:nil'
    }, {
        ['text'] = 'Next ' .. utf8.char(8594),
        ['callback_data'] = string.format('pokedex:page:%s', next_page)
    }})
    return keyboard
end

function pokedex.on_callback_query(_, callback_query, message, _, language)
    local callback_type, page = callback_query.data:match('^(.-):(.-)$')
    if not callback_type or not page then
        return mattata.answer_callback_query(callback_query.id)
    elseif callback_type == 'page' then
        local keyboard = pokedex.get_keyboard(tonumber(page), 3, 21)
        return mattata.edit_message_text(message.chat.id, message.message_id, '<em>Select a Pokémon to view more information about it</em>', 'html', true, keyboard)
    end
    local output = pokedex.get_pokemon(callback_type, language)
    local keyboard = mattata.inline_keyboard():row(
        mattata.row():callback_data_button(mattata.symbols.back .. ' Back', 'pokedex:page:' .. page)
    )
    return mattata.edit_message_text(message.chat.id, message.message_id, output, 'html', false, keyboard)
end

function pokedex.get_pokemon(pokemon, language)
    if not pokemon then
        return language.errors.results
    end
    local jstr, res = https.request('https://pokeapi.co/api/v2/pokemon/' .. url.escape(pokemon))
    if res ~= 200 then
        return 'Please make sure you\'ve specified the Pokémon by its correct name. Alternatively, you can specify it by its Pokédex ID.'
    end
    local jdat = json.decode(jstr)
    local name = jdat.name:gsub('^%l', string.upper)
    local id = '#' .. jdat.id
    local descriptions = {}
    local description = 'Description unavailable'
    jstr, res = https.request('https://pokeapi.co/api/v2/pokemon-species/' .. jdat.id)
    if res == 200 then
        description = json.decode(jstr)
        for _, v in pairs(description.flavor_text_entries) do
            if v.language.name == 'en' then
                table.insert(descriptions, v)
            end
        end
        if next(descriptions) then
            description = descriptions[#descriptions].flavor_text:gsub('[\n\f]', ' ')
        end
    end
    description = description:gsub('[Pp][Oo][Kk][Eeé]?[Mm][Oo][Nn]', 'Pokémon')
    local poke_type
    for _, v in pairs(jdat.types) do
        local type_name = v.type.name:gsub('^%l', string.upper)
        if not poke_type then
            poke_type = type_name
        else
            poke_type = poke_type .. ' / ' .. type_name
        end
    end
    poke_type = poke_type .. ' type'
    local output = '<a href="%s">%s</a> <b>%s</b>\n%s\n\n<em>%s</em>'
    output = string.format(output, 'https://img.pokemondb.net/artwork/' .. name:gsub('^%u', string.lower) .. '.jpg', id, name, poke_type, description)
    if jdat.species then
        local species = jdat.species.url:match('species/(%d*)/$')
        species = pokedex.get_chain(species)
        if species then
            output = output .. '\n\n' .. species
        end
    end
    return output
end

function pokedex.on_message(_, message, _, language)
    local input = mattata.input(message.text:lower())
    if not input then
        return mattata.send_reply(message, 'Please select a Pokémon:', nil, false, pokedex.get_keyboard(1, 3, 21))
    end
    local output = pokedex.get_pokemon(input, language)
    return mattata.send_message(message.chat.id, output, 'html', false, false)
end

return pokedex