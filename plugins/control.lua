local control = {}
local mattata = require('mattata')
local functions = require('functions')
local command_prefix
function control:init(configuration)
	command_prefix = configuration.command_prefix
	control.triggers = functions.triggers(self.info.username, command_prefix, {'^'..command_prefix..'script'}):t('reboot', true):t('shutdown').table
end
function control:action(msg, configuration)
	if msg.from.id ~= configuration.owner_id then
		return
	end
	if msg.date < os.time() - 2 then
		return
	end
	if msg.text_lower:match('^' .. command_prefix .. 'reboot') then
		for pac, _ in pairs(package.loaded) do
			if pac:match('^plugins%.') then
				package.loaded[pac] = nil
			end
		end
		package.loaded['telegram_api'] = nil
		package.loaded['functions'] = nil
		package.loaded['configuration'] = nil
		if not msg.text_lower:match('%-configuration') then
			for k, v in pairs(require('configuration')) do
				configuration[k] = v
			end
		end
		mattata.init(self, configuration)
		functions.send_reply(msg, '*mattata is rebooting...*', true)
	elseif msg.text_lower:match('^'..command_prefix..'shutdown') then
		self.is_started = false
		functions.send_reply(msg, 'mattata is shutting down...')
	elseif msg.text_lower:match('^'..command_prefix..'script') then
		local input = msg.text_lower:match('^'..command_prefix..'script\n(.+)')
		if not input then
			functions.send_reply(msg, 'usage: ```\n'..command_prefix..'script\n'..command_prefix..'command <arg>\n...\n```', true)
			return
		end
		input = input .. '\n'
		for command in input:gmatch('(.-)\n') do
			command = functions.trim(command)
			msg.text = command
			mattata.on_msg_receive(msg, configuration)
		end
	end
end
return control