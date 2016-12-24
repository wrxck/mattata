local control = {}
local mattata = require('mattata')

function control:init(configuration) control.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('reload'):command('reboot').table end

function control:onMessage(message, configuration)
	if not mattata.isConfiguredAdmin(message.from.id) then return end
	for p, _ in pairs(package.loaded) do if p:match('^plugins%.') then package.loaded[p] = nil end end
	package.loaded['mattata'] = nil
	package.loaded['configuration'] = nil
	if not message.text_lower:match('%-configuration') then for k, v in pairs(require('configuration')) do configuration[k] = v end end
	mattata.init(self, configuration)
	mattata.sendMessage(message.chat.id, self.info.first_name .. ' is reloading...', nil, true, false, message.message_id)
end

return control