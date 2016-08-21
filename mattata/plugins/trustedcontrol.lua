local trustedcontrol = {}

local bot = require('mattata.bot')
local utilities = require('mattata.utilities')

local cmd_pat

function trustedcontrol:init(config)
	cmd_pat = config.cmd_pat
	trustedcontrol.triggers = utilities.triggers(self.info.username, cmd_pat,
		{'^'..cmd_pat..'script'}):t('treboot', true):t('thalt').table
end

function trustedcontrol:action(msg, config)
    if msg.from.id ~= config.trusted then
        return
    end
    if msg.date < os.time() - 2 then return end
    if msg.text_lower:match('^'..cmd_pat..'treboot') then
        for pac, _ in pairs(package.loaded) do
            if pac:match('^mattata%.plugins%.') then
                package.loaded[pac] = nil
            end
        end
        package.loaded['mattata.bindings'] = nil
        package.loaded['mattata.utilities'] = nil
        package.loaded['mattata.drua-tg'] = nil
        package.loaded['config'] = nil
        if not msg.text_lower:match('%-config') then
            for k, v in pairs(require('config')) do
                config[k] = v
            end
        end
        bot.init(self, config)
        utilities.send_reply(self, msg, 'mattata is being rebooted...')
        utilities.send_message(self, msg.chat.id, 'mattata has successfully been rebooted!')
    elseif msg.text_lower:match('^'..cmd_pat..'thalt') then
        self.is_started = false
        utilities.send_reply(self, msg, 'mattata is shutting down...')
    elseif msg.text_lower:match('^'..cmd_pat..'script') then
        local input = msg.text_lower:match('^'..cmd_pat..'script\n(.+)')
        if not input then
            utilities.send_reply(self, msg, 'usage: ```\n'..cmd_pat..'script\n'..cmd_pat..'command <arg>\n...\n```', true)
            return
        end
        input = input .. '\n'
        for command in input:gmatch('(.-)\n') do
            command = utilities.trim(command)
            msg.text = command
            bot.on_msg_receive(self, msg, config)
        end
    end
end

return trustedcontrol