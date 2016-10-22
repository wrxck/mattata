local slap = {}
local mattata = require('mattata')

function slap:init(configuration)
	slap.arguments = 'slap (target)'
	slap.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('slap', true).table
	slap.help = configuration.commandPrefix .. 'slap (target) - Slap somebody (or something).'
end

function slap:onMessageReceive(msg, configuration)
	local slaps = configuration.slaps
	local input = mattata.input(msg.text)
	local victor_id = msg.from.id
	local victim_id
	if msg.reply_to_message then
		victim_id = msg.reply_to_message.from.id
	else
		if input then
			if tonumber(input) then
				victim_id = tonumber(input)
			elseif input:match('^@') then
				local t = mattata.resUsername(self, input)
				if t then
					victim_id = t.id
				end
			end
		end
	end
	if victim_id then
		if victim_id == victor_id then
			victor_id = self.info.id
		end
	else
		if not input then
			victor_id = self.info.id
			victim_id = msg.from.id
		end
	end
	local victor_name, victim_name
	if input and not victim_id then
		victim_name = input
	else
		local victim_id_str = tostring(victim_id)
		if self.db.userdata[victim_id_str] and self.db.userdata[victim_id_str].nickname then
			victim_name = self.db.userdata[victim_id_str].nickname
		elseif self.db.users[victim_id_str] then
			victim_name = mattata.build_name(self.db.users[victim_id_str].first_name, self.db.users[victim_id_str].last_name)
		else
			victim_name = victim_id_str
		end
	end
	local victor_id_str = tostring(victor_id)
	if self.db.userdata[victor_id_str] and self.db.userdata[victor_id_str].nickname then
		victor_name = self.db.userdata[victor_id_str].nickname
	elseif self.db.users[victor_id_str] then
		victor_name = mattata.build_name(self.db.users[victor_id_str].first_name, self.db.users[victor_id_str].last_name)
	else
		victor_name = self.info.first_name
	end
	mattata.sendMessage(msg.chat.id, mattata.char.zwnj .. slaps[math.random(#slaps)]:gsub('VICTIM', victim_name):gsub('VICTOR', victor_name), nil, true, false, msg.message_id, nil)
end

return slap