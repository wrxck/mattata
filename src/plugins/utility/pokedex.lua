--[[
    mattata v2.0 - Pokedex Plugin
    Fetches Pokemon information from PokeAPI.
]]

local plugin = {}
plugin.name = 'pokedex'
plugin.category = 'utility'
plugin.description = 'Look up Pokemon information'
plugin.commands = { 'pokedex', 'pokemon', 'dex' }
plugin.help = '/pokedex <name|id> - Look up information about a Pokemon.'

function plugin.on_message(api, message, ctx)
    local https = require('ssl.https')
    local json = require('dkjson')
    local tools = require('telegram-bot-lua.tools')

    local input = message.args
    if not input or input == '' then
        return api.send_message(message.chat.id, 'Please specify a Pokemon name or ID. Usage: /pokedex <name|id>')
    end

    local query = input:lower():gsub('%s+', '-')
    local api_url = 'https://pokeapi.co/api/v2/pokemon/' .. query
    local body, status = https.request(api_url)
    if not body or status ~= 200 then
        return api.send_message(message.chat.id, 'Pokemon not found. Please check the name or ID and try again.')
    end

    local data = json.decode(body)
    if not data then
        return api.send_message(message.chat.id, 'Failed to parse Pokemon data.')
    end

    -- Capitalise name
    local name = (data.name or query):gsub('^%l', string.upper):gsub('%-(%l)', function(c) return '-' .. c:upper() end)

    -- Types
    local types = {}
    if data.types then
        for _, t in ipairs(data.types) do
            if t.type and t.type.name then
                table.insert(types, t.type.name:gsub('^%l', string.upper))
            end
        end
    end

    -- Abilities
    local abilities = {}
    if data.abilities then
        for _, a in ipairs(data.abilities) do
            if a.ability and a.ability.name then
                local ability_name = a.ability.name:gsub('^%l', string.upper):gsub('%-(%l)', function(c) return '-' .. c:upper() end)
                if a.is_hidden then
                    ability_name = ability_name .. ' (Hidden)'
                end
                table.insert(abilities, ability_name)
            end
        end
    end

    -- Base stats
    local stats = {}
    if data.stats then
        for _, s in ipairs(data.stats) do
            if s.stat and s.stat.name then
                local stat_name = s.stat.name:upper():gsub('%-', ' ')
                stats[stat_name] = s.base_stat
            end
        end
    end

    local lines = {
        string.format('<b>#%d - %s</b>', data.id or 0, tools.escape_html(name)),
        ''
    }

    if #types > 0 then
        table.insert(lines, 'Type: <code>' .. table.concat(types, ', ') .. '</code>')
    end

    table.insert(lines, string.format('Height: <code>%.1fm</code>', (data.height or 0) / 10))
    table.insert(lines, string.format('Weight: <code>%.1fkg</code>', (data.weight or 0) / 10))

    if #abilities > 0 then
        table.insert(lines, 'Abilities: <code>' .. table.concat(abilities, ', ') .. '</code>')
    end

    if next(stats) then
        table.insert(lines, '')
        table.insert(lines, '<b>Base Stats</b>')
        local stat_order = { 'HP', 'ATTACK', 'DEFENSE', 'SPECIAL ATTACK', 'SPECIAL DEFENSE', 'SPEED' }
        for _, stat_name in ipairs(stat_order) do
            if stats[stat_name] then
                table.insert(lines, string.format('%s: <code>%d</code>', stat_name, stats[stat_name]))
            end
        end
    end

    -- Send sprite if available
    local sprite = data.sprites and data.sprites.front_default
    if sprite then
        return api.send_photo(message.chat.id, sprite, table.concat(lines, '\n'), 'html')
    end

    return api.send_message(message.chat.id, table.concat(lines, '\n'), 'html')
end

return plugin
