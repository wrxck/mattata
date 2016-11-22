--[[

    Based on xkcd.lua, Copyright 2016 topkecleon <drew@otou.to>
    This code is licensed under the GNU AGPLv3.

]]--

local xkcd = {}
local mattata = require('mattata')
local HTTPS = require('ssl.https')
local HTTP = require('socket.http')
local URL = require('socket.url')
local JSON = require('dkjson')

xkcd.base_url = 'https://xkcd.com/info.0.json'
xkcd.strip_url = 'http://xkcd.com/%s/info.0.json'

function xkcd:init(configuration)
	xkcd.arguments = 'xkcd <i>'
	xkcd.commands = mattata.commands(self.info.username, configuration.commandPrefix):c('xkcd').table
	xkcd.help = configuration.commandPrefix .. 'xkcd <i> - Returns the latest xkcd strip and its alt text. If a number is given, returns that number strip. If \'r\' is passed in place of a number, returns a random strip.'
	local jstr = HTTP.request(xkcd.base_url)
	if jstr then
		local data = JSON.decode(jstr)
		if data then
			xkcd.latest = data.num
		end
		
	end
	xkcd.latest = xkcd.latest
end

function xkcd:onChannelPost(channel_post, configuration)
	local input = mattata.getWord(channel_post.text, 2)
	if not input then
		input = xkcd.latest
	end
	if input == 'r' then
		input = math.random(xkcd.latest)
	elseif tonumber(input) ~= nil then
		input = tonumber(input)
	else
		local link = 'https://www.google.co.uk/search?num=20&q=' .. URL.escape('inurl:xkcd.com ' .. input)
		local search, code = HTTPS.request(link)
		local result = search:match("https?://xkcd[^/]+/(%d+)")
		if tonumber(result) ~= nil then
			input = result
		else
			input = xkcd.latest
		end
	end
	local url = xkcd.strip_url:format(input)
	local jstr, res = HTTP.request(url)
	if res == 404 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.results, nil, true, false, channel_post.message_id)
	elseif res ~= 200 then
		mattata.sendMessage(channel_post.chat.id, configuration.errors.connection, nil, true, false, channel_post.message_id)
	end
	local data = JSON.decode(jstr)
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Read more',
				url = 'https://xkcd.com/' .. data.num
			}
		}
	}
	mattata.sendPhoto(channel_post.chat.id, data.img, data.num .. ' | ' .. data.safe_title .. ' | ' .. data.day .. '/' .. data.month .. '/' .. data.year, false, channel_post.message_id, JSON.encode(keyboard))
end

function xkcd:onMessage(message, language)
	local input = mattata.getWord(message.text, 2)
	if not input then
		input = xkcd.latest
	end
	if input == 'r' then
		input = math.random(xkcd.latest)
	elseif tonumber(input) ~= nil then
		input = tonumber(input)
	else
		local link = 'https://www.google.co.uk/search?num=20&q=' .. URL.escape('inurl:xkcd.com ' .. input)
		local search, code = HTTPS.request(link)
		local result = search:match("https?://xkcd[^/]+/(%d+)")
		if tonumber(result) ~= nil then
			input = result
		else
			input = xkcd.latest
		end
	end
	local url = xkcd.strip_url:format(input)
	local jstr, res = HTTP.request(url)
	if res == 404 then
		mattata.sendMessage(message.chat.id, language.errors.results, nil, true, false, message.message_id)
	elseif res ~= 200 then
		mattata.sendMessage(message.chat.id, language.errors.connection, nil, true, false, message.message_id)
	end
	local data = JSON.decode(jstr)
	local keyboard = {}
	keyboard.inline_keyboard = {
		{
			{
				text = 'Read more',
				url = 'https://xkcd.com/' .. data.num
			}
		}
	}
	mattata.sendPhoto(message.chat.id, data.img, data.num .. ' | ' .. data.safe_title .. ' | ' .. data.day .. '/' .. data.month .. '/' .. data.year, false, message.message_id, JSON.encode(keyboard))
end

return xkcd