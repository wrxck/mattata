local trump = {}
local mattata = require('mattata')

function trump:init(configuration)
	trump.arguments = 'trump (target)'
	trump.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('trump', true).table
	trump.help = configuration.commandPrefix .. 'trump (target) - trump somebody (or something).'
end

function trump:onMessageReceive(msg, configuration)
	local trumps = configuration.trumps
	local input = mattata.input(msg.text)
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
		if self.db.userdata[victim_id_str] and self.db.userdata[victim_id_str].nickname then
			victim_name = self.db.userdata[victim_id_str].nickname
		elseif self.db.users[victim_id_str] then
			victim_name = mattata.build_name(self.db.users[victim_id_str].first_name, self.db.users[victim_id_str].last_name)
		else
			victim_name = victim_id_str
		end
	end
	mattata.sendMessage(msg.chat.id, mattata.char.zwnj .. trumps[math.random(#trumps)]:gsub('VICTIM', victim_name) .. ' - Donald J. Trump', nil, true, false, msg.message_id, nil)
end

return trump