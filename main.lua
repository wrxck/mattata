local cleverbot = require('mattata-ai')
local cleverbot1 = cleverbot:init()
local cleverbot2 = cleverbot:init()

local current_question = "Hi!"
while true do
	local ans1 = cleverbot1:talk(current_question)
	print("Bot 1: " .. ans1)
	local ans2 = cleverbot2:talk(ans1)
	print("Bot 2: " .. ans2)
	current_question = ans2
end