local reactions = {}

local utilities = require('mattata.utilities')

reactions.command = 'reactions'
reactions.doc = 'Returns a list of "reaction" emoticon commands.'

local mapping = {
	['shrug'] = '¯\\_(ツ)_/¯',
	['lenny'] = '( ͡° ͜ʖ ͡°)',
	['flip'] = '(╯°□°）╯︵ ┻━┻',
	['homo'] = '┌（┌　＾o＾）┐',
	['look'] = 'ಠ_ಠ',
	['shots?'] = 'SHOTS FIRED',
	['facepalm'] = '(－‸ლ)',
	['floofy'] = '.3.',
	['donger'] = '༼ つ ◕_◕ ༽つ',
}

local help

function reactions:init(config)

	help = 'Reactions:\n'
	reactions.triggers = utilities.triggers(self.info.username, config.cmd_pat):t('reactions').table
	local username = self.info.username:lower()
	for trigger,reaction in pairs(mapping) do
		help = help .. '• ' .. config.cmd_pat .. trigger:gsub('.%?', '') .. ': ' .. reaction .. '\n'
		table.insert(reactions.triggers, '^'..config.cmd_pat..trigger)
		table.insert(reactions.triggers, '^'..config.cmd_pat..trigger..'@'..username)
		table.insert(reactions.triggers, config.cmd_pat..trigger..'$')
		table.insert(reactions.triggers, config.cmd_pat..trigger..'@'..username..'$')
		table.insert(reactions.triggers, '\n'..config.cmd_pat..trigger)
		table.insert(reactions.triggers, '\n'..config.cmd_pat..trigger..'@'..username)
		table.insert(reactions.triggers, config.cmd_pat..trigger..'\n')
		table.insert(reactions.triggers, config.cmd_pat..trigger..'@'..username..'\n')
	end
end

function reactions:action(msg, config)
	if string.match(msg.text_lower, config.cmd_pat..'reactions') then
		utilities.send_message(self, msg.chat.id, help)
		return
	end
	for trigger,reaction in pairs(mapping) do
		if string.match(msg.text_lower, config.cmd_pat..trigger) then
			utilities.send_message(self, msg.chat.id, reaction)
			return
		end
	end
end

return reactions
