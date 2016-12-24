local help = {}
local mattata = require('mattata')
local https = require('ssl.https')
local url = require('socket.url')
local redis = require('mattata-redis')
local json = require('dkjson')

function help:init(configuration)
	help.argumentsList = {}
	for _, plugin in ipairs(self.plugins) do
		if plugin.arguments then
			table.insert(help.argumentsList, '• ' .. configuration.commandPrefix .. plugin.arguments)
			if plugin.help then plugin.helpWord = mattata.getWord(plugin.arguments, 1) end
		end
	end
	table.insert(help.argumentsList, '• ' .. configuration.commandPrefix .. 'help <plugin>')
	table.sort(help.argumentsList)
	help.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('help'):command('start').table
	help.help = configuration.commandPrefix .. 'help <plugin> - Usage information for the given plugin.'
end

function help.getPluginPage(argumentsList, page)
	local pluginCount = #argumentsList
	local pageBeginsAt = tonumber(page) * 10 - 9
	local pageEndsAt = tonumber(pageBeginsAt) + 9
	if tonumber(pageEndsAt) > tonumber(pluginCount) then pageEndsAt = tonumber(pluginCount) end
	local pagePlugins = {}
	for i = tonumber(pageBeginsAt), tonumber(pageEndsAt) do table.insert(pagePlugins, argumentsList[i]) end
	return table.concat(pagePlugins, '\n')
end

function help:onInlineQuery(inline_query, configuration)
	local results = json.encode({{
			type = 'article',
			id = '1',
			title = 'Begin typing to speak with ' .. self.info.first_name .. '!',
			description = '@' .. self.info.username .. ' <text> - Speak with ' .. self.info.first_name .. '!',
			input_message_content = { message_text = '@' .. self.info.username .. ' <text> - Speak with ' .. self.info.first_name .. '!' },
			thumb_url = 'http://matthewhesketh.com/mattata/mattata.png'
		},{
			type = 'article',
			id = '2',
			title = configuration.commandPrefix .. 'id',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'id <user/group> - Get information about a user/group.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'id <user/group> - Get information about a user/group.' },
			thumb_url = 'http://matthewhesketh.com/mattata/id.png'
		},{
			type = 'article',
			id = '3',
			title = configuration.commandPrefix .. 'apod',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'apod - Astronomical photo of the day, from NASA.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'apod - Astronomical photo of the day, from NASA.' },
			thumb_url = 'http://matthewhesketh.com/mattata/apod.jpg'
		},{
			type = 'article',
			id = '4',
			title = configuration.commandPrefix .. 'gif',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'gif <query> - Search for a gif on GIPHY.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'gif <query> - Search for a gif on GIPHY.' },
			thumb_url = 'http://matthewhesketh.com/mattata/giphy.png'
		},{
			type = 'article',
			id = '5',
			title = configuration.commandPrefix .. 'np',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'np - See what you last listened to on last.fm.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'np - See what you last listened to on last.fm.' },
			thumb_url = 'http://matthewhesketh.com/mattata/lastfm.png'
		},{
			type = 'article',
			id = '6',
			title = configuration.commandPrefix .. 'translate',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'translate <language> <text> - Translate text between different languages.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'translate <language> <text> - Translate text between different languages.' },
			thumb_url = 'http://matthewhesketh.com/mattata/translate.jpg'
		},{
			type = 'article',
			id = '7',
			title = configuration.commandPrefix .. 'lyrics',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'lyrics <song> - Get the lyrics to a song.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'lyrics <song> - Get the lyrics to a song.' },
			thumb_url = 'http://matthewhesketh.com/mattata/lyrics.png'
		},{
			type = 'article',
			id = '8',
			title = configuration.commandPrefix .. 'catfact',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'catfact - Discover something new about cats.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'catfact - Discover something new about cats.' },
			thumb_url = 'http://matthewhesketh.com/mattata/catfact.jpg'
		},{
			type = 'article',
			id = '9',
			title = configuration.commandPrefix .. 'ninegag',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'ninegag - View the latest images on 9gag.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'ninegag - View the latest images on 9gag.' },
			thumb_url = 'http://matthewhesketh.com/mattata/ninegag.png'
		},{
			type = 'article',
			id = '10',
			title = configuration.commandPrefix .. 'urban',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'urban <query> - Search the urban dictionary.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'urban <query> - Search the urban dictionary.' },
			thumb_url = 'http://matthewhesketh.com/mattata/urbandictionary.jpg'
		},{
			type = 'article',
			id = '11',
			title = configuration.commandPrefix .. 'cat',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'cat - Get a random photo of a cat. Meow!',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'cat - Get a random photo of a cat. Meow!' },
			thumb_url = 'http://matthewhesketh.com/mattata/cats.png'
		},{
			type = 'article',
			id = '12',
			title = configuration.commandPrefix .. 'flickr <query>',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'flickr <query> - Search for an image on Flickr.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'flickr <query> - Search for an image on Flickr.' },
			thumb_url = 'http://matthewhesketh.com/mattata/flickr.png'
		},{
			type = 'article',
			id = '13',
			title = configuration.commandPrefix .. 'location <query>',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'location <query> - Sends a location from Google Maps.',
			input_message_content = { message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'location <query> - Sends a location from Google Maps.' },
			thumb_url = 'http://matthewhesketh.com/mattata/location.png'
		}})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function help:onCallbackQuery(callback_query, message, configuration, language)
	if callback_query.data == 'commands' then
		local pluginCount = #help.argumentsList
		local pageCount = math.floor(tonumber(pluginCount) / 10) + 1
		local keyboard = {}
		keyboard.inline_keyboard = {{
			{ text = '◀️', callback_data = 'help:results:0' },
			{ text = '1/' .. pageCount, callback_data = 'help:pages:1:' .. pageCount },
			{ text = '▶️', callback_data = 'help:results:2' }
			},{{ text = 'Back', callback_data = 'help:back' }
		}}
		mattata.editMessageText(message.chat.id, message.message_id, help.getPluginPage(help.argumentsList, 1), nil, true, json.encode(keyboard))
	elseif callback_query.data:match('^results:(.-)$') then
		local newPage = callback_query.data:match('^results:(.-)$')
		local pluginCount = #help.argumentsList
		local pageCount = math.floor(tonumber(pluginCount) / 10) + 1
		if tonumber(newPage) > tonumber(pageCount) then
			newPage = 1
		elseif tonumber(newPage) < 1 then
			newPage = tonumber(pageCount)
		end
		local keyboard = {}
		keyboard.inline_keyboard = {{
			{ text = '◀️', callback_data = 'help:results:' .. math.floor(tonumber(newPage) - 1) },
			{ text = newPage .. '/' .. pageCount, callback_data = 'help:pages:' .. newPage .. ':' .. pageCount },
			{ text = '▶️', callback_data = 'help:results:' .. math.floor(tonumber(newPage) + 1) }
			},{{ text = 'Back', callback_data = 'help:back' }
		}}
		mattata.editMessageText(message.chat.id, message.message_id, help.getPluginPage(help.argumentsList, newPage), nil, true, json.encode(keyboard))
	elseif callback_query.data:match('^pages:(.-):(.-)$') then
		local currentPage, totalPages = callback_query.data:match('^pages:(.-):(.-)$')
		mattata.answerCallbackQuery(callback_query.id, 'You are on page ' .. currentPage .. ' of ' .. totalPages .. '!')
	elseif callback_query.data == 'administration' then
		local administrationHelpText = 'I take advantage of the administrative methods the Telegram bot API offers in the following ways:\n\nYou can <b>kick</b>, <b>ban</b> and <b>unban</b> users from groups you administrate by doing the following:\n\n- Add me to the group you want me to administrate, and grant me the necessary permissions to do my job by promoting me to an administrator. You\'ll know I\'m an administrator when you see a ⭐️ next to my name in the list of users.\n\nWhen the time comes to perform an administrative action, there are two ways to target the user:\n\n- You can specify the user by their @username (or their numerical ID) as an argument to the command - I then do some further checks to make sure the user you specified meets the necessary criteria (i.e. the user exists, they\'re present in the chat, and not an administrator) - don\'t worry, I\'m a bot, I can do this in no time at all!\n- You can target the user by replying to one of their messages with the desired action-corresponding command\n\n<i>If you specify the user by command arguments, but send the message as a reply, I will target the user you specified as the command arguments by default - which means the replied-to user will only be subject to the specified action when you send the command with nothing next to it!</i>'
		local keyboard = {}
		keyboard.inline_keyboard = {{{ text = 'Back', callback_data = 'help:back' }}}
		mattata.editMessageText(message.chat.id, message.message_id, administrationHelpText, 'HTML', true, json.encode(keyboard))
	elseif callback_query.data == 'links' then
		local helpLinks = language.officialLinks
		local keyboard = {}
		keyboard.inline_keyboard = {{
			{ text = 'Support', url = 'https://telegram.me/joinchat/DTcYUD7ELOondGVro-8PZQ' },
			{ text = 'Development', url = 'https://telegram.me/joinchat/DTcYUEDWD1IgrvQDrkKH0w' },
			{ text = 'Channel', url = 'https://telegram.me/mattata' }
			},{{ text = 'Source', url = 'https://github.com/matthewhesketh/mattata' },
			{ text = 'Donate', url = 'https://paypal.me/wrxck' },
			{ text = 'Rate', url = 'https://telegram.me/storebot?start=mattatabot' }
			},{{ text = 'Back', callback_data = 'help:back' }
		}}
		mattata.editMessageText(message.chat.id, message.message_id, helpLinks, 'Markdown', true, json.encode(keyboard))
	elseif callback_query.data == 'plugins' then
		local keyboard = {}
		keyboard.inline_keyboard = {{{ text = 'Back', callback_data = 'help:back' }}}
		mattata.editMessageText(message.chat.id, message.message_id, '<b>Hello, ' .. mattata.htmlEscape(message.reply_to_message.from.first_name) .. '!</b>\n\nTo disable a specific plugin, use \'' .. configuration.commandPrefix .. 'plugins disable &lt;plugin&gt;\'. To enable a specific plugin, use \'' .. configuration.commandPrefix .. 'plugins enable &lt;plugin&gt;\'.\n\nFor the sake of convenience, you can disable all of my non-core plugins by using \'' .. configuration.commandPrefix .. 'plugins enable all\'. To disable all of my non-core plugins, you can use \'' .. configuration.commandPrefix .. 'plugins disable all\'.\n\nTo see a list of plugins you\'ve disabled, use \'' .. configuration.commandPrefix .. 'plugins disabled\'. For a list of plugins that can be toggled and haven\'t been disabled in this chat yet, use \'' .. configuration.commandPrefix .. 'plugins enabled\'.\n\nA list of all toggleable plugins can be viewed by using \'' .. configuration.commandPrefix .. 'plugins list\'.', 'HTML', true, json.encode(keyboard))
	elseif callback_query.data == 'back' then
		local keyboard = {}
		keyboard.inline_keyboard = {{
			{ text = 'Links', callback_data = 'help:links' },
			{ text = 'Administration', callback_data = 'help:administration' },
			{ text = 'Commands', callback_data = 'help:commands' }
			},{{ text = 'Help', callback_data = 'help:help' },
			{ text = 'Plugins', callback_data = 'help:plugins' },
			{ text = 'About', callback_data = 'help:about' }
			},{{ text = 'Add me to a group!', url = 'https://telegram.me/' .. self.info.username .. '?startgroup=c' }
		}}
		mattata.editMessageText(message.chat.id, message.message_id, language.helpIntroduction:gsub('NAME', '*' .. mattata.markdownEscape(callback_query.from.first_name) .. '*'):gsub('MATTATA', self.info.first_name):gsub('COMMANDPREFIX', configuration.commandPrefix), 'Markdown', true, json.encode(keyboard))
	elseif callback_query.data == 'help' then
		local keyboard = {}
		keyboard.inline_keyboard = {{{ text = 'Back', callback_data = 'help:back' }}}
		mattata.editMessageText(message.chat.id, message.message_id, language.helpConfused:gsub('COMMANDPREFIX', configuration.commandPrefix), 'Markdown', true, json.encode(keyboard))
	elseif callback_query.data == 'about' then
		local keyboard = {}
		keyboard.inline_keyboard = {{{ text = 'Back', callback_data = 'help:back' }}}
		mattata.editMessageText(message.chat.id, message.message_id, language.helpAbout, 'Markdown', true, json.encode(keyboard))
	end
end

function help:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if input then
		for _, plugin in ipairs(self.plugins) do
			if plugin.helpWord == input:gsub('^' .. configuration.commandPrefix, '') then
				mattata.sendMessage(message.chat.id, '*Help for* ' .. mattata.markdownEscape(plugin.helpWord) .. '*:*\n' .. plugin.help, 'Markdown', true, false, message.message_id)
				return
			end
		end
		mattata.sendMessage(message.chat.id, language.noDocumentedHelp, 'Markdown', true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {{
		{ text = 'Links', callback_data = 'help:links' },
		{ text = 'Administration', callback_data = 'help:administration' },
		{ text = 'Commands', callback_data = 'help:commands' }
		},{{ text = 'Help', callback_data = 'help:help' },
		{ text = 'Plugins', callback_data = 'help:plugins' },
		{ text = 'About', callback_data = 'help:about' }
		},{{ text = 'Add me to a group!', url = 'https://telegram.me/' .. self.info.username .. '?startgroup=c' }
	}}
	mattata.sendMessage(message.chat.id, language.helpIntroduction:gsub('NAME', '*' .. mattata.markdownEscape(message.from.first_name) .. '*'):gsub('MATTATA', self.info.first_name):gsub('COMMANDPREFIX', configuration.commandPrefix), 'Markdown', true, false, message.message_id, json.encode(keyboard))
end

return help