local urbandictionary = {}
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local mattata = require('mattata')

function urbandictionary:init(configuration)
	urbandictionary.arguments = 'urbandictionary <query>'
	urbandictionary.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('urbandictionary'):command('ud'):command('urban').table
	urbandictionary.inlineCommands = urbandictionary.commands
	urbandictionary.help = configuration.commandPrefix .. 'urbandictionary <query> - Defines the given word. Urban style. Aliases: ' .. configuration.commandPrefix .. 'ud, ' .. configuration.commandPrefix .. 'urban.'
end

function urbandictionary:onInlineQuery(inline_query, configuration, language)
	local input = mattata.input(inline_query.query)
	local jstr, res = http.request('http://api.urbandictionary.com/v0/define?term=' .. url.escape(input))
	if res ~= 200 then
		local results = json.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.connection,
				input_message_content = { message_text = language.errors.connection }
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local jdat = json.decode(jstr)
	local results = {}
	local id = 1
	for n in pairs(jdat.list) do
		table.insert(results, {
			type = 'article',
			id = tostring(id),
			title = jdat.list[n].word,
			description = jdat.list[n].definition,
			input_message_content = {
				message_text = '<b>' .. mattata.htmlEscape(jdat.list[n].word) .. '</b>\n\n' .. mattata.htmlEscape(jdat.list[n].definition),
				parse_mode = 'HTML'
			}
		})
		id = id + 1
	end
	mattata.answerInlineQuery(inline_query.id, json.encode(results), 0)
	return
end

function urbandictionary.getResultCount(input)
	local jstr, res = http.request('http://api.urbandictionary.com/v0/define?term=' .. url.escape(input))
	if res ~= 200 then
		return 0
	end
	local jdat = json.decode(jstr)
	if jdat.result_type == 'no_results' then
		return 0
	end
	return #jdat.list
end

function urbandictionary.getResult(input, n)
	local jstr, res = http.request('http://api.urbandictionary.com/v0/define?term=' .. url.escape(input))
	if res ~= 200 then
		return false
	end
	local jdat = json.decode(jstr)
	if jdat.result_type == 'no_results' then
		return false
	end
	if not jdat.list[n].example then return false end
	local definition = mattata.htmlEscape(jdat.list[n].definition)
	local output = '<b>' .. jdat.list[n].word .. '</b>\n\n' .. mattata.trim(definition)
	if string.len(jdat.list[n].example) > 0 then
		local example = mattata.htmlEscape(jdat.list[n].example)
		output = output .. '\n\n<i>' .. mattata.trim(example) .. '</i>'
	end
	return output
end

function urbandictionary:onCallbackQuery(callback_query, message, configuration)
	if callback_query.data:match('^results:(%d*)$') then
		local result = callback_query.data:match('^results:(%d*)$')
		local input = mattata.input(message.reply_to_message.text)
		local totalResults = urbandictionary.getResultCount(input)
		if tonumber(result) > tonumber(totalResults) then
			result = 1
		elseif tonumber(result) < 1 then
			result = tonumber(totalResults)
		end
		local output = urbandictionary.getResult(input, tonumber(result))
		if not output then
			mattata.answerCallbackQuery(callback_query.id, 'An error occured!')
			return
		end
		local previousResult = 'urbandictionary:results:' .. math.floor(tonumber(result) - 1)
		local nextResult = 'urbandictionary:results:' .. math.floor(tonumber(result) + 1)
		local keyboard = {}
		keyboard.inline_keyboard = {{
			{ text = '◀️', callback_data = previousResult },
			{ text = result .. '/' .. totalResults, callback_data = 'urbandictionary:pages:' .. result .. ':' .. totalResults },
			{ text = '▶️', callback_data = nextResult }
		}}
		mattata.editMessageText(message.chat.id, message.message_id, output, 'HTML', true, json.encode(keyboard))
		return
	elseif callback_query.data:match('^pages:(.-):(.-)$') then
		local current, total = callback_query.data:match('^pages:(.-):(.-)$')
		mattata.answerCallbackQuery(callback_query.id, string.format('You are on page %s of %s!', current, total))
		return
	end
end

function urbandictionary:onMessage(message, configuration, language)
	local input = mattata.input(message.text)
	if not input then
		mattata.sendMessage(message.chat.id, urbandictionary.help, nil, true, false, message.message_id)
		return
	end
	local output = urbandictionary.getResult(input, 1)
	if not output then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	local keyboard = {}
	keyboard.inline_keyboard = {{
		{ text = '◀️', callback_data = 'urbandictionary:results:0' },
		{ text = '1/' .. urbandictionary.getResultCount(input), callback_data = 'urbandictionary:pages:1:' .. urbandictionary.getResultCount(input) },
		{ text = '▶️', callback_data = 'urbandictionary:results:2' }
	}}
	mattata.sendMessage(message.chat.id, output, 'HTML', true, false, message.message_id, json.encode(keyboard))
end

return urbandictionary