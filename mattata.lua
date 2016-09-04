local mattata = {}
local telegram_api
local functions
mattata.version = '1.3'
function mattata:init(configuration)
 telegram_api = require('telegram_api')
 functions = require('functions')
 assert(configuration.api_key ~= '',('You did not set your token in the configuration file!'))
 self.BASE_URL = 'https://api.telegram.org/bot' .. configuration.api_key .. '/'
 repeat
  print('mattata is initialising...')
  self.info = telegram_api.getMe(self)
 until self.info
 self.info = self.info.result
 if not self.database then
  self.database = functions.load_data('mattata.db')
 end
 self.database.users = self.database.users or {}
 self.database.userdata = self.database.userdata or {}
 self.database.version = mattata.version
 self.database.users[tostring(self.info.id)] = self.info
 self.plugins = {}
 for _,v in ipairs(configuration.plugins) do
  local p = require('plugins.'..v)
  table.insert(self.plugins, p)
  if p.init then p.init(self, configuration) end
  if p.doc then p.doc = '```\n'..p.doc..'\n```' end
 end
 print('mattata was successfully initialised! ' .. self.info.first_name .. ' ('..self.info.id..')')
 self.last_update = self.last_update or 0
 self.last_cron = self.last_cron or os.date('%M')
 self.last_database_save = self.last_database_save or os.date('%H')
 self.is_started = true
end
function mattata:on_msg_receive(msg, configuration)
 if msg.date < os.time() - 5 then
  return
 end
 self.database.users[tostring(msg.from.id)] = msg.from
 if msg.reply_to_message then
  self.database.users[tostring(msg.reply_to_message.from.id)] = msg.reply_to_message.from
 elseif msg.forward_from then
  self.database.users[tostring(msg.forward_from.id)] = msg.forward_from
 elseif msg.new_chat_member then
  self.database.users[tostring(msg.new_chat_member.id)] = msg.new_chat_member
 elseif msg.left_chat_member then
  self.database.users[tostring(msg.left_chat_member.id)] = msg.left_chat_member
 end
 msg.text = msg.text or msg.caption or ''
 msg.text_lower = msg.text:lower()
 if msg.reply_to_message then
  msg.reply_to_message.text = msg.reply_to_message.text or msg.reply_to_message.caption or ''
 end
 if msg.text:match('^'..configuration.command_prefix..'start .+') then
  msg.text = configuration.command_prefix .. functions.input(msg.text)
  msg.text_lower = msg.text:lower()
 end
 for _, plugin in ipairs(self.plugins) do
  for _, trigger in ipairs(plugin.triggers or {}) do
   if string.match(msg.text_lower, trigger) then
    local success, result = pcall(function()
     return plugin.action(self, msg, configuration)
    end)
    if not success then
     if plugin.error then
      functions.send_reply(self, msg, plugin.error)
     elseif plugin.error == nil then
      functions.send_reply(self, msg, configuration.errors.generic)
     end
     functions.handle_exception(self, result, msg.from.id .. ': ' .. msg.text, configuration)
     return
    end
    if type(result) == 'table' then
     msg = result
    elseif result ~= true then
     return
    end
   end
  end
 end
end
function mattata:run(configuration)
 mattata.init(self, configuration)
 while self.is_started do
  local res = telegram_api.getUpdates(self, { timeout=20, offset = self.last_update+1 } )
  if res then
   for _,v in ipairs(res.result) do
    self.last_update = v.update_id
    if v.message then
     mattata.on_msg_receive(self, v.message, configuration)
    end
   end
  else
   print('An error occured whilst mattata was retrieving updates from Telegram.')
  end
  if self.last_cron ~= os.date('%M') then
   self.last_cron = os.date('%M')
   for i,v in ipairs(self.plugins) do
    if v.cron then
     local result, err = pcall(function() v.cron(self, configuration) end)
     if not result then
      functions.handle_exception(self, err, 'CRON: ' .. i, configuration)
     end
    end
   end
  end
 if self.last_database_save ~= os.date('%H') then
   functions.save_data(self.info.username..'.db', self.database)
   self.last_database_save = os.date('%H')
  end
 end functions.save_data(self.info.username..'.db', self.database)
 print('mattata is shutting down...')
end
return mattata