local redis = require('redis')
local configuration = require('configuration')

redis.commands.hgetall = redis.command('hgetall', {
	response = function(reply, command, ...)
		local new_reply = { }
		for i = 1, #reply, 2 do
			new_reply[reply[i]] = reply[i + 1]
		end
		return new_reply
	end
} )

local res = pcall(function()
	local params = {
		host = configuration.redis.host,
		port = configuration.redis.port
	}
	redis = redis.connect(params)
end)

if res then
	if configuration.redis.password then
		redis:auth(configuration.redis.password)
	end
	if configuration.redis.database then
		redis:select(configuration.redis.database)
	end
else
	print('Error.')
end

return redis