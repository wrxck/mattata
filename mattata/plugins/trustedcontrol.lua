local trustedcontrol = {}
local bot = require('mattata.bot')
local functions = require('mattata.functions')
local command_prefix
function trustedcontrol:init(configuration)
	command_prefix = configuration.command_prefix
	trustedcontrol.triggers = functions.triggers(self.info.username, command_prefix,
		{'^'..command_prefix..'script'}):t('treboot', true):t('thalt').table
end
function trustedcontrol:action(msg, configuration)
    if msg.from.id ~= configuration.trusted then
        return
    end
    if msg.date < os.time() - 2 then return end
    if msg.text_lower:match('^'..command_prefix..'treboot') then
        for pac, _ in pairs(package.loaded) do
            if pac:match('^mattata%.plugins%.') then
                package.loaded[pac] = nil
            end
        end
        package.loaded['mattata.telegram_api'] = nil
        package.loaded['mattata.functions'] = nil
        package.loaded['mattata.drua-tg'] = nil
        package.loaded['configuration'] = nil
        if not msg.text_lower:match('%-configuration') then
            for k, v in pairs(require('configuration')) do
                configuration[k] = v
            end
        end
        bot.init(self, configuration)
        functions.send_reply(self, msg, 'mattata is being rebooted...')
        functions.send_message(self, msg.chat.id, 'mattata has successfully been rebooted!')
    elseif msg.text_lower:match('^'..command_prefix..'thalt') then
        self.is_started = false
        functions.send_reply(self, msg, 'mattata is shutting down...')
    elseif msg.text_lower:match('^'..command_prefix..'script') then
        local input = msg.text_lower:match('^'..command_prefix..'script\n(.+)')
        if not input then
            functions.send_reply(self, msg, 'usage: ```\n'..command_prefix..'script\n'..command_prefix..'command <arg>\n...\n```', true)
            return
        end
        input = input .. '\n'
        for command in input:gmatch('(.-)\n') do
            command = functions.trim(command)
            msg.text = command
            bot.on_msg_receive(self, msg, configuration)
        end
    end
end
return trustedcontrol