local groups = {}
local mattata = require('mattata')

function groups:init(configuration)
	groups.arguments = 'groups <search query>'
	groups.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('groups').table
	groups.help = configuration.commandPrefix .. 'groups <search query> - If no arguments are given, a list of configured groups is sent; otherwise, a list of groups matching the given search query is sent instead.'
end

function groups:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	local groups = {}
	local results = {}
	for group, link in pairs(configuration.groups) do
		if link then
			local result = '• [' .. mattata.markdownEscape(group) .. '](' .. link .. ')'
			table.insert(groups, result)
			if input and string.match(group:lower(), input:lower()) then
				table.insert(results, result)
			end
		end
	end
	local output
	if #results > 0 then
		table.sort(results)
		output = '*Groups found matching* ' .. mattata.markdownEscape(input) .. '*:*\n' .. table.concat(results, '\n')
	elseif #groups > 0 then
		table.sort(groups)
		output = '*Groups:*\n' .. table.concat(groups, '\n')
	else
		output = configuration.errors.results
	end
	mattata.sendMessage(channel_post.chat.id, output, 'Markdown', true, false, channel_post.message_id)
end

function groups:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	local groups = {}
	local results = {}
	for group, link in pairs(configuration.groups) do
		if link then
			local result = '• [' .. mattata.markdownEscape(group) .. '](' .. link .. ')'
			table.insert(groups, result)
			if input and string.match(group:lower(), input:lower()) then
				table.insert(results, result)
			end
		end
	end
	local output
	if #results > 0 then
		table.sort(results)
		output = '*Groups found matching* ' .. mattata.markdownEscape(input) .. '*:*\n' .. table.concat(results, '\n')
	elseif #groups > 0 then
		table.sort(groups)
		output = '*Groups:*\n' .. table.concat(groups, '\n')
	else
		output = language.errors.results
	end
	mattata.sendMessage(message.chat.id, output, 'Markdown', true, false, message.message_id)
end

return groups