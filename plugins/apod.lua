local apod = {}
local mattata = require('mattata')
local https = require('ssl.https')
local json = require('dkjson')

function apod:init(configuration)
    assert(
        configuration.keys.apod,
        'apod.lua requires an API key, and you haven\'t got one configured!'
    )
    apod.arguments = 'apod <DD/MM/YYYY>'
    apod.commands = mattata.commands(
        self.info.username,
        configuration.command_prefix
    ):command('apod').table
    apod.help = '/apod <DD/MM/YYYY> - Sends the Astronomy Picture of the Day.'
end

function apod:on_inline_query(inline_query, configuration)
    local jstr, res = https.request('https://api.nasa.gov/planetary/apod?api_key=' .. configuration.keys.apod)
    if res ~= 200 then
        return
    end
    local jdat = json.decode('[' .. jstr .. ']')
    return mattata.answer_inline_query(
        inline_query.id,
        json.encode(
            {
                {
                    ['type'] = 'photo',
                    ['id'] = '1',
                    ['photo_url'] = jdat[1].url,
                    ['thumb_url'] = jdat[1].url,
                    ['caption'] = jdat[1].title:gsub('"', '\\"')
                }
            }
        )
    )
end

function apod:on_message(message, configuration, language)
    local input = mattata.input(message.text)
    local url = 'https://api.nasa.gov/planetary/apod?api_key=' .. configuration.keys.apod
    local date = os.date('%Y-%m-%d')
    if input and input:match('^(%d%d)/(%d%d)/(%d%d%d%d)$') then
        local day, month, year = input:match('^(%d%d)/(%d%d)/(%d%d%d%d)$')
        url = url .. year .. '-' .. month .. '-' .. day
        date = input
    end
    local jstr, res = https.request(url)
    if res ~= 200 then
        return mattata.send_reply(
            message,
            language.errors.connection
        )
    end
    local jdat = json.decode(jstr)
    local year, month, day = jdat.date:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    mattata.send_chat_action(
        message.chat.id,
        'upload_photo'
    )
    return mattata.send_photo(
        message.chat.id,
        jdat.url,
        '\'' .. jdat.title .. '\' - ' .. day .. '/' .. month .. '/' .. year
    )
end

return apod