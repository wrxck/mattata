local trump = {}
local functions = require('functions')
function trump:init(configuration)
	trump.command = 'trump (target)'
	trump.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('trump', true).table
	trump.documentation = configuration.command_prefix .. 'trump (target) - trump somebody (or something).'
end
function trump:action(msg, configuration)
	local trumps = configuration.trumps
	local input = functions.input(msg.text)
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
	if not victim_id then
		if not input then
			victim_id = msg.from.id
		end
	end
	local victim_name
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
	functions.send_reply(msg, functions.char.zwnj .. trumps[math.random(#trumps)]:gsub('VICTIM', victim_name) .. ' - Donald J. Trump')
end
return trump