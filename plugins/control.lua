local control = {}
local mattata = require('mattata')
local mattata = require('mattata')

function control:init(configuration)
	control.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('reload', true).table
end

function control:onMessageReceive(msg, configuration)
	if msg.from.id ~= configuration.owner then
		return
	end
	for pac, _ in pairs(package.loaded) do
		if pac:match('^plugins%.') then
				package.loaded[pac] = nil
		end
	end
	package.loaded['mattata'] = nil
	package.loaded['mattata'] = nil
	package.loaded['configuration'] = nil
	if not msg.text_lower:match('%-configuration') then
		for k, v in pairs(require('configuration')) do
			configuration[k] = v
		end
	end
	mattata.init(self, configuration)
	print(self.info.first_name .. ' is reloading...')
	mattata.sendMessage(msg.chat.id, self.info.first_name .. ' is reloading...', nil, true, false, msg.message_id, nil)
end

return control