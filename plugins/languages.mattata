--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local languages = {}
local mattata = require('mattata')

function languages:init()
    languages.commands = mattata.commands(self.info.username):command('languages').table
    languages.help = '/languages - Returns a list of languages that aren\'t currently supported by mattata, but are being spoken by users.'
end

function languages:on_message(message)
    local missing_languages = mattata.get_missing_languages()
    return mattata.send_message(
        message.chat.id,
        missing_languages
        and ('The following locales are languages my users speak that I do not currently have a translation file for:\n\n' .. missing_languages .. '\n\nIf you speak any of these languages well, and you are willing to volunteer your time into contributing to the development of mattata in the form of translating a file containing strings, please join https://t.me/mattataDev - thank you!')
        or 'At this moment in time, all of the languages spoken by my users have been translated, and can be selected by using /setlang!'
    )
end

return languages