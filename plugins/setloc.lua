local setloc = {}
local mattata = require('mattata')
local http = require('socket.http')
local url = require('socket.url')
local json = require('dkjson')
local redis = require('mattata-redis')
local configuration = require('configuration')

function setloc:init(configuration)
	setloc.arguments = 'setloc <location>'
	setloc.commands = mattata.commands(self.info.username, configuration.commandPrefix):command('setloc').table
	setloc.help = configuration.commandPrefix .. 'setloc <location> - Sets your location to the given value.'
end

function setloc.validateLocation(location)
	local jstr, res = http.request('http://maps.googleapis.com/maps/api/geocode/json?address=' .. url.escape(location))
	if res ~= 200 then
		return false, configuration.errors.connection
	end
	local jdat = json.decode(jstr)
	if jdat.status == 'ZERO_RESULTS' then
		return false, configuration.errors.results
	end
    return true, jdat.results[1].geometry.location.lat .. ':' .. jdat.results[1].geometry.location.lng .. ':' .. jdat.results[1].formatted_address
end

function setloc.setLocation(user, location)
	local validate, res = setloc.validateLocation(location)
	if not validate then
		return res
	end
	local latitude, longitude, address = res:match('^(.-):(.-):(.-)$')
	local userLocation = json.encode({
		latitude = latitude,
		longitude = longitude,
		address = address
	})
	local hash = mattata.getUserRedisHash(user, 'location')
	if hash then
		redis:hset(hash, 'location', userLocation)
		return 'Your location has been updated to: ' .. address .. '\nYou can now use commands such as ' .. configuration.commandPrefix .. 'weather and ' .. configuration.commandPrefix .. 'location, without needing to specify a location - your location will be used by default. Giving a different location as the command argument will override this.'
	end
end

function setloc.getLocation(user)
	local hash = mattata.getUserRedisHash(user, 'location')
	if hash then
		local location = redis:hget(hash, 'location')
		if not location or location == 'false' then
			return false
		else
			return location
		end
	end
end

function setloc:onMessage(message, configuration)
	local input = mattata.input(message.text)
	if not input then
		local location = setloc.getLocation(message.from)
		if not location then
			mattata.sendMessage(message.chat.id, 'You don\'t have a location set. Use \'' .. configuration.commandPrefix .. 'setloc <location>\' to set one.', nil, true, false, message.message_id)
			return
		end
		mattata.sendMessage(message.chat.id, 'Your location is currently set to: ' .. json.decode(location).address, nil, true, false, message.message_id)
		return
	end
	mattata.sendMessage(message.chat.id, setloc.setLocation(message.from, input), nil, true, false, message.message_id)
end

return setloc