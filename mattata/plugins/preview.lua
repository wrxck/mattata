local preview = {}
local HTTP = require('socket.http')
local functions = require('mattata.functions')
function preview:init(configuration)
    preview.command = 'preview <url>'
    preview.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('preview', true).table
    preview.doc = configuration.command_prefix .. 'preview <link> \nSends an "unlinked" preview of the given URL.'
end
function preview:action(msg)
    local input = functions.input(msg.text)
    if not input then
        functions.send_message(self, msg.chat.id, preview.doc, true, nil, true)
        return
    end
    input = functions.get_word(input, 1)
    if not input:match('^https?://.+') then
        input = 'http://' .. input
    end
    local res = HTTP.request(input)
    if not res then
        functions.send_reply(self, msg, 'Please provide a valid URL.')
        return
    end
    if res:len() == 0 then
        functions.send_reply(self, msg, 'Sorry, the URL you provided is not letting me generate a preview. Please check it\'s a valid link.')
        return
    end
    local output = '[​](' .. input .. ')'
    functions.send_message(self, msg.chat.id, output, false, nil, true)
end
return preview