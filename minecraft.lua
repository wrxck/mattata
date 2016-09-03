local minecraft = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local ltn12 = require("ltn12")
local functions = require('mattata.functions')
function minecraft:init(configuration)
    minecraft.command = "minecraft <server IP:port>"
    minecraft.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('minecraft', true).table
    minecraft.doc = configuration.command_prefix .. [[minecraft <server IP:port> Checks and returns the current status of the given Minecraft server IP on the given port.]]
end
function minecraft:action(msg, configuration)
    input = functions.input(msg.text):gsub(":", "&port=")
    jstr = HTTP.request("http://api.syfaro.net/server/status?ip=".. input .."&players=true&favicon=false")
    jdat = JSON.decode(jstr)
    motd = jdat.motd:gsub("§a", ""):gsub("§b", ""):gsub("§c", ""):gsub("§d", ""):gsub("§e", ""):gsub("§f", ""):gsub("§k", ""):gsub("§l", ""):gsub("§m", ""):gsub("§n", ""):gsub("§o", ""):gsub("§r", ""):gsub("§0", ""):gsub("§1", ""):gsub("§2", ""):gsub("§3", ""):gsub("§4", ""):gsub("§5", ""):gsub("§6", ""):gsub("§7", ""):gsub("§8", ""):gsub("§9", ""):gsub("           ", " "):gsub("          ", " "):gsub("         ", " "):gsub("        ", " "):gsub("       ", " "):gsub("      ", " "):gsub("     ", " "):gsub("    ", " "):gsub("   ", " "):gsub("  ", " ")
    currentplayers = jdat.players.now
    maxplayers = jdat.players.max
    serverversion = jdat.server.name
    serverprotocol = jdat.server.protocol
    if input ~= nil then
        functions.send_message(self, msg.chat.id, "*MOTD:* "..motd.."\n".."*Minecraft version:* "..serverversion.."\n".."*Protocol version:* "..serverprotocol.."\n".."*Players: *"..currentplayers.."*/*"..maxplayers, true, nil, true)
    else
        functions.send_reply(self, msg, "Please enter an IP and port in the format IP:PORT.")
    end
end
return minecraft