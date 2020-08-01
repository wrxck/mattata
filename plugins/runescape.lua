--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local runescape = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function runescape:init()
    runescape.commands = mattata.commands(self.info.username):command('runescape').table
    runescape.help = '/runescape <player name> - Displays skill-related information about the given RuneScape player.'
end

function runescape.errors(error_message, language)
    local errors = {
        ['NO_PROFILE'] = 'This player does not have a RuneMetrics profile!',
        ['PROFILE_PRIVATE'] = 'This player appears to have privacy mode enabled on their RuneMetrics profile!',
        ['Unable to fetch profile'] = 'This player appears to have privacy mode enabled on their RuneMetrics profile!'
    }
    return errors[error_message]
    or language['errors']['generic']
end

function runescape.get_skill_info(jdat)
    local skills = {
        ['0'] = 'Attack',
        ['1'] = 'Defence',
        ['2'] = 'Strength',
        ['3'] = 'Constitution',
        ['4'] = 'Ranged',
        ['5'] = 'Prayer',
        ['6'] = 'Magic',
        ['7'] = 'Cooking',
        ['8'] = 'Woodcutting',
        ['9'] = 'Fletching',
        ['10'] = 'Fishing',
        ['11'] = 'Firemaking',
        ['12'] = 'Crafting',
        ['13'] = 'Smithing',
        ['14'] = 'Mining',
        ['15'] = 'Herblore',
        ['16'] = 'Agility',
        ['17'] = 'Thieving',
        ['18'] = 'Slayer',
        ['19'] = 'Farming',
        ['20'] = 'Runecrafting',
        ['21'] = 'Hunter',
        ['22'] = 'Construction',
        ['23'] = 'Summoning',
        ['24'] = 'Dungeoneering',
        ['25'] = 'Divination',
        ['26'] = 'Invention',
        ['27'] = 'Archaeology'
    }
    local output = {}
    local longest_skill = 0
    local longest_rank = 0
    local longest_xp = 0
    local skill, rank, xp
    for _, v in pairs(jdat) do
        v.rank = v.rank or 'N/A'
        if v.id then
            skill = tostring(v.id)
            skill = skills[skill]
            if skill:len() > longest_skill then
                longest_skill = skill:len()
            end
        end
        if v.rank then
            rank = v.rank
            if rank ~= 'N/A' then
                rank = tonumber(rank)
                rank = mattata.comma_value(rank)
            end
            rank = tostring(rank)
            if rank:len() > longest_rank then
                longest_rank = rank:len()
            end
        end
        if v.xp then
            v.xp = tonumber(v.xp) / 10
            xp = mattata.comma_value(v.xp)
            xp = tostring(xp)
            if xp:len() > longest_xp then
                longest_xp = xp:len()
            end
        end
    end
    if longest_skill < 5 then
        longest_skill = 5
    end
    if longest_rank < 4 then
        longest_rank = 4
    end
    if longest_xp < 2 then
        longest_xp = 2
    end
    local separator = '|-'
    for _ = 1, longest_skill do
        separator = separator .. '-'
    end
    separator = separator .. '-|-------|-'
    for _ = 1, longest_rank do
        separator = separator .. '-'
    end
    separator = separator .. '-|-'
    for _ = 1, longest_xp do
        separator = separator .. '-'
    end
    separator = separator .. '-|'
    table.insert(output, separator)
    local heading = ''
    for k, v in pairs(jdat) do
        v.rank = v.rank or 'N/A'
        if v.id and v.level and v.rank and v.xp then
            local id = tostring(v.id)
            skill = skills[id]
            if skill:len() < longest_skill then
                repeat
                    skill = skill .. ' '
                until skill:len() == longest_skill
            end
            local level = tostring(v.level)
            repeat
                level = level .. ' '
            until level:len() == 5
            rank = v.rank
            if rank ~= 'N/A' then
                rank = tonumber(rank)
                rank = mattata.comma_value(rank)
            end
            rank = tostring(rank)
            if rank:len() < longest_rank then
                repeat
                    rank = rank .. ' '
                until rank:len() == longest_rank
            end
            xp = mattata.comma_value(v.xp)
            xp = tostring(xp)
            if xp:len() < longest_xp then
                repeat
                    xp = xp .. ' '
                until xp:len() == longest_xp
            end
            local row = '| ' .. skill .. ' | ' .. level .. ' | ' .. rank .. ' | ' .. xp .. ' |'
            table.insert(output, row)
            if k < #jdat then
                table.insert(output, separator)
            else
                skill = 'Skill'
                if skill:len() < longest_skill then
                    repeat
                        skill = skill .. ' '
                    until skill:len() == longest_skill
                end
                level = 'Level'
                rank = 'Rank'
                if rank:len() < longest_rank then
                    repeat
                        rank = rank .. ' '
                    until rank:len() == longest_rank
                end
                xp = 'XP'
                if xp:len() < longest_xp then
                    repeat
                        xp = xp .. ' '
                    until xp:len() == longest_xp
                end
                heading = '| ' .. skill .. ' | ' .. level .. ' | ' .. rank .. ' | ' .. xp .. ' |'
            end
        end
    end
    table.insert(output, separator)
    output = table.concat(output, '\n')
    return output, heading
end

function runescape.on_message(_, message, _, language)
    local input = mattata.input(message.text)
    if not input then
        return mattata.send_reply(message, runescape.help)
    end
    local jstr, res = https.request('https://apps.runescape.com/runemetrics/profile/profile?user=' .. url.escape(input))
    if res ~= 200 then
        return mattata.send_reply(message, language.errors.connection)
    end
    local jdat = json.decode(jstr)
    if jdat.error or not jdat.skillvalues then
        local error_message = runescape.errors(jdat.error, language)
        return mattata.send_reply(message, error_message)
    end
    local output, heading = runescape.get_skill_info(jdat.skillvalues)
    output = string.format('<pre>%s\n%s</pre>', mattata.escape_html(heading), mattata.escape_html(output))
    return mattata.send_message(message.chat.id, output, 'html')
end

return runescape