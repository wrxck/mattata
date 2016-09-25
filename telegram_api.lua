local telegram_api = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
local ltn12 = require('ltn12')
local mp_encode = require('multipart-post').encode
function telegram_api.init(token)
	telegram_api.BASE_URL = 'https://api.telegram.org/bot' .. token .. '/'
	return telegram_api
end
function telegram_api.request(method, parameters, file)
	parameters = parameters or {}
	for k,v in pairs(parameters) do
		parameters[k] = tostring(v)
	end
	if file and next(file) ~= nil then
		local file_type, file_name = next(file)
		if not file_name then return false end
		if string.match(file_name, '/tmp/') then
			local file_file = io.open(file_name, 'r')
			local file_data = {
				filename = file_name,
				data = file_file:read('*a')
			}
			file_file:close()
			parameters[file_type] = file_data
		else
			local file_type, file_name = next(file)
			parameters[file_type] = file_name
		end
	end
	if next(parameters) == nil then
		parameters = {''}
	end
	local response = {}
	local body, boundary = mp_encode(parameters)
	local success, code = HTTPS.request{
		url = telegram_api.BASE_URL .. method,
		method = 'POST',
		headers = {
			["Content-Type"] =	"multipart/form-data; boundary=" .. boundary,
			["Content-Length"] = #body,
		},
		source = ltn12.source.string(body),
		sink = ltn12.sink.table(response)
	}
	local data = table.concat(response)
	if not success then
		print(method .. ': Connection error. [' .. code	.. ']')
		return false, false
	else
		local result = JSON.decode(data)
		if not result then
			return false, false
		elseif result.ok then
			return result
		else
			assert(result.description ~= 'Method not found', method .. ': Method not found.')
			return false, result
		end
	end
end
function telegram_api.gen(_, key)
	return function(params, file)
		return telegram_api.request(key, params, file)
	end
end
setmetatable(telegram_api, { __index = telegram_api.gen })
return telegram_api