-- created by wrxck, largely modified, but based on a plugin by brawl
-- by sending the output as a link preview rather than a file, we reduce loading time

local HTTP = require('socket.http')
local JSON = require('dkjson')
local utilities = require('mattata.utilities')
local bindings = require('mattata.bindings')

local ninegag = {}

function ninegag:init(config)
    ninegag.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('9gag', true).table
    ninegag.command = '9gag'
    ninegag.doc = config.cmd_pat .. [[9gag ...
Returns a random image from the latest 9gag posts.
    ]]
end

function ninegag:action(msg, config)
    local url = "http://api-9gag.herokuapp.com/"
    local jstr, res = HTTP.request(url)
    if res ~= 200 then
        utilities.send_reply(self, msg, config.errors.connection)
        return
    end
    local jstr = HTTP.request(url)
    local jdat = JSON.decode(jstr)
    local math = math.random(#jdat)
    local random = jdat[math].src
    local output = '[XD]('..random..')'
    utilities.send_message(self, msg.chat.id, output, false, true)
end

return ninegag