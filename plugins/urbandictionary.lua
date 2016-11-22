--[[

    Based on urbandictionary.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local urbandictionary = {}
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')
local mattata = require('mattata')

function urbandictionary:init(configuration)
	urbandictionary.arguments = 'urbandictionary <query>'
	urbandictionary.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('urbandictionary'):c('ud'):c('urban').table
	urbandictionary.inlineCommands = urbandictionary.commands
	urbandictionary.help = configuration.commandPrefix .. 'urbandictionary <query> - Defines the given word. Urban style. Aliases: ' .. configuration.commandPrefix .. 'ud, ' .. configuration.commandPrefix .. 'urban.'
end

function urbandictionary:onInlineQuery(inline_query, language)
	local input = mattata.input(inline_query.query)
	local jstr, res = HTTP.request('http://api.urbandictionary.com/v0/define?term=' .. URL.escape(input))
	if res ~= 200 then
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.connection,
				input_message_content = {
					message_text = language.errors.connection
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdat = JSON.decode(jstr)
	local results = '['
	local id = 1
	for n in pairs(jdat.list) do
		results = results .. JSON.encode({
			type = 'article',
			id = tostring(id),
			title = jdat.list[n].word,
			description = jdat.list[n].definition,
			input_message_content = {
				message_text = '*' .. jdat.list[n].word .. '*\n\n' .. mattata.markdownEscape(jdat.list[n].definition),
				parse_mode = 'Markdown'
			}
		})
		id = id + 1
		if n < #jdat.list then
			results = results .. ','
		end
	end
	mattata.answerInlineQuery(inline_query.id, results .. ']', 0)
end

function urbandictionary:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text)
	if not input then
		mattata.sendMessage(channel_post.chat.id, urbandictionary.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTP.request('http://api.urbandictionary.com/v0/define?term=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.result_type == 'no_results' then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	local output = '*' .. jdat.list[1].word .. '*\n\n' .. mattata.trim(jdat.list[1].definition)
	if string.len(jdat.list[1].example) > 0 then
		output = output .. '_\n\n' .. mattata.trim(jdat.list[1].example) .. '_'
	end
	mattata.sendMessage(channel_post.chat.id, output:gsub('%[', ''):gsub('%]', ''), 'Markdown', true, false, channel_post.message_id)
end

function urbandictionary:onMessage(message, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, urbandictionary.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://api.urbandictionary.com/v0/define?term=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.result_type == 'no_results' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local output = '*' .. jdat.list[1].word .. '*\n\n' .. mattata.trim(jdat.list[1].definition)
	if string.len(jdat.list[1].example) > 0 then
		output = output .. '_\n\n' .. mattata.trim(jdat.list[1].example) .. '_'
	end
	mattata.sendMessage(message.chat.id, output:gsub('%[', ''):gsub('%]', ''), 'Markdown', true, false, message.message_id)
end

return urbandictionary