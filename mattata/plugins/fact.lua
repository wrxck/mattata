-- created by wrxck
local fact = {}
local JSON = require('dkjson')
local utilities = require('mattata.utilities')
local URL = require('socket.url')
local HTTP = require('socket.http')

function fact:init(config)
    fact.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('fact', true):t('didyouknow', true).table
    fact.command = 'fact'
    fact.doc = 'Returns a random fact!'
end

function fact:action(msg, config)
    local url = 'http://mentalfloss.com/api/1.0/views/amazing_facts.json?limit=5000'
    local jstr = HTTP.request(url)
    local jdat = JSON.decode(jstr)
    if jdat.error then
        utilities.send_reply(self, msg, config.errors.results)
        return
    end
    local math = math.random(#jdat)
    local output = jdat[math].nid:gsub('<p>',''):gsub('</p>',''):gsub('&amp;','&'):gsub('<em>',''):gsub('</em>',''):gsub('<strong>',''):gsub('</strong>','')
    utilities.send_message(self, msg.chat.id, output, nil, true)
end

return fact