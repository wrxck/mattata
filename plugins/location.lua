--[[

    Based on location.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local location = {}
local mattata = require('mattata')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

function location:init(configuration)
	location.arguments = 'location <query>'
	location.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('location').table
	location.inlineCommands = location.commands
	location.help = configuration.commandPrefix .. 'location <query> - Sends a location from Google Maps.'
end

function location:onInlineQuery(inline_query, configuration, language)
	local input = mattata.input(inline_query.query)
	local jstr, res = HTTP.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. URL.escape(input))
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
	if jdat.status == 'ZERO_RESULTS' then
		local results = JSON.encode({
			{
				type = 'article',
				id = '1',
				title = 'An error occured!',
				description = language.errors.results,
				input_message_content = {
					message_text = language.errors.results
				}
			}
		})
		mattata.answerInlineQuery(inline_query.id, results, 0)
		return
	end
	local results = JSON.encode({
		{
			type = 'location',
			id = '1',
			latitude = jdat.results[1].geometry.location.lat,
			longitude = jdat.results[1].geometry.location.lng,
			title = input
		}
	})
	mattata.answerInlineQuery(inline_query.id, results, 0)
end

function location:onChannelPost(channel_post, configuration)
	local input = mattata.input(channel_post.text_lower)
	if not input then
		mattata.sendMessage(channel_post.chat.id, location.help, nil, true, false, channel_post.message_id)
		return
	end
	local jstr, res = HTTP.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.status == 'ZERO_RESULTS' then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
		return
	end
	mattata.sendLocation(channel_post.chat.id, jdat.results[1].geometry.location.lat, jdat.results[1].geometry.location.lng)
end

function location:onMessage(message, language)
	local input = mattata.input(message.text_lower)
	if not input then
		mattata.sendMessage(message.chat.id, location.help, nil, true, false, message.message_id)
		return
	end
	local jstr, res = HTTP.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. URL.escape(input))
	if res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
		return
	end
	local jdat = JSON.decode(jstr)
	if jdat.status == 'ZERO_RESULTS' then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
		return
	end
	mattata.sendLocation(message.chat.id, jdat.results[1].geometry.location.lat, jdat.results[1].geometry.location.lng)
end

return location