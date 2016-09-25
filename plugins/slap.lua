local slap = {}
local functions = require('functions')
function slap:init(configuration)
	slap.command = 'slap (target)'
	slap.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('slap', true).table
	slap.doc = configuration.command_prefix .. 'slap (target) - Slap somebody (or something).'
end
function slap:action(msg, configuration)
	local slaps = configuration.slaps
	local input = functions.input(msg.text)
	local victor_id = msg.from.id
	local victim_id
	if msg.reply_to_message then
		victim_id = msg.reply_to_message.from.id
	else
		if input then
			if tonumber(input) then
				victim_id = tonumber(input)
			elseif input:match('^@') then
				local t = functions.resolve_username(self, input)
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
		if self.database.userdata[victim_id_str] and self.database.userdata[victim_id_str].nickname then
			victim_name = self.database.userdata[victim_id_str].nickname
		elseif self.database.users[victim_id_str] then
			victim_name = functions.build_name(self.database.users[victim_id_str].first_name, self.database.users[victim_id_str].last_name)
		else
			victim_name = victim_id_str
		end
	end
	local victor_id_str = tostring(victor_id)
	if self.database.userdata[victor_id_str] and self.database.userdata[victor_id_str].nickname then
		victor_name = self.database.userdata[victor_id_str].nickname
	elseif self.database.users[victor_id_str] then
		victor_name = functions.build_name(self.database.users[victor_id_str].first_name, self.database.users[victor_id_str].last_name)
	else
		victor_name = self.info.first_name
	end
	local output = functions.char.zwnj .. slaps[math.random(#slaps)]:gsub('VICTIM', victim_name):gsub('VICTOR', victor_name)
	functions.send_reply(msg, '`' .. output .. '`', true)
end
return slap