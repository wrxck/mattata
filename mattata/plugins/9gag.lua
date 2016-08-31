-- created by wrxck, largely modified, but based on a plugin by brawl
-- by sending the output as a link preview rather than a file, we reduce loading time

local HTTP = require('socket.http')
local JSON = require('dkjson')
local functions = require('mattata.functions')
local telegram_api = require('mattata.telegram_api')

local ninegag = {}

function ninegag:init(configuration)
    ninegag.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('9gag', true).table
    ninegag.command = '9gag'
    ninegag.doc = configuration.command_prefix .. [[9gag ...
Returns a random image from the latest 9gag posts.
    ]]
end

function ninegag:action(msg, configuration)
    local url = "http://api-9gag.herokuapp.com/"
    local jstr, res = HTTP.request(url)
    if res ~= 200 then
        functions.send_reply(self, msg, configuration.errors.connection)
        return
    end
    local jstr = HTTP.request(url)
    local jdat = JSON.decode(jstr)
    local math = math.random(#jdat)
    local random = jdat[math].src
    local output = '[XD]('..random..')'
    functions.send_message(self, msg.chat.id, output, false, true)
end

return ninegag
