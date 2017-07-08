local Http = require "socket.http"
--local Https = require "ssl.https"
--local Https = require "https"
require "https"
local Https = ssl.https
local Base64 = require "base64"
local Ltn12 = require "ltn12"
local Url = require "socket.url"
--local Crypto = require "crypto"


local Client = {}
Client.__index = Client

--
-- Encodes the key-value pairs of a table according the application/x-www-form-urlencoded content type.
local function url_encode_arguments(arguments)
	local body = {}
	for k,v in pairs(arguments) do
		body[#body + 1] = Url.escape(tostring(k)) .. "=" .. Url.escape(tostring(v))
	end
	return table.concat(body, "&")
end

---
-- Performs the actual http request, using LuaSocket or LuaSec (when using an https scheme)
-- @param url is the url to request
-- @param method is the http method (GET, POST, etc)
-- @param headers are the supplied http headers as a table
-- @param arguments is an optional table with whose keys and values will be encoded as "application/x-www-form-urlencoded"
--   or a string (or something that can be converted to a string). In that case, you must supply the Content-Type.
-- @param post_body is a string with all parameters (custom + oauth ones) encoded. This is used when the OAuth provider
--   does not support the 'Authorization' header.
local function PerformRequestHelper(self, url, method, headers, arguments, post_body)
	-- Remove oauth_related arguments
	if type(arguments) == "table" then
		for k,v in pairs(arguments) do
			if type(k) == "string" and k:match("^oauth_") then
				arguments[k] = nil
			end
		end
		if not next(arguments) then
			arguments = nil
		end
	end
	
	-- this method screams "refactor me!"
	local response_body = {}
	local request_constructor = {
		url = url,
		method = method,
		headers = headers,
		sink = Ltn12.sink.table(response_body)
	}
	
	if method == "PUT" then
		if type(arguments) == "table" then
			error("unsupported table argument for PUT")
		else
			local string_data = tostring(arguments)
			if string_data == "nil" then
				error("data must be something convertible to a string")
			end
			request_constructor.headers["Content-Length"] = tostring(#string_data)
			request_constructor.source = Ltn12.source.string(string_data)
		end
	
	elseif method == "POST" then
		if type(arguments) == "table" then
			request_constructor.headers["Content-Type"] = "application/x-www-form-urlencoded"
			if not self.m_supportsAuthHeader then
				-- send all parameters (oauth + custom) in the body
				request_constructor.headers["Content-Length"] = tostring(#post_body)
				request_constructor.source = Ltn12.source.string(post_body)
			else
				-- encode the custom parameters and send them in the body
				local source = url_encode_arguments(arguments)
				request_constructor.headers["Content-Length"] = tostring(#source)
				request_constructor.source = Ltn12.source.string(source)
			end
		elseif arguments then
			if not self.m_supportsAuthHeader then
				error("can't send POST body if the server does not support 'Authorization' header")
			end
			local string_data = tostring(arguments)
			if string_data == "nil" then
				error("data must be something convertible to a string")
			end
			request_constructor.headers["Content-Length"] = tostring(#string_data)
			request_constructor.source = Ltn12.source.string(string_data)
		else
			request_constructor.headers["Content-Length"] = "0"
		end
		
	elseif method == "GET" or method == "HEAD" or method == "DELETE" then
		if self.m_supportsAuthHeader then
			if arguments then
				request_constructor.url = url .. "?" .. url_encode_arguments(arguments)
			end
		else
			-- send all parameters (oauth + custom) in the url
			request_constructor.url = url .. "?" .. post_body
		end
	end
	
	local ok, response_code, response_headers, response_status_line
	if url:match("^https://") then
		ok, response_code, response_headers, response_status_line = Https.request(request_constructor)
	elseif url:match("^http://") then
		ok, response_code, response_headers, response_status_line = Http.request(request_constructor)
	else
		error( ("unsupported scheme '%s'"):format( tostring(url:match("^([^:]+)")) ) )
	end
	
	if not ok then
		return nil, response_code, response_headers, response_status_line, response_body
	end
	
	response_body = table.concat(response_body)
	
	--[=[
	for k,v in pairs(response_headers or {}) do
		print( ("%s: %s"):format(k,v) )
	end
	print( ("response: %s"):format(response_body) )
	--]=]
	
	return true, response_code, response_headers, response_status_line, response_body
end



--
-- After retrieving an access token, this method is used to issue properly authenticated requests.
-- (see http://tools.ietf.org/html/rfc5849#section-3)
-- @param method is the http method (GET, POST, etc)
-- @param url is the url to request
-- @param arguments is an optional table whose keys and values will be encoded as "application/x-www-form-urlencoded"
--  (when doing a POST) or encoded and sent in the query string (when doing a GET).
-- @param headers is an optional table with http headers to be sent in the request
-- @return the http status code (a number), a table with the response headers, the status line and the response itself
--
function Client:PerformRequest(method, url, arguments, headers)
	assert(type(method) == "string", "'method' must be a string")
	method = method:upper()
	
	--local headers, post_body, arguments = self:BuildRequest(method, url, arguments, headers)
	arguments = arguments or {}
	arguments.client_id = self.m_consumer_key
	local ok, response_code, response_headers, response_status_line, response_body = PerformRequestHelper(self, url, method, headers, arguments, post_body)
	return response_code, response_headers, response_status_line, response_body
end









function Client.new(consumer_key, consumer_secret, endpoints, params)
	params = params or {}
	local newInstance = {
		m_consumer_key = consumer_key,
		m_consumer_secret = consumer_secret,
		m_endpoints = {},
		m_signature_method = params.SignatureMethod or "HMAC-SHA1",
		m_supportsAuthHeader = true,
		m_oauth_token = params.OAuthToken,
		m_oauth_token_secret = params.OAuthTokenSecret,
		m_oauth_verifier = params.OAuthVerifier
	}
	
	if type(params.UseAuthHeaders) == "boolean" then
		newInstance.m_supportsAuthHeader = params.UseAuthHeaders
	end
	
	for k,v in pairs(endpoints or {}) do
		if type(v) == "table" then
			newInstance.m_endpoints[k] = { url = v[1], method = string.upper(v.method) }
		else
			newInstance.m_endpoints[k] = { url = v, method = "POST" }
		end
	end
	
	setmetatable(newInstance, Client)
	
	return newInstance
end

return Client
