local redis = require 'redis'
local fakeredis = require 'fakeredis'
local configuration = require('configuration')
if not configuration.redis then
	configuration.redis = {
		host = '127.0.0.1',
		port = 6379,
		use_socket = false
	}
end
redis.commands.hgetall = redis.command('hgetall', {
	response = function(reply, command, ...)
		local new_reply = { }
		for i = 1, #reply, 2 do new_reply[reply[i]] = reply[i + 1] end
		return new_reply
	end
})
local redis = nil
local ok = pcall(function()
	if configuration.redis.use_socket and configuration.redis.socket_path then
		redis = redis.connect(configuration.redis.socket_path)
	else
	local params = {
		host = configuration.redis.host,
		port = configuration.redis.port
	}
		redis = redis.connect(params)
	end
end)
if not ok then
	local fake_func = function()
		print('\27[31mCan\'t connect with redis, install/configurationure it!\27[39m')
	end
	fake_func()
	fake = fakeredis.new()

	redis = setmetatable({fakeredis=true}, {
	__index = function(a, b)
		if b ~= 'data' and fake[b] then
			fake_func(b)
		end
		return fake[b] or fake_func
	end })
else
	if configuration.redis.password then
		redis:auth(configuration.redis.password)
	end
	if configuration.redis.database then
		redis:select(configuration.redis.database)
	end
end
return redis