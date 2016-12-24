local redis = require('redis')
local configuration = require('configuration')

redis.commands.hgetall = redis.command('hgetall', {
	response = function(reply, command, ...)
		local new = {}
		for i = 1, #reply, 2 do new[reply[i]] = reply[i + 1] end
		return new
	end
})

local res = pcall(function()
	local params = { host = configuration.redis.host, port = configuration.redis.port }
	redis = redis.connect(params)
end)

if not res then
	print('Error.')
	return
end
if configuration.redis.database ~= '' then redis:select(configuration.redis.database)
elseif configuration.redis.usePassword then redis:auth(configuration.redis.password) end

return redis