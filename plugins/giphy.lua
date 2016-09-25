local giphy = {}
local HTTPS = require('ssl.https')
local JSON = require('dkjson')
function giphy:init(configuration)
	giphy.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('gif', true).table
	giphy.inline_triggers = giphy.triggers
end
function giphy:inline_callback(inline_query, configuration, matches)
	local input = inline_query.query:gsub('/gif ', '')
	local url = HTTPS.request('https://api.giphy.com/v1/gifs/search?q='..URL.escape(input)..'&api_key=dc6zaTOxFJmzC')
	local jdat = JSON.decode(url)
	local results = '['
	local id = 50
	for n in pairs(jdat.data) do
		results = results..'{"type":"mpeg4_gif","id":"'..id..'","mpeg4_url":"'..jdat.data[n].images.original.mp4..'","thumb_url":"'..jdat.data[n].images.fixed_height.url..'","mpeg4_width":'..jdat.data[n].images.original.width..',"mp4_height":'..jdat.data[n].images.original.height..'}'
		id = id + 1
		if n < #jdat.data then
			results = results..','
		end
	end
	local results = results..']'
	functions.answer_inline_query(inline_query, results, 3600)
end
function giphy:action()
end
return giphy