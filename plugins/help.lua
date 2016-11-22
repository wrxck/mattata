local help = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local redis = require('mattata-redis')
local JSON = require('dkjson')
local helpText, administrationHelpText, users

function help:init(configuration)
	local argumentsList = {}
	helpText = '• ' .. configuration.commandPrefix
	for _, plugin in ipairs(self.plugins) do
		if plugin.arguments then
			table.insert(argumentsList, plugin.arguments)
			if plugin.help then
				plugin.helpWord = mattata.getWord(plugin.arguments, 1)
			end
		end
	end
	table.insert(argumentsList, 'help <plugin>')
	table.sort(argumentsList)
	helpText = helpText .. table.concat(argumentsList, '\n• ' .. configuration.commandPrefix)
	local administrationArgumentsList = {}
	administrationHelpText = 'I utilise the administration methods the Telegram bot API supports, feel free to set me as an administrator in your group to gain access to the following commands:\n\n• ' .. configuration.commandPrefix
	for _, administrationPlugin in ipairs(self.administrationPlugins) do
		if administrationPlugin.arguments then
			table.insert(administrationArgumentsList, administrationPlugin.arguments)
			if administrationPlugin.help then
				administrationPlugin.helpWord = mattata.getWord(administrationPlugin.arguments, 1)
			end
		end
	end
	table.sort(administrationArgumentsList)
	administrationHelpText = administrationHelpText .. table.concat(administrationArgumentsList, '\n• ' .. configuration.commandPrefix)
	help.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('help'):c('start').table
	help.help = configuration.commandPrefix .. 'help <plugin> - Usage information for the given plugin.'
	users = self.users
end

function help:onInlineQuery(inline_query, configuration)
	local results = JSON.encode({
		{
			type = 'article',
			id = '1',
			title = 'Begin typing to speak with ' .. self.info.first_name .. '!',
			description = '@' .. self.info.username .. ' <text> - Speak with ' .. self.info.first_name .. '!',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' <text> - Speak with ' .. self.info.first_name .. '!'
			},
			thumb_url = 'http://matthewhesketh.com/images/mattata.png'
		},
		{
			type = 'article',
			id = '2',
			title = configuration.commandPrefix .. 'id',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'id <user/group> - Get information about a user/group.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'id <user/group> - Get information about a user/group.'
			},
			thumb_url = 'http://matthewhesketh.com/images/id.png'
		},
		{
			type = 'article',
			id = '3',
			title = configuration.commandPrefix .. 'apod',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'apod - Astronomical photo of the day, from NASA.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'apod - Astronomical photo of the day, from NASA.'
			},
			thumb_url = 'http://matthewhesketh.com/images/apod.jpg'
		},
		{
			type = 'article',
			id = '4',
			title = configuration.commandPrefix .. 'gif',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'gif <query> - Search for a gif on GIPHY.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'gif <query> - Search for a gif on GIPHY.'
			},
			thumb_url = 'http://matthewhesketh.com/images/giphy.png'
		},
		{
			type = 'article',
			id = '5',
			title = configuration.commandPrefix .. 'np',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'np - See what you last listened to on last.fm.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'np - See what you last listened to on last.fm.'
			},
			thumb_url = 'http://matthewhesketh.com/images/lastfm.png'
		},
		{
			type = 'article',
			id = '6',
			title = configuration.commandPrefix .. 'translate',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'translate <language> <text> - Translate text between different languages.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'translate <language> <text> - Translate text between different languages.'
			},
			thumb_url = 'http://matthewhesketh.com/images/translate.jpg'
		},
		{
			type = 'article',
			id = '7',
			title = configuration.commandPrefix .. 'lyrics',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'lyrics <song> - Get the lyrics to a song.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'lyrics <song> - Get the lyrics to a song.'
			},
			thumb_url = 'http://matthewhesketh.com/images/lyrics.png'
		},
		{
			type = 'article',
			id = '8',
			title = configuration.commandPrefix .. 'bandersnatch',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'bandersnatch - Generate a new, weird and wacky name!',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'bandersnatch - Generate a new, weird and wacky name!'
			},
			thumb_url = 'http://matthewhesketh.com/images/bandersnatch.jpg'
		},
		{
			type = 'article',
			id = '9',
			title = configuration.commandPrefix .. 'catfact',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'catfact - Discover something new about cats.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'catfact - Discover something new about cats.'
			},
			thumb_url = 'http://matthewhesketh.com/images/catfact.jpg'
		},
		{
			type = 'article',
			id = '10',
			title = configuration.commandPrefix .. '9gag',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. '9gag - View the latest images on 9gag.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. '9gag - View the latest images on 9gag.'
			},
			thumb_url = 'http://matthewhesketh.com/images/9gag.png'
		},
		{
			type = 'article',
			id = '11',
			title = configuration.commandPrefix .. 'urban',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'urban <query> - Search the urban dictionary.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'urban <query> - Search the urban dictionary.'
			},
			thumb_url = 'http://matthewhesketh.com/images/urbandictionary.jpg'
		},
		{
			type = 'article',
			id = '12',
			title = configuration.commandPrefix .. 'cat',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'cat - Get a random photo of a cat. Meow!',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'cat - Get a random photo of a cat. Meow!',
			},
			thumb_url = 'http://matthewhesketh.com/images/cats.png'
		},
		{
			type = 'article',
			id = '13',
			title = configuration.commandPrefix .. 'flickr <query>',
			description = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'flickr <query> - Search for an image on Flickr.',
			input_message_content = {
				message_text = '@' .. self.info.username .. ' ' .. configuration.commandPrefix .. 'flickr <query> - Search for an image on Flickr.',
			},
			thumb_url = 'http://matthewhesketh.com/images/flickr.png'
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function help:onCallback(callback, message, configuration, language)
	if callback.data == 'helpCommands' then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'Back',
					callback_data = 'helpBack'
				}
			}
		}
		if message.chat.type ~= 'private' then
			local res = mattata.sendMessage(callback.from.id, helpText, 'Markdown', true, false)
			if not res then
				mattata.editMessageText(message.chat.id, message.message_id, language.pleaseMessageMe:gsub('MATTATA', self.info.username), 'Markdown', true, JSON.encode(keyboard))
			else
				mattata.editMessageText(message.chat.id, message.message_id, language.sentPrivateMessage, nil, true, JSON.encode(keyboard))
			end
		else
			mattata.editMessageText(message.chat.id, message.message_id, helpText, 'Markdown', true, JSON.encode(keyboard))
		end
	end
	if callback.data == 'helpAdministration' then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'Back',
					callback_data = 'helpBack'
				}
			}
		}
		if message.chat.type ~= 'private' then
			local res = mattata.sendMessage(callback.from.id, administrationHelpText, 'Markdown', true, false)
			if not res then
				mattata.editMessageText(message.chat.id, message.message_id, language.pleaseMessageMe:gsub('MATTATA', self.info.username), 'Markdown', true, JSON.encode(keyboard))
			else
				mattata.editMessageText(message.chat.id, message.message_id, language.sentPrivateMessage, nil, true, JSON.encode(keyboard))
			end
		else
			mattata.editMessageText(message.chat.id, message.message_id, administrationHelpText, 'Markdown', true, JSON.encode(keyboard))
		end
	end
	if callback.data == 'helpLinks' then
		local helpLinks = language.officialLinks
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'Group',
					url = 'https://telegram.me/mattata'
				},
				{
					text = 'Channel',
					url = 'https://telegram.me/mattataofficial'
				},
				{
					text = 'GitHub',
					url = 'https://github.com/matthewhesketh/mattata'
				}
			},
			{
				{
					text = 'Donate',
					url = 'https://paypal.me/wrxck'
				},
				{
					text = 'Rate',
					url = 'https://telegram.me/storebot?start=mattatabot'
				}
			},
			{
				{
					text = 'Back',
					callback_data = 'helpBack'
				}
			}
		}
		mattata.editMessageText(message.chat.id, message.message_id, helpLinks, 'Markdown', true, JSON.encode(keyboard))
	end
	if callback.data == 'helpBack' then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'Links',
					callback_data = 'helpLinks'
				},
				{
					text = 'Administration',
					callback_data = 'helpAdministration'
				},
				{
					text = 'Commands',
					callback_data = 'helpCommands'
				}
			},
			{
				{
					text = 'Help',
					callback_data = 'helpHelp'
				},
				{
					text = 'About',
					callback_data = 'helpAbout'
				}
			}
		}
		mattata.editMessageText(message.chat.id, message.message_id, language.helpIntroduction:gsub('NAME', '*' .. mattata.markdownEscape(callback.from.first_name) .. '*'):gsub('MATTATA', self.info.first_name):gsub('COMMANDPREFIX', configuration.commandPrefix), 'Markdown', true, JSON.encode(keyboard))
	end
	if callback.data == 'helpHelp' then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'Back',
					callback_data = 'helpBack'
				}
			}
		}
		mattata.editMessageText(message.chat.id, message.message_id, language.helpConfused:gsub('COMMANDPREFIX', configuration.commandPrefix), 'Markdown', true, JSON.encode(keyboard))
	end
	if callback.data == 'helpAbout' then
		local keyboard = {}
		keyboard.inline_keyboard = {
			{
				{
					text = 'Back',
					callback_data = 'helpBack'
				}
			}
		}
		mattata.editMessageText(message.chat.id, message.message_id, language.helpAbout, 'Markdown', true, JSON.encode(keyboard))
	end
end

function help:onChannelPost(channel_post, configuration)
	local language = require('languages/en')
	local input = mattata.input(channel_post.text)
	if input then
		for _, plugin in ipairs(self.plugins) do
			if plugin.helpWord == input:gsub('^/', '') then
				mattata.sendMessage(channel_post.chat.id, '*Help for* ' .. mattata.markdownEscape(plugin.helpWord) .. '*:*\n' .. plugin.help, 'Markdown', true, false, channel_post.message_id)
				return
			end
		end
		mattata.sendMessage(channel_post.chat.id, language.noDocumentedHelp, nil, true, false, channel_post.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Links',
				callback_data = 'helpLinks'
			},
			{
				text = 'Administration',
				callback_data = 'helpAdministration'
			},
			{
				text = 'Commands',
				callback_data = 'helpCommands'
			}
		},
		{
			{
				text = 'Help',
				callback_data = 'helpHelp'
			},
			{
				text = 'About',
				callback_data = 'helpAbout'
			}
		}
	}
	mattata.sendMessage(channel_post.chat.id, language.helpIntroduction:gsub('NAME', '*friend*'):gsub('MATTATA', self.info.first_name):gsub('COMMANDPREFIX', configuration.commandPrefix), 'Markdown', true, false, nil, JSON.encode(keyboard))
end

function help:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if input then
		for _, plugin in ipairs(self.plugins) do
			if plugin.helpWord == input:gsub('^/', '') then
				mattata.sendMessage(message.chat.id, '*Help for* ' .. mattata.markdownEscape(plugin.helpWord) .. '*:*\n' .. plugin.help, 'Markdown', true, false, message.message_id)
				return
			end
		end
		mattata.sendMessage(message.chat.id, language.noDocumentedHelp, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Links',
				callback_data = 'helpLinks'
			},
			{
				text = 'Administration',
				callback_data = 'helpAdministration'
			},
			{
				text = 'Commands',
				callback_data = 'helpCommands'
			}
		},
		{
			{
				text = 'Help',
				callback_data = 'helpHelp'
			},
			{
				text = 'About',
				callback_data = 'helpAbout'
			}
		}
	}
	mattata.sendMessage(message.chat.id, language.helpIntroduction:gsub('NAME', '*' .. mattata.markdownEscape(message.from.first_name) .. '*'):gsub('MATTATA', self.info.first_name):gsub('COMMANDPREFIX', configuration.commandPrefix), 'Markdown', true, false, nil, JSON.encode(keyboard))
end

return help