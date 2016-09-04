local minecraft = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local functions = require('functions')
function minecraft:init(configuration)
    minecraft.command = 'minecraft <server IP>'
    minecraft.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('minecraft', true).table
    minecraft.doc = configuration.command_prefix .. 'minecraft <server IP> \nSends information about the given Minecraft server IP.'
end
function minecraft:action(msg, configuration)
    local input = functions.input(msg.text)
    if not input then
        if msg.reply_to_message and msg.reply_to_message.text then
            input = msg.reply_to_message.text
        else
            functions.send_message(self, msg.chat.id, minecraft.doc, true, msg.message_id, true)
            return
        end
    end
    local url = 'http://api.syfaro.net/server/status?ip='..input..'&port=25565&players=true&favicon=false'
    local jstr = HTTP.request(url)
    local jdat = JSON.decode(jstr)
    local output = '*MOTD:*' .. '```' .. jdat.motd:gsub("§a", ""):gsub("§b", ""):gsub("§c", ""):gsub("§d", ""):gsub("§e", ""):gsub("§f", ""):gsub("§k", ""):gsub("§l", ""):gsub("§m", ""):gsub("§n", ""):gsub("§o", ""):gsub("§r", ""):gsub("§0", ""):gsub("§1", ""):gsub("§2", ""):gsub("§3", ""):gsub("§4", ""):gsub("§5", ""):gsub("§6", ""):gsub("§7", ""):gsub("§8", ""):gsub("§9", ""):gsub("\n", " "):gsub("             ", " "):gsub("            ", " "):gsub("           ", " "):gsub("          ", " "):gsub("         ", " "):gsub("        ", " "):gsub("       ", " "):gsub("      ", " "):gsub("     ", " "):gsub("    ", " "):gsub("   ", " "):gsub("  ", " "):gsub(" ", " ") .. '```' .. '\n*Players:*  ' .. '```' .. jdat.players.now .. '```' .. '*/*' .. '```' .. jdat.players.max .. '```' .. '\n*Version:*  ' .. '```' .. jdat.server.name .. '```' .. '\n*Protocol:*  ' .. '```' .. jdat.server.protocol .. '```'
    functions.send_message(self, msg.chat.id, output, true, nil, true)
end
return minecraft