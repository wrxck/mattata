local JSON = require('dkjson')
local mattata = require('drua-tg')
local telegram_api = require('telegram_api')
local functions = require('functions')
local administration = {}
function administration:init(configuration)
 -- Build the administration db if nonexistent.
 if not self.database.administration then
  self.database.administration = {
   admins = {},
   groups = {},
   activity = {},
   autokick_timer = os.date('%d'),
   globalbans = {}
  }
 end
 administration.temp = {
  help = {},
  flood = {}
 }
 mattata.PORT = configuration.cli_port or 4570
 administration.flags = administration.init_flags(configuration.command_prefix)
 administration.init_command(self, configuration)
 administration.antiflood = configuration.administration.antiflood
 administration.doc = 'Returns a list of administrated groups.\nUse '..configuration.command_prefix..'ahelp for more administrative commands.'
 administration.command = 'groups [query]'
 -- In the worst case, don't send errors in reply to random messages.
 administration.error = false
 -- Accept forwarded messages and messages from blocked users.
 administration.panoptic = true
end
function administration.init_flags(command_prefix) return {
 [1] = {
  name = 'unlisted',
  desc = 'Removes this group from the group listing.',
  short = 'This group is unlisted.',
  enabled = 'This group is no longer listed in '..command_prefix..'groups.',
  disabled = 'This group is now listed in '..command_prefix..'groups.'
 },
 [2] = {
  name = 'antisquig',
  desc = 'Automatically removes users who post Arabic script or RTL characters.',
  short = 'This group does not allow Arabic script or RTL characters.',
  enabled = 'Users will now be removed automatically for posting Arabic script and/or RTL characters.',
  disabled = 'Users will no longer be removed automatically for posting Arabic script and/or RTL characters.',
  kicked = 'You were automatically kicked from GROUPNAME for posting Arabic script and/or RTL characters.'
 },
 [3] = {
  name = 'antisquig++',
  desc = 'Automatically removes users whose names contain Arabic script or RTL characters.',
  short = 'This group does not allow users whose names contain Arabic script or RTL characters.',
  enabled = 'Users whose names contain Arabic script and/or RTL characters will now be removed automatically.',
  disabled = 'Users whose names contain Arabic script and/or RTL characters will no longer be removed automatically.',
  kicked = 'You were automatically kicked from GROUPNAME for having a name which contains Arabic script and/or RTL characters.'
 },
 [4] = {
  name = 'antibot',
  desc = 'Prevents the addition of bots by non-moderators.',
  short = 'This group does not allow users to add bots.',
  enabled = 'Non-moderators will no longer be able to add bots.',
  disabled = 'Non-moderators will now be able to add bots.'
 },
 [5] = {
  name = 'antiflood',
  desc = 'Prevents flooding by rate-limiting messages per user.',
  short = 'This group automatically removes users who flood.',
  enabled = 'Users will now be removed automatically for excessive messages. Use '..command_prefix..'antiflood to configurationure limits.',
  disabled = 'Users will no longer be removed automatically for excessive messages.',
  kicked = 'You were automatically kicked from GROUPNAME for flooding.'
 },
 [6] = {
  name = 'antihammer',
  desc = 'Allows globally banned users to enter this group. Note that users hammered in this group will also be banned locally.',
  short = 'This group does not acknowledge global bans.',
  enabled = 'This group will no longer remove users for being globally banned.',
  disabled = 'This group will now remove users for being globally banned.'
 }
} end

administration.ranks = {
 [0] = 'Banned',
 [1] = 'Users',
 [2] = 'Moderators',
 [3] = 'Directors',
 [4] = 'Administrators',
 [5] = 'Owner'
}

function administration:get_rank(user_id_str, chat_id_str, configuration)

 user_id_str = tostring(user_id_str)
 local user_id = tonumber(user_id_str)
 chat_id_str = tostring(chat_id_str)

 -- Return 5 if the user_id_str is the bot or its owner.
 if user_id == configuration.admin or user_id == self.info.id then
  return 5
 end

 -- Return 4 if the user_id_str is an administrator.
 if self.database.administration.admins[user_id_str] then
  return 4
 end

 if chat_id_str and self.database.administration.groups[chat_id_str] then
  -- Return 3 if the user_id_str is the director of the chat_id_str.
  if self.database.administration.groups[chat_id_str].director == user_id then
   return 3
  -- Return 2 if the user_id_str is a moderator of the chat_id_str.
  elseif self.database.administration.groups[chat_id_str].mods[user_id_str] then
   return 2
  -- Return 0 if the user_id_str is banned from the chat_id_str.
  elseif self.database.administration.groups[chat_id_str].bans[user_id_str] then
   return 0
  -- Return 1 if antihammer is enabled.
  elseif self.database.administration.groups[chat_id_str].flags[6] then
   return 1
  end
 end

 -- Return 0 if the user_id_str is globally banned (and antihammer is not enabled).
 if self.database.administration.globalbans[user_id_str] then
  return 0
 end

 -- Return 1 if the user_id_str is a regular user.
 return 1

end

-- Returns an array of "user" tables.
function administration:get_targets(msg, configuration)
 if msg.reply_to_message then
  local d = msg.reply_to_message.new_chat_member or msg.reply_to_message.left_chat_member or msg.reply_to_message.from
  local target = {}
  for k,v in pairs(d) do
   target[k] = v
  end
  target.name = functions.build_name(target.first_name, target.last_name)
  target.id_str = tostring(target.id)
  target.rank = administration.get_rank(self, target.id, msg.chat.id, configuration)
  return { target }
 else
  local input = functions.input(msg.text)
  if input then
   local t = {}
   for user in input:gmatch('%g+') do
    if self.database.users[user] then
     local target = {}
     for k,v in pairs(self.database.users[user]) do
      target[k] = v
     end
     target.name = functions.build_name(target.first_name, target.last_name)
     target.id_str = tostring(target.id)
     target.rank = administration.get_rank(self, target.id, msg.chat.id, configuration)
     table.insert(t, target)
    elseif tonumber(user) then
     local id = math.abs(tonumber(user))
     local target = {
      id = id,
      id_str = tostring(id),
      name = 'Unknown ('..id..')',
      rank = administration.get_rank(self, user, msg.chat.id, configuration)
     }
     table.insert(t, target)
    elseif user:match('^@') then
     local target = functions.resolve_username(self, user)
     if target then
      target.rank = administration.get_rank(self, target.id, msg.chat.id, configuration)
      target.id_str = tostring(target.id)
      target.name = functions.build_name(target.first_name, target.last_name)
      table.insert(t, target)
     else
      table.insert(t, { err = 'Sorry, I do not recognize that username ('..user..').' })
     end
    else
     table.insert(t, { err = 'Invalid username or ID ('..user..').' })
    end
   end
   return t
  else
   return false
  end
 end
end

function administration:mod_format(id)
 id = tostring(id)
 local user = self.database.users[id] or { first_name = 'Unknown' }
 local name = functions.build_name(user.first_name, user.last_name)
 name = functions.md_escape(name)
 local output = '• ' .. name .. ' `[' .. id .. ']`\n'
 return output
end

function administration:get_desc(chat_id, configuration)

 local group = self.database.administration.groups[tostring(chat_id)]
 local t = {}
 if group.link then
  table.insert(t, '*Welcome to* [' .. group.name .. '](' .. group.link .. ')*!*')
 else
  table.insert(t, '*Welcome to ' .. group.name .. '!*')
 end
 if group.motd then
  table.insert(t, '*Message of the Day:*\n' .. group.motd)
 end
 if #group.rules > 0 then
  local rulelist = '*Rules:*\n'
  for i = 1, #group.rules do
   rulelist = rulelist .. '*' .. i .. '.* ' .. group.rules[i] .. '\n'
  end
  table.insert(t, functions.trim(rulelist))
 end
 local flaglist = ''
 for i = 1, #administration.flags do
  if group.flags[i] then
   flaglist = flaglist .. '• ' .. administration.flags[i].short .. '\n'
  end
 end
 if flaglist ~= '' then
  table.insert(t, '*Flags:*\n' .. functions.trim(flaglist))
 end
 if group.director then
  local dir = self.database.users[tostring(group.director)]
  local s
  if dir then
   s = functions.md_escape(functions.build_name(dir.first_name, dir.last_name)) .. ' `[' .. dir.id .. ']`'
  else
   s = 'Unknown `[' .. group.director .. ']`'
  end
  table.insert(t, '*Director:* ' .. s)
 end
 local modstring = ''
 for k,_ in pairs(group.mods) do
  modstring = modstring .. administration.mod_format(self, k)
 end
 if modstring ~= '' then
  table.insert(t, '*Moderators:*\n' .. functions.trim(modstring))
 end
 table.insert(t, 'Run '..configuration.command_prefix..'ahelp@' .. self.info.username .. ' for a list of commands.')
 return table.concat(t, '\n\n')

end

function administration:update_desc(chat, configuration)
 local group = self.database.administration.groups[tostring(chat)]
 local desc = 'Welcome to ' .. group.name .. '!\n'
 if group.motd then desc = desc .. group.motd .. '\n' end
 if group.director then
  local dir = self.database.users[tostring(group.director)]
  desc = desc .. '\nDirector: ' .. functions.build_name(dir.first_name, dir.last_name) .. ' [' .. dir.id .. ']\n'
 end
 local s = '\n'..configuration.command_prefix..'desc@' .. self.info.username .. ' for more information.'
 desc = desc:sub(1, 250-s:len()) .. s
 mattata.channel_set_about(chat, desc)
end

function administration:kick_user(chat, target, reason, configuration)
 mattata.kick_user(chat, target)
 local victim = target
 if self.database.users[tostring(target)] then
  victim = functions.build_name(
    self.database.users[tostring(target)].first_name,
    self.database.users[tostring(target)].last_name
   ) .. ' [' .. victim .. ']'
 end
 local group = self.database.administration.groups[tostring(chat)].name
 functions.handle_exception(self, victim..' kicked from '..group, reason, configuration)
end

function administration.init_command(self_, configuration_)
 administration.commands = {

  { -- generic, mostly autokicks
   triggers = { '' },

   privilege = 0,
   interior = true,

   action = function(self, msg, group, configuration)

    local rank = administration.get_rank(self, msg.from.id, msg.chat.id, configuration)
    local user = {}
    local from_id_str = tostring(msg.from.id)
    local chat_id_str = tostring(msg.chat.id)

    if rank < 2 then
     local from_name = functions.build_name(msg.from.first_name, msg.from.last_name)

     -- banned
     if rank == 0 then
      user.do_kick = true
      user.dont_unban = true
      user.reason = 'banned'
      user.output = 'Sorry, you are banned from ' .. msg.chat.title .. '.'
     elseif group.flags[2] and ( -- antisquig
      msg.text:match(functions.char.arabic)
      or msg.text:match(functions.char.rtl_override)
      or msg.text:match(functions.char.rtl_mark)
     ) then
      user.do_kick = true
      user.reason = 'antisquig'
      user.output = administration.flags[2].kicked:gsub('GROUPNAME', msg.chat.title)
     elseif group.flags[3] and ( -- antisquig++
      from_name:match(functions.char.arabic)
      or from_name:match(functions.char.rtl_override)
      or from_name:match(functions.char.rtl_mark)
     ) then
      user.do_kick = true
      user.reason = 'antisquig++'
      user.output = administration.flags[3].kicked:gsub('GROUPNAME', msg.chat.title)
     end

     -- antiflood
     if group.flags[5] then
      if not group.antiflood then
       group.antiflood = JSON.decode(JSON.encode(administration.antiflood))
      end
      if not administration.temp.flood[chat_id_str] then
       administration.temp.flood[chat_id_str] = {}
      end
      if not administration.temp.flood[chat_id_str][from_id_str] then
       administration.temp.flood[chat_id_str][from_id_str] = 0
      end
      if msg.sticker then -- Thanks Brazil for discarding switches.
       administration.temp.flood[chat_id_str][from_id_str] = administration.temp.flood[chat_id_str][from_id_str] + group.antiflood.sticker
      elseif msg.photo then
       administration.temp.flood[chat_id_str][from_id_str] = administration.temp.flood[chat_id_str][from_id_str] + group.antiflood.photo
      elseif msg.document then
       administration.temp.flood[chat_id_str][from_id_str] = administration.temp.flood[chat_id_str][from_id_str] + group.antiflood.document
      elseif msg.audio then
       administration.temp.flood[chat_id_str][from_id_str] = administration.temp.flood[chat_id_str][from_id_str] + group.antiflood.audio
      elseif msg.contact then
       administration.temp.flood[chat_id_str][from_id_str] = administration.temp.flood[chat_id_str][from_id_str] + group.antiflood.contact
      elseif msg.video then
       administration.temp.flood[chat_id_str][from_id_str] = administration.temp.flood[chat_id_str][from_id_str] + group.antiflood.video
      elseif msg.location then
       administration.temp.flood[chat_id_str][from_id_str] = administration.temp.flood[chat_id_str][from_id_str] + group.antiflood.location
      elseif msg.voice then
       administration.temp.flood[chat_id_str][from_id_str] = administration.temp.flood[chat_id_str][from_id_str] + group.antiflood.voice
      else
       administration.temp.flood[chat_id_str][from_id_str] = administration.temp.flood[chat_id_str][from_id_str] + group.antiflood.text
      end
      if administration.temp.flood[chat_id_str][from_id_str] > 99 then
       user.do_kick = true
       user.reason = 'antiflood'
       user.output = administration.flags[5].kicked:gsub('GROUPNAME', msg.chat.title)
       administration.temp.flood[chat_id_str][from_id_str] = nil
      end
     end

    end

    local new_user = user
    local new_rank = rank

    if msg.new_chat_member then

     -- I hate typing this out.
     local noob = msg.new_chat_member
     local noob_name = functions.build_name(noob.first_name, noob.last_name)

     -- We'll make a new table for the new guy, unless he's also
     -- the original guy.
     if msg.new_chat_member.id ~= msg.from.id then
      new_user = {}
      new_rank = administration.get_rank(self,noob.id, msg.chat.id, configuration)
     end

     if new_rank == 0 then
      new_user.do_kick = true
      new_user.dont_unban = true
      new_user.reason = 'banned'
      new_user.output = 'Sorry, you are banned from ' .. msg.chat.title .. '.'
     elseif new_rank == 1 then
      if group.flags[3] and ( -- antisquig++
       noob_name:match(functions.char.arabic)
       or noob_name:match(functions.char.rtl_override)
       or noob_name:match(functions.char.rtl_mark)
      ) then
       new_user.do_kick = true
       new_user.reason = 'antisquig++'
       new_user.output = administration.flags[3].kicked:gsub('GROUPNAME', msg.chat.title)
      elseif ( -- antibot
       group.flags[4]
       and noob.username
       and noob.username:match('bot$')
       and rank < 2
      ) then
       new_user.do_kick = true
       new_user.reason = 'antibot'
      end
     else
      -- Make the new user a group admin if he's a mod or higher.
      if msg.chat.type == 'supergroup' then
       mattata.channel_set_admin(msg.chat.id, msg.new_chat_member.id, 2)
      end
     end

    elseif msg.new_chat_title then
     if rank < 3 then
      mattata.rename_chat(msg.chat.id, group.name)
     else
      group.name = msg.new_chat_title
      if group.grouptype == 'supergroup' then
       administration.update_desc(self, msg.chat.id, configuration)
      end
     end
    elseif msg.new_chat_photo then
     if group.grouptype == 'group' then
      if rank < 3 then
       mattata.set_photo(msg.chat.id, group.photo)
      else
       group.photo = mattata.get_photo(msg.chat.id)
      end
     else
      group.photo = mattata.get_photo(msg.chat.id)
     end
    elseif msg.delete_chat_photo then
     if group.grouptype == 'group' then
      if rank < 3 then
       mattata.set_photo(msg.chat.id, group.photo)
      else
       group.photo = nil
      end
     else
      group.photo = nil
     end
    end

    if new_user ~= user and new_user.do_kick then
     administration.kick_user(self, msg.chat.id, msg.new_chat_member.id, new_user.reason, configuration)
     if new_user.output then
      functions.send_message(self, msg.new_chat_member.id, new_user.output)
     end
     if not new_user.dont_unban and msg.chat.type == 'supergroup' then
      telegram_api.unbanChatMember(self, { chat_id = msg.chat.id, user_id = msg.from.id } )
     end
    end

    if group.flags[5] and user.do_kick and not user.dont_unban then
     if group.autokicks[from_id_str] then
      group.autokicks[from_id_str] = group.autokicks[from_id_str] + 1
     else
      group.autokicks[from_id_str] = 1
     end
     if group.autokicks[from_id_str] >= group.autoban then
      group.autokicks[from_id_str] = 0
      group.bans[from_id_str] = true
      user.dont_unban = true
      user.reason = 'antiflood autoban: ' .. user.reason
      user.output = user.output .. '\nYou have been banned for being autokicked too many times.'
     end
    end

    if user.do_kick then
     administration.kick_user(self, msg.chat.id, msg.from.id, user.reason, configuration)
     if user.output then
      functions.send_message(self, msg.from.id, user.output)
     end
     if not user.dont_unban and msg.chat.type == 'supergroup' then
      telegram_api.unbanChatMember(self, { chat_id = msg.chat.id, user_id = msg.from.id } )
     end
    end

    if msg.new_chat_member and not new_user.do_kick then
     local output = administration.get_desc(self, msg.chat.id, configuration)
     functions.send_message(self, msg.new_chat_member.id, output, true, nil, true)
    end

    -- Last active time for group listing.
    if msg.text:len() > 0 then
     for i,v in pairs(self.database.administration.activity) do
      if v == chat_id_str then
       table.remove(self.database.administration.activity, i)
       table.insert(self.database.administration.activity, 1, chat_id_str)
      end
     end
    end

    return true

   end
  },

  { -- /groups
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('groups', true).table,

   command = 'groups \\[query]',
   privilege = 1,
   interior = false,
   doc = 'Returns a list of groups matching the query, or a list of all administrated groups.',

   action = function(self, msg, _, configuration)
    local input = functions.input(msg.text)
    local search_res = ''
    local grouplist = ''
    for _, chat_id_str in ipairs(self.database.administration.activity) do
     local group = self.database.administration.groups[chat_id_str]
     if (not group.flags[1]) and group.link then -- no unlisted or unlinked groups
      grouplist = grouplist .. '• [' .. functions.md_escape(group.name) .. '](' .. group.link .. ')\n'
      if input and string.match(group.name:lower(), input:lower()) then
       search_res = search_res .. '• [' .. functions.md_escape(group.name) .. '](' .. group.link .. ')\n'
      end
     end
    end
    local output
    if search_res ~= '' then
     output = '*Groups matching* _' .. input .. '_ *:*\n' .. search_res
    elseif grouplist ~= '' then
     output = '*Groups:*\n' .. grouplist
    else
     output = 'There are currently no listed groups.'
    end
    functions.send_message(self, msg.chat.id, output, true, nil, true)
   end
  },

  { -- /ahelp
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('ahelp', true).table,

   command = 'ahelp \\[command]',
   privilege = 1,
   interior = false,
   doc = 'Returns a list of realm-related commands for your rank (in a private message), or command-specific help.',

   action = function(self, msg, group, configuration)
    local rank = administration.get_rank(self, msg.from.id, msg.chat.id, configuration)
    local input = functions.get_word(msg.text_lower, 2)
    if input then
     input = input:gsub('^'..configuration.command_prefix..'', '')
     local doc
     for _,action in ipairs(administration.commands) do
      if action.keyword == input then
       doc = ''..configuration.command_prefix..'' .. action.command:gsub('\\','') .. '\n' .. action.doc
       break
      end
     end
     if doc then
      local output = '*Help for* _' .. input .. '_ :\n```\n' .. doc .. '\n```'
      functions.send_message(self, msg.chat.id, output, true, nil, true)
     else
      local output = 'Sorry, there is no help for that command.\n'..configuration.command_prefix..'ahelp@'..self.info.username
      functions.send_reply(self, msg, output)
     end
    else
     local output = '*Commands for ' .. administration.ranks[rank] .. ':*\n'
     for i = 1, rank do
      for _, val in ipairs(administration.temp.help[i]) do
       output = output .. '• ' .. configuration.command_prefix .. val .. '\n'
      end
     end
     output = output .. 'Arguments: <required> \\[optional]'
     if functions.send_message(self, msg.from.id, output, true, nil, true) then
      if msg.from.id ~= msg.chat.id then
       functions.send_reply(self, msg, 'I have sent you the requested information in a private message.')
      end
     else
      functions.send_message(self, msg.chat.id, output, true, nil, true)
     end
    end
   end
  },

  { -- /ops
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('ops'):t('oplist').table,

   command = 'ops',
   privilege = 1,
   interior = true,
   doc = 'Returns a list of moderators and the director for the group.',

   action = function(self, msg, group, configuration)
    local modstring = ''
    for k,_ in pairs(group.mods) do
     modstring = modstring .. administration.mod_format(self, k)
    end
    if modstring ~= '' then
     modstring = '*Moderators for ' .. msg.chat.title .. ':*\n' .. modstring
    end
    local dirstring = ''
    if group.director then
     local dir = self.database.users[tostring(group.director)]
     if dir then
      dirstring = '*Director:* ' .. functions.md_escape(functions.build_name(dir.first_name, dir.last_name)) .. ' `[' .. dir.id .. ']`'
     else
      dirstring = '*Director:* Unknown `[' .. group.director .. ']`'
     end
    end
    local output = functions.trim(modstring) ..'\n\n' .. functions.trim(dirstring)
    if output == '\n\n' then
     output = 'There are currently no moderators for this group.'
    end
    functions.send_message(self, msg.chat.id, output, true, nil, true)
   end

  },

  { -- /desc
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('desc'):t('description').table,

   command = 'description',
   privilege = 1,
   interior = true,
   doc = 'Returns a description of the group (in a private message), including its motd, rules, flags, director, and moderators.',

   action = function(self, msg, group, configuration)
    local output = administration.get_desc(self, msg.chat.id, configuration)
    if functions.send_message(self, msg.from.id, output, true, nil, true) then
     if msg.from.id ~= msg.chat.id then
      functions.send_reply(self, msg, 'I have sent you the requested information in a private message.')
     end
    else
     functions.send_message(self, msg.chat.id, output, true, nil, true)
    end
   end
  },

  { -- /rules
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('rules?', true).table,

   command = 'rules \\[i]',
   privilege = 1,
   interior = true,
   doc = 'Returns the group\'s list of rules, or a specific rule.',

   action = function(self, msg, group, configuration)
    local output
    local input = functions.get_word(msg.text_lower, 2)
    input = tonumber(input)
    if #group.rules > 0 then
     if input and group.rules[input] then
      output = '*' .. input .. '.* ' .. group.rules[input]
     else
      output = '*Rules for ' .. msg.chat.title .. ':*\n'
      for i,v in ipairs(group.rules) do
       output = output .. '*' .. i .. '.* ' .. v .. '\n'
      end
     end
    else
     output = 'No rules have been set for ' .. msg.chat.title .. '.'
    end
    functions.send_message(self, msg.chat.id, output, true, nil, true)
   end
  },

  { -- /motd
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('motd'):t('qotd').table,

   command = 'motd',
   privilege = 1,
   interior = true,
   doc = 'Returns the group\'s message of the day.',

   action = function(self, msg, group, configuration)
    local output = 'No MOTD has been set for ' .. msg.chat.title .. '.'
    if group.motd then
     output = '*MOTD for ' .. msg.chat.title .. ':*\n' .. group.motd
    end
    functions.send_message(self, msg.chat.id, output, true, nil, true)
   end
  },

  { -- /link
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('link').table,

   command = 'link',
   privilege = 1,
   interior = true,
   doc = 'Returns the group\'s link.',

   action = function(self, msg, group, configuration)
    local output = 'No link has been set for ' .. msg.chat.title .. '.'
    if group.link then
     output = '[' .. msg.chat.title .. '](' .. group.link .. ')'
    end
    functions.send_message(self, msg.chat.id, output, true, nil, true)
   end
  },

  { -- /kick
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('kick', true).table,

   command = 'kick <user>',
   privilege = 2,
   interior = true,
   doc = 'Removes a user from the group. The target may be specified via reply, username, or ID.',

   action = function(self, msg, group, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local output = ''
     for _, target in ipairs(targets) do
      if target.err then
       output = output .. target.err .. '\n'
      elseif target.rank >= administration.get_rank(self, msg.from.id, msg.chat.id, configuration) then
       output = output .. target.name .. ' is too privileged to be kicked.\n'
      else
       administration.kick_user(self, msg.chat.id, target.id, 'kicked by ' .. functions.build_name(msg.from.first_name, msg.from.last_name), configuration)
       output = output .. target.name .. ' has been kicked.\n'
       if msg.chat.type == 'supergroup' then
        telegram_api.unbanChatMember(self, { chat_id = msg.chat.id, user_id = target.id } )
       end
      end
     end
     functions.send_reply(self, msg, output)
    else
     functions.send_reply(self, msg, 'Please specify a user or users via reply, username, or ID.')
    end
   end
  },

  { -- /ban
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('ban', true).table,

   command = 'ban <user>',
   privilege = 2,
   interior = true,
   doc = 'Bans a user from the group. The target may be specified via reply, username, or ID.',

   action = function(self, msg, group, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local output = ''
     for _, target in ipairs(targets) do
      if target.err then
       output = output .. target.err .. '\n'
      elseif group.bans[target.id_str] then
       output = output .. target.name .. ' is already banned.\n'
      elseif target.rank >= administration.get_rank(self, msg.from.id, msg.chat.id, configuration) then
       output = output .. target.name .. ' is too privileged to be banned.\n'
      else
       administration.kick_user(self, msg.chat.id, target.id, 'banned by ' .. functions.build_name(msg.from.first_name, msg.from.last_name), configuration)
       output = output .. target.name .. ' has been banned.\n'
       group.mods[target.id_str] = nil
       group.bans[target.id_str] = true
      end
     end
     functions.send_reply(self, msg, output)
    else
     functions.send_reply(self, msg, 'Please specify a user or users via reply, username, or ID.')
    end
   end
  },

  { -- /unban
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('unban', true).table,

   command = 'unban <user>',
   privilege = 2,
   interior = true,
   doc = 'Unbans a user from the group. The target may be specified via reply, username, or ID.',

   action = function(self, msg, group, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local output = ''
     for _, target in ipairs(targets) do
      if target.err then
       output = output .. target.err .. '\n'
      else
       if not group.bans[target.id_str] then
        output = output .. target.name .. ' is not banned.\n'
       else
        output = output .. target.name .. ' has been unbanned.\n'
        group.bans[target.id_str] = nil
       end
       if msg.chat.type == 'supergroup' then
        telegram_api.unbanChatMember(self, { chat_id = msg.chat.id, user_id = target.id } )
       end
      end
     end
     functions.send_reply(self, msg, output)
    else
     functions.send_reply(self, msg, 'Please specify a user or users via reply, username, or ID.')
    end
   end
  },

  { -- /setmotd
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('setmotd', true):t('setqotd', true).table,

   command = 'setmotd <motd>',
   privilege = configuration_.administration.moderator_setmotd and 2 or 3,
   interior = true,
   doc = 'Sets the group\'s message of the day. Markdown is supported. Pass "--" to delete the message.',

   action = function(self, msg, group, configuration)
    local input = functions.input(msg.text)
    local quoted = functions.build_name(msg.from.first_name, msg.from.last_name)
    if msg.reply_to_message and #msg.reply_to_message.text > 0 then
     input = msg.reply_to_message.text
     if msg.reply_to_message.forward_from then
      quoted = functions.build_name(msg.reply_to_message.forward_from.first_name, msg.reply_to_message.forward_from.last_name)
     else
      quoted = functions.build_name(msg.reply_to_message.from.first_name, msg.reply_to_message.from.last_name)
     end
    end
    if input then
     if input == '--' or input == functions.char.em_dash then
      group.motd = nil
      functions.send_reply(self, msg, 'The MOTD has been cleared.')
     else
      if msg.text:match('^/setqotd') then
       input = '_' .. functions.md_escape(input) .. '_\n - ' .. functions.md_escape(quoted)
      end
      group.motd = input
      local output = '*MOTD for ' .. msg.chat.title .. ':*\n' .. input
      functions.send_message(self, msg.chat.id, output, true, nil, true)
     end
     if group.grouptype == 'supergroup' then
      administration.update_desc(self, msg.chat.id, configuration)
     end
    else
     functions.send_reply(self, msg, 'Please specify the new message of the day.')
    end
   end
  },

  { -- /setrules
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('setrules', true).table,

   command = 'setrules <rules>',
   privilege = 3,
   interior = true,
   doc = 'Sets the group\'s rules. Rules will be automatically numbered. Separate rules with a new line. Markdown is supported. Pass "--" to delete the rules.',

   action = function(self, msg, group, configuration)
    local input = msg.text:match('^'..configuration.command_prefix..'setrules[@'..self.info.username..']*(.+)')
    if input == ' --' or input == ' ' .. functions.char.em_dash then
     group.rules = {}
     functions.send_reply(self, msg, 'The rules have been cleared.')
    elseif input then
     group.rules = {}
     input = functions.trim(input) .. '\n'
     local output = '*Rules for ' .. msg.chat.title .. ':*\n'
     local i = 1
     for l in input:gmatch('(.-)\n') do
      output = output .. '*' .. i .. '.* ' .. l .. '\n'
      i = i + 1
      table.insert(group.rules, functions.trim(l))
     end
     functions.send_message(self, msg.chat.id, output, true, nil, true)
    else
     functions.send_reply(self, msg, 'Please specify the new rules.')
    end
   end
  },

  { -- /changerule
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('changerule', true).table,

   command = 'changerule <i> <rule>',
   privilege = 3,
   interior = true,
   doc = 'Changes a single rule. Pass "--" to delete the rule. If i is a number for which there is no rule, adds a rule by the next incremented number.',

   action = function(self, msg, group, configuration)
    local input = functions.input(msg.text)
    local output = 'usage: `'..configuration.command_prefix..'changerule <i> <newrule>`'
    if input then
     local rule_num = tonumber(input:match('^%d+'))
     local new_rule = functions.input(input)
     if not rule_num then
      output = 'Please specify which rule you want to change.'
     elseif not new_rule then
      output = 'Please specify the new rule.'
     elseif new_rule == '--' or new_rule == functions.char.em_dash then
      if group.rules[rule_num] then
       table.remove(group.rules, rule_num)
       output = 'That rule has been deleted.'
      else
       output = 'There is no rule with that number.'
      end
     else
      if not group.rules[rule_num] then
       rule_num = #group.rules + 1
      end
      group.rules[rule_num] = new_rule
      output = '*' .. rule_num .. '*. ' .. new_rule
     end
    end
    functions.send_reply(self, msg, output, true)
   end
  },

  { -- /setlink
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('setlink', true).table,

   command = 'setlink <link>',
   privilege = 3,
   interior = true,
   doc = 'Sets the group\'s join link. Pass "--" to regenerate the link.',

   action = function(self, msg, group, configuration)
    local input = functions.input(msg.text)
    if input == '--' or input == functions.char.em_dash then
     group.link = mattata.export_link(msg.chat.id)
     functions.send_reply(self, msg, 'The link has been regenerated.')
    elseif input then
     group.link = input
     local output = '[' .. msg.chat.title .. '](' .. input .. ')'
     functions.send_message(self, msg.chat.id, output, true, nil, true)
    else
     functions.send_reply(self, msg, 'Please specify the new link.')
    end
   end
  },

  { -- /alist
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('alist').table,

   command = 'alist',
   privilege = 3,
   interior = true,
   doc = 'Returns a list of administrators. Owner is denoted with a star character.',

   action = function(self, msg, group, configuration)
    local output = '*Administrators:*\n'
    output = output .. administration.mod_format(self, configuration.admin):gsub('\n', ' ★\n')
    for id,_ in pairs(self.database.administration.admins) do
     output = output .. administration.mod_format(self, id)
    end
    functions.send_message(self, msg.chat.id, output, true, nil, true)
   end
  },

  { -- /flags
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('flags?', true).table,

   command = 'flag \\[i] ...',
   privilege = 3,
   interior = true,
   doc = 'Returns a list of flags or toggles the specified flags.',

   action = function(self, msg, group, configuration)
    local output = ''
    local input = functions.input(msg.text)
    if input then
     for i in input:gmatch('%g+') do
      local n = tonumber(i)
      if n and administration.flags[n] then
       if group.flags[n] == true then
        group.flags[n] = false
        output = output .. administration.flags[n].disabled .. '\n'
       else
        group.flags[n] = true
        output = output .. administration.flags[n].enabled .. '\n'
       end
      end
     end
     if output == '' then
      input = false
     end
    end
    if not input then
     output = '*Flags for ' .. msg.chat.title .. ':*\n'
     for i, flag in ipairs(administration.flags) do
      local status = group.flags[i] or false
      output = output .. '*' .. i .. '. ' .. flag.name .. '* `[' .. tostring(status) .. ']`\n• ' .. flag.desc .. '\n'
     end
    end
    functions.send_message(self, msg.chat.id, output, true, nil, true)
   end
  },

  { -- /antiflood
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('antiflood', true).table,

   command = 'antiflood \\[<type> <i>]',
   privilege = 3,
   interior = true,
   doc = 'Returns a list of antiflood values or sets one.',

   action = function(self, msg, group, configuration)
    if not group.flags[5] then
     functions.send_message(self, msg.chat.id, 'antiflood is not enabled. Use `'..configuration.command_prefix..'flag 5` to enable it.', true, nil, true)
    else
     if not group.antiflood then
      group.antiflood = JSON.decode(JSON.encode(administration.antiflood))
     end
     local input = functions.input(msg.text_lower)
     local output
     if input then
      local key, val = input:match('(%a+) (%d+)')
      if not key or not val or not tonumber(val) then
       output = 'Not a valid message type or number.'
      elseif key == 'autoban' then
       group.autoban = tonumber(val)
       output = 'Users will now be autobanned after *' .. val .. '* autokicks.'
      else
       group.antiflood[key] = tonumber(val)
       output = '*' .. key:gsub('^%l', string.upper) .. '* messages are now worth *' .. val .. '* points.'
      end
     else
      output = 'usage: `'..configuration.command_prefix..'antiflood <type> <i>`\nexample: `'..configuration.command_prefix..'antiflood text 5`\nUse this command to configurationure the point values for each message type. When a user reaches 100 points, he is kicked. The points are reset each minute. The current values are:\n'
      for k,v in pairs(group.antiflood) do
       output = output .. '*'..k..':* `'..v..'`\n'
      end
      output = output .. 'Users will be banned automatically after *' .. group.autoban .. '* autokicks. Configure this with the *autoban* keyword.'
     end
     functions.send_message(self, msg.chat.id, output, true, msg.message_id, true)
    end
   end
  },

  { -- /mod
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('mod', true).table,

   command = 'mod <user>',
   privilege = 3,
   interior = true,
   doc = 'Promotes a user to a moderator. The target may be specified via reply, username, or ID.',

   action = function(self, msg, group, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local output = ''
     for _, target in ipairs(targets) do
      if target.err then
       output = output .. target.err .. '\n'
      else
       if target.rank > 1 then
        output = output .. target.name .. ' is already a moderator or greater.\n'
       else
        output = output .. target.name .. ' is now a moderator.\n'
        group.mods[target.id_str] = true
        group.bans[target.id_str] = nil
       end
       if group.grouptype == 'supergroup' then
        local chat_member = telegram_api.getChatMember(self, { chat_id = msg.chat.id, user_id = target.id })
        if chat_member and chat_member.result.status == 'member' then
         mattata.channel_set_admin(msg.chat.id, target.id, 2)
        end
       end
      end
     end
     functions.send_reply(self, msg, output)
    else
     functions.send_reply(self, msg, 'Please specify a user or users via reply, username, or ID.')
    end
   end
  },

  { -- /demod
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('demod', true).table,

   command = 'demod <user>',
   privilege = 3,
   interior = true,
   doc = 'Demotes a moderator to a user. The target may be specified via reply, username, or ID.',

   action = function(self, msg, group, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local output = ''
     for _, target in ipairs(targets) do
      if target.err then
       output = output .. target.err .. '\n'
      else
       if not group.mods[target.id_str] then
        output = output .. target.name .. ' is not a moderator.\n'
       else
        output = output .. target.name .. ' is no longer a moderator.\n'
        group.mods[target.id_str] = nil
       end
       if group.grouptype == 'supergroup' then
        mattata.channel_set_admin(msg.chat.id, target.id, 0)
       end
      end
     end
     functions.send_reply(self, msg, output)
    else
     functions.send_reply(self, msg, 'Please specify a user or users via reply, username, or ID.')
    end
   end
  },

  { -- /dir
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('dir', true).table,

   command = 'dir <user>',
   privilege = 4,
   interior = true,
   doc = 'Promotes a user to the director. The current director will be replaced. The target may be specified via reply, username, or ID.',

   action = function(self, msg, group, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local target = targets[1]
     if target.err then
      functions.send_reply(self, msg, target.err)
     else
      if group.director == target.id then
       functions.send_reply(self, msg, target.name .. ' is already the director.')
      else
       group.bans[target.id_str] = nil
       group.mods[target.id_str] = nil
       group.director = target.id
       functions.send_reply(self, msg, target.name .. ' is the new director.')
      end
      if group.grouptype == 'supergroup' then
       local chat_member = telegram_api.getChatMember(self, { chat_id = msg.chat.id, user_id = target.id })
       if chat_member and chat_member.result.status == 'member' then
        mattata.channel_set_admin(msg.chat.id, target.id, 2)
       end
       administration.update_desc(self, msg.chat.id, configuration)
      end
     end
    else
     functions.send_reply(self, msg, 'Please specify a user via reply, username, or ID.')
    end
   end
  },

  { -- /dedir
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('dedir', true).table,

   command = 'dedir <user>',
   privilege = 4,
   interior = true,
   doc = 'Demotes the director to a user. The administrator will become the new director. The target may be specified via reply, username, or ID.',

   action = function(self, msg, group, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local target = targets[1]
     if target.err then
      functions.send_reply(self, msg, target.err)
     else
      if group.director ~= target.id then
       functions.send_reply(self, msg, target.name .. ' is not the director.')
      else
       group.director = msg.from.id
       functions.send_reply(self, msg, target.name .. ' is no longer the director.')
      end
      if group.grouptype == 'supergroup' then
       mattata.channel_set_admin(msg.chat.id, target.id, 0)
       administration.update_desc(self, msg.chat.id, configuration)
      end
     end
    else
     functions.send_reply(self, msg, 'Please specify a user via reply, username, or ID.')
    end
   end
  },

  { -- /hammer
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('hammer', true).table,

   command = 'hammer <user>',
   privilege = 4,
   interior = false,
   doc = 'Bans a user from all groups. The target may be specified via reply, username, or ID.',

   action = function(self, msg, group, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local output = ''
     for _, target in ipairs(targets) do
      if target.err then
       output = output .. target.err .. '\n'
      elseif self.database.administration.globalbans[target.id_str] then
       output = output .. target.name .. ' is already globally banned.\n'
      elseif target.rank >= administration.get_rank(self, msg.from.id, msg.chat.id, configuration) then
       output = output .. target.name .. ' is too privileged to be globally banned.\n'
      else
       if group then
        administration.kick_user(self, msg.chat.id, target.id, 'hammered by ' .. functions.build_name(msg.from.first_name, msg.from.last_name), configuration)
       end
       if #targets == 1 then
        for k,v in pairs(self.database.administration.groups) do
         if not v.flags[6] then
          v.mods[target.id_str] = nil
          mattata.kick_user(k, target.id)
         end
        end
       end
       self.database.administration.globalbans[target.id_str] = true
       if group and group.flags[6] == true then
        group.mods[target.id_str] = nil
        group.bans[target.id_str] = true
        output = output .. target.name .. ' has been globally and locally banned.\n'
       else
        output = output .. target.name .. ' has been globally banned.\n'
       end
      end
     end
     functions.send_reply(self, msg, output)
    else
     functions.send_reply(self, msg, 'Please specify a user or users via reply, username, or ID.')
    end
   end
  },

  { -- /unhammer
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('unhammer', true).table,

   command = 'unhammer <user>',
   privilege = 4,
   interior = false,
   doc = 'Removes a global ban. The target may be specified via reply, username, or ID.',

   action = function(self, msg, group, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local output = ''
     for _, target in ipairs(targets) do
      if target.err then
       output = output .. target.err .. '\n'
      elseif not self.database.administration.globalbans[target.id_str] then
       output = output .. target.name .. ' is not globally banned.\n'
      else
       self.database.administration.globalbans[target.id_str] = nil
       output = output .. target.name .. ' has been globally unbanned.\n'
      end
     end
     functions.send_reply(self, msg, output)
    else
     functions.send_reply(self, msg, 'Please specify a user or users via reply, username, or ID.')
    end
   end
  },

  { -- /admin
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('admin', true).table,

   command = 'admin <user>',
   privilege = 5,
   interior = false,
   doc = 'Promotes a user to an administrator. The target may be specified via reply, username, or ID.',

   action = function(self, msg, _, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local output = ''
     for _, target in ipairs(targets) do
      if target.err then
       output = output .. target.err .. '\n'
      elseif target.rank >= 4 then
       output = output .. target.name .. ' is already an administrator or greater.\n'
      else
       for _, group in pairs(self.database.administration.groups) do
        group.mods[target.id_str] = nil
       end
       self.database.administration.admins[target.id_str] = true
       output = output .. target.name .. ' is now an administrator.\n'
      end
     end
     functions.send_reply(self, msg, output)
    else
     functions.send_reply(self, msg, 'Please specify a user or users via reply, username, or ID.')
    end
   end
  },

  { -- /deadmin
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('deadmin', true).table,

   command = 'deadmin <user>',
   privilege = 5,
   interior = false,
   doc = 'Demotes an administrator to a user. The target may be specified via reply, username, or ID.',

   action = function(self, msg, _, configuration)
    local targets = administration.get_targets(self, msg, configuration)
    if targets then
     local output = ''
     for _, target in ipairs(targets) do
      if target.err then
       output = output .. target.err .. '\n'
      elseif target.rank ~= 4 then
       output = output .. target.name .. ' is not an administrator.\n'
      else
       for chat_id, group in pairs(self.database.administration.groups) do
        if group.grouptype == 'supergroup' then
         mattata.channel_set_admin(chat_id, target.id, 0)
        end
       end
       self.database.administration.admins[target.id_str] = nil
       output = output .. target.name .. ' is no longer an administrator.\n'
      end
     end
     functions.send_reply(self, msg, output)
    else
     functions.send_reply(self, msg, 'Please specify a user or users via reply, username, or ID.')
    end
   end
  },

  { -- /gadd
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('gadd', true).table,

   command = 'gadd \\[i] ...',
   privilege = 5,
   interior = false,
   doc = 'Adds a group to the administration system. Pass numbers as arguments to enable those flags immediately.\nExample usage:\n\t/gadd 1 4 5\nThis would add a group and enable the unlisted flag, antibot, and antiflood.',

   action = function(self, msg, group, configuration)
    if msg.chat.id == msg.from.id then
     functions.send_message(self, msg.chat.id, 'This is not a group.')
    elseif group then
     functions.send_reply(self, msg, 'I am already administrating this group.')
    else
     local output = 'I am now administrating this group.'
     local flags = {}
     for i = 1, #administration.flags do
      flags[i] = false
     end
     local input = functions.input(msg.text)
     if input then
      for i in input:gmatch('%g+') do
       local n = tonumber(i)
       if n and administration.flags[n] and flags[n] ~= true then
        flags[n] = true
        output = output .. '\n' .. administration.flags[n].short
       end
      end
     end
     self.database.administration.groups[tostring(msg.chat.id)] = {
      mods = {},
      director = msg.from.id,
      bans = {},
      flags = flags,
      rules = {},
      grouptype = msg.chat.type,
      name = msg.chat.title,
      link = mattata.export_link(msg.chat.id),
      photo = mattata.get_photo(msg.chat.id),
      founded = os.time(),
      autokicks = {},
      autoban = 3
     }
     administration.update_desc(self, msg.chat.id, configuration)
     table.insert(self.database.administration.activity, tostring(msg.chat.id))
     functions.send_reply(self, msg, output)
     mattata.channel_set_admin(msg.chat.id, self.info.id, 2)
    end
   end
  },

  { -- /grem
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('grem', true):t('gremove', true).table,

   command = 'gremove \\[chat]',
   privilege = 5,
   interior = false,
   doc = 'Removes a group from the administration system.',

   action = function(self, msg)
    local input = functions.input(msg.text) or tostring(msg.chat.id)
    local output
    if self.database.administration.groups[input] then
     local chat_name = self.database.administration.groups[input].name
     self.database.administration.groups[input] = nil
     for i,v in ipairs(self.database.administration.activity) do
      if v == input then
       table.remove(self.database.administration.activity, i)
      end
     end
     output = 'I am no longer administrating _' .. functions.md_escape(chat_name) .. '_.'
    else
     if input == tostring(msg.chat.id) then
      output = 'I do not administrate this group.'
     else
      output = 'I do not administrate that group.'
     end
    end
    functions.send_message(self, msg.chat.id, output, true, nil, true)
   end
  },

  { -- /glist
   triggers = functions.triggers(self_.info.username, configuration_.command_prefix):t('glist', false).table,

   command = 'glist',
   privilege = 5,
   interior = false,
   doc = 'Returns a list (in a private message) of all administrated groups with their directors and links.',

   action = function(self, msg, group, configuration)
    local output = ''
    if functions.table_size(self.database.administration.groups) > 0 then
     for k,v in pairs(self.database.administration.groups) do
      output = output .. '[' .. functions.md_escape(v.name) .. '](' .. v.link .. ') `[' .. k .. ']`\n'
      if v.director then
       local dir = self.database.users[tostring(v.director)]
       output = output .. '★ ' .. functions.md_escape(functions.build_name(dir.first_name, dir.last_name)) .. ' `[' .. dir.id .. ']`\n'
      end
     end
    else
     output = 'There are no groups.'
    end
    if functions.send_message(self, msg.from.id, output, true, nil, true) then
     if msg.from.id ~= msg.chat.id then
      functions.send_reply(self, msg, 'I have sent you the requested information in a private message.')
     end
    end
   end
  }

 }

 administration.triggers = {''}

 -- Generate help messages and ahelp keywords.
 self_.database.administration.help = {}
 for i,_ in ipairs(administration.ranks) do
  administration.temp.help[i] = {}
 end
 for _,v in ipairs(administration.commands) do
  if v.command then
   table.insert(administration.temp.help[v.privilege], v.command)
   if v.doc then
    v.keyword = functions.get_word(v.command, 1)
   end
  end
 end
end

function administration:action(msg, configuration)
 for _,command in ipairs(administration.commands) do
  for _,trigger in pairs(command.triggers) do
   if msg.text_lower:match(trigger) then
    if
     (command.interior and not self.database.administration.groups[tostring(msg.chat.id)])
     or administration.get_rank(self, msg.from.id, msg.chat.id, configuration) < command.privilege
    then
     break
    end
    local res = command.action(self, msg, self.database.administration.groups[tostring(msg.chat.id)], configuration)
    if res ~= true then
     return res
    end
   end
  end
 end
 return true
end

function administration:cron()
 administration.temp.flood = {}
 if os.date('%d') ~= self.database.administration.autokick_timer then
  self.database.administration.autokick_timer = os.date('%d')
  for _,v in pairs(self.database.administration.groups) do
   v.autokicks = {}
  end
 end
end

return administration
