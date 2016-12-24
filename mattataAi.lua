--[[

	mattataAi
	
	Copyright (c) 2016 Matthew Hesketh
	See LICENSE for details
	
	mattataAi is a basic implementation of Cleverbot, written in Lua.
	Intended for use with the mattata library, a feature-filled Telegram bot API framework

]]--

local mattataAi = {}
local mattataAiMeta = { __name = 'mattataAi'; __index = mattataAi; }
local http = require('http.request')
local url = require('socket.url')
local digest = require('openssl.digest')

function mattataAi.numtohex(int)
	local hex = '0123456789abcdef'
	local s = ''
	while int > 0 do
		local mod = math.fmod(int, 16)
		s = hex:sub(mod + 1, mod +1 ) .. s
		int = math.floor(int / 16)
	end
	if s == '' then s = '0' end
	return s
end

function mattataAi.strtohex(str)
	local s = ''
	while #str > 0 do
		local h = mattataAi.numtohex(str:byte(1, 1))
		if #h < 2 then h = '0' .. h end
		s = s .. h
		str = str:sub(2)
	end
	return s
end

function mattataAi:init()
	return setmetatable({
		base = 'http://www.cleverbot.com/';
		webservice = 'http://www.cleverbot.com/webservicemin?uc=321&';
		cookie = {};
	}, mattataAiMeta)
end
 
function mattataAi:setCookie()
	local request = http.new_from_uri(self.base)
	local headers, res = assert(request:go())
	res:shutdown()
	assert(headers:get(':status') == '200')
	local set = headers:get('set-cookie')
	local k, v = set:match('([^%s;=]+)=?([^%s;]*)')
	self.cookie[k] = v
end

function mattataAi.processHeaders(request, cookie)
	request.headers:upsert('Cookie', cookie)
	request.headers:upsert('Content-Type', 'text/plain;charset=UTF-8')
	request.headers:upsert('Host', 'www.cleverbot.com')
	request.headers:upsert('Origin', 'http://www.cleverbot.com')
	request.headers:upsert('Referrer', 'http://www.cleverbot.com/')
	request.headers:upsert('User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36')
	return request
end

function mattataAi:talk(message)
	if next(self.cookie) == nil then self:setCookie() end
	local request = http.new_from_uri(self.webservice)
	request.headers:upsert(':method', 'POST')
	local cookie = {}
	for k, v in pairs(self.cookie) do cookie[#cookie+1] = k .. '=' .. v end
	cookie = table.concat(cookie, '; ')
	request = mattataAi.processHeaders(request, cookie)
	local query = 'stimulus=' .. url.escape(message) .. '&islearning=1&icognoid=wsf&cb_settings_language=en&cb_settings_scripting=no&icognocheck='
	local hash = query:sub(10, 35)
	hash = mattataAi.strtohex(digest.new('md5'):final(hash))
	request:set_body(query .. hash)
	local headers, res = assert(request:go())
	local response = res:get_body_as_string()
	if headers:get(':status') ~= '200' then error(response) end
	res:shutdown()
	return response:match('([^\r]*)\r')
end
 
return { init = mattataAi.init; }