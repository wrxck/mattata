local blacklist = {}
local functions = require('functions')
local telegram_api = require('telegram_api')
function blacklist:init()
 if not self.database.blacklist then
  self.database.blacklist = {}
 end
end
blacklist.triggers = {
 ''
}
blacklist.error = false
function blacklist:action(msg, configuration)
 if self.database.blacklist[tostring(msg.from.id)] then
  return
 elseif self.database.blacklist[tostring(msg.chat.id)] then
  telegram_api.leaveChat(self, { chat_id = msg.chat.id })
  return
 end
 if not (
  msg.from.id == configuration.admin
  and (
   msg.text:match('^'..configuration.cmd_pat..'blacklist') or msg.text:match('^'..configuration.cmd_pat..'unblacklist')
  )
 ) then
  return true
 end
 local targets = {}
 if msg.reply_to_message then
  table.insert(targets, {
   id = msg.reply_to_message.from.id,
   id_str = tostring(msg.reply_to_message.from.id),
   name = functions.build_name(msg.reply_to_message.from.first_name, msg.reply_to_message.from.last_name)
  })
 else
  local input = functions.input(msg.text)
  if input then
   for _, user in ipairs(functions.index(input)) do
 if self.database.users[user] then
  table.insert(targets, {
   id = self.database.users[user].id,
   id_str = tostring(self.database.users[user].id),
   name = functions.build_name(self.database.users[user].first_name, self.database.users[user].last_name)
  })
 elseif tonumber(user) then
  local t = {
   id_str = user,
   id = tonumber(user)
  }
  if tonumber(user) < 0 then
   t.name = 'Group (' .. user .. ')'
  else
   t.name = 'Unknown (' .. user .. ')'
  end
  table.insert(targets, t)
 elseif user:match('^@') then
  local u = functions.resolve_username(self, user)
  if u then
   table.insert(targets, {
    id = u.id,
    id_str = tostring(u.id),
    name = functions.build_name(u.first_name, u.last_name)
   })
  else
   table.insert(targets, { err = 'I\'m sorry, but I do not recognise the username '..user..'. Please ensure you typed it correctly, and then try again.' })
  end
 else
  table.insert(targets, { err = 'I\'m sorry, but '..user..' is an invalid username or ID. Please ensure you typed it correctly, and then try again.' })
 end
   end
  else
   functions.send_reply(self, msg, 'Please specify a user/group by stating their username (or ID) as a command argument.')
   return
  end
 end
 local output = ''
 if msg.text:match('^'..configuration.cmd_pat..'blacklist') then
  for _, target in ipairs(targets) do
   if target.err then
 output = output .. target.err .. '\n'
   elseif self.database.blacklist[target.id_str] then
 output = output .. target.name .. ' is already blacklisted.\n'
   else
 self.database.blacklist[target.id_str] = true
 output = output .. target.name .. ' is now blacklisted.\n'
 if configuration.drua_block_on_blacklist and target.id > 0 then
  require('drua-tg').block(target.id)
 end
   end
  end
 elseif msg.text:match('^'..configuration.cmd_pat..'unblacklist') then
  for _, target in ipairs(targets) do
   if target.err then
 output = output .. target.err .. '\n'
   elseif not self.database.blacklist[target.id_str] then
 output = output .. target.name .. ' is not blacklisted.\n'
   else
 self.database.blacklist[target.id_str] = nil
 output = output .. target.name .. ' is no longer blacklisted.\n'
 if configuration.drua_block_on_blacklist and target.id > 0 then
  require('drua-tg').unblock(target.id)
 end
   end
  end
 end
 functions.send_reply(self, msg, output)
end
return blacklist