local help = {}
local functions = require('functions')
local help_text
function help:init(configuration)
 local command_list = {}
 help_text = '*Commands I understand include:*\n» '..configuration.command_prefix
 for _,plugin in ipairs(self.plugins) do
  if plugin.command then
   table.insert(command_list, plugin.command)
   if plugin.doc then
    plugin.help_word = functions.get_word(plugin.command, 1)
   end
  end
 end
 table.insert(command_list, 'help [command]')
 table.sort(command_list)
 help_text = help_text .. table.concat(command_list, '\n» '..configuration.command_prefix) .. '\nArguments: <required> [optional]'
 help_text = help_text:gsub('%[', '\\[')
 help.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('help', true):t('h', true).table
 help.doc = configuration.command_prefix .. '*help [command]* \n*Usage information for the given command.*'
end
function help:action(msg)
 local input = functions.input(msg.text_lower)
 if input then
  for _,plugin in ipairs(self.plugins) do
   if plugin.help_word == input:gsub('^/', '') then
    local output = '*Help for* _' .. plugin.help_word .. '_ *:*\n' .. plugin.doc
    functions.send_message(self, msg.chat.id, output, true, nil, true)
    return
   end
  end
  functions.send_message(self, msg, '*Sorry, there is no help for that command!*', true, nil, true)
 else
  local res = functions.send_message(self, msg.from.id, help_text, true, nil, true)
  if not res then
   functions.send_message(self, msg.chat.id, 'Please [message me in a private chat](http://telegram.me/' .. self.info.username .. '?start=help) for command-related help.', true, nil, true)
  elseif msg.chat.type ~= 'private' then
   functions.send_message(self, msg.chat.id, '*Hi there, mate! I have sent you a private message!*', true, nil, true)
  end
 end
end
return help