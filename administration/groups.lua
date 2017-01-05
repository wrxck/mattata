--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]--

local groups = {}

local mattata = require('mattata')

function groups:init(configuration)
    groups.arguments = 'groups <search query>'
    groups.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('groups').table
    groups.help = configuration.command_prefix .. 'groups <search query> - If no arguments are given, a list of configured groups is sent; otherwise, a list of groups matching the given search query is sent instead.'
end

function groups:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    local groups = {}
    local results = {}
    for k, v in pairs(configuration.groups) do
        if v then
            local result = '• <a href="' .. v .. '">' .. mattata.escape_html(k) .. '</a>'
            table.insert(
                groups,
                result
            )
            if input and k:lower():match(input:lower()) then
                table.insert(
                    results,
                    result
                )
            end
        end
    end
    local output
    if #results > 0 then
        table.sort(results)
        output = '<b>Groups found matching:</b> ' .. mattata.escape_html(input) .. '\n' .. table.concat(results, '\n')
    elseif #groups > 0 then
        table.sort(groups)
        output = '<b>Groups:</b>\n' .. table.concat(groups, '\n')
    else
        output = language.errors.results
    end
    return mattata.send_message(
        message.chat.id,
        output,
        'html'
    )
end

return groups