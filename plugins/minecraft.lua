local minecraft = {}
local HTTP = require('socket.http')
local JSON = require('dkjson')
local mattata = require('mattata')

function minecraft:init(configuration)
	minecraft.arguments = 'minecraft <server IP> <port>'
	minecraft.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('minecraft', true).table
	minecraft.help = configuration.commandPrefix .. 'minecraft <server IP> <port> - Sends information about the given Minecraft server IP.'
end

function minecraft:onMessageReceive(msg, configuration)
	local input = mattata.input(msg.text)
	if not input then
		mattata.sendMessage(msg.chat.id, minecraft.help, nil, true, false, msg.message_id, nil)
		return
	end
	local url = configuration.apis.minecraft .. input:gsub(' ', '&port=') .. '&players=true&favicon=false'
	local jstr, res = HTTP.request(url)
	if res ~= 200 then
		mattata.sendMessage(msg.chat.id, configuration.errors.connection, nil, true, false, msg.message_id, nil)
		return
	end
	local jdat = JSON.decode(jstr)
	local output = '*'..jdat.motd:gsub("§a", ""):gsub("§b", ""):gsub("§c", ""):gsub("§d", ""):gsub("§e", ""):gsub("§f", ""):gsub("§k", ""):gsub("§l", ""):gsub("§m", ""):gsub("§n", ""):gsub("§o", ""):gsub("§r", ""):gsub("§0", ""):gsub("§1", ""):gsub("§2", ""):gsub("§3", ""):gsub("§4", ""):gsub("§5", ""):gsub("§6", ""):gsub("§7", ""):gsub("§8", ""):gsub("§9", ""):gsub("\n", " "):gsub("			 ", " "):gsub("			", " "):gsub("		   ", " "):gsub("		  ", " "):gsub("		 ", " "):gsub("		", " "):gsub("	   ", " "):gsub("	  ", " "):gsub("	 ", " "):gsub("	", " "):gsub("   ", " "):gsub("  ", " "):gsub(" ", " ") .. '*\n\n*Players*: ' .. '_' .. jdat.players.now .. '_' .. '_/_' .. '_' .. jdat.players.max .. '_' .. '\n*Version*: ' .. '_' .. jdat.server.name .. '_' .. '\n*Protocol*: ' .. '_' .. jdat.server.protocol .. '_'
	mattata.sendMessage(msg.chat.id, output, 'Markdown', true, false, msg.message_id, nil)
end

return minecraft