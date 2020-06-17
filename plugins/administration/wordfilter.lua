--[[
    Copyright 2020 Matthew Hesketh <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local wordfilter = {}
local mattata = require('mattata')
local redis = require('libs.redis')

function wordfilter:init()
    wordfilter.commands = mattata.commands(self.info.username):command('wordfilter').table
    wordfilter.help = '/wordfilter - View a list of words which have been added to the chat\'s word filter.'
    wordfilter.bytes = {
        ['a'] = { 197, 229, 506, 507, 7680, 7681, 7834, 258, 259, 7862, 7863, 7854, 7855, 7856, 7857, 7858, 7859, 7860, 7861, 514, 515, 194, 226, 7852, 7853, 7844, 7845, 7846, 7847, 7850, 7851, 7848, 7849, 7842, 7843, 461, 462, 570, 11365, 550, 551, 480, 481, 7840, 7841, 196, 228, 478, 479, 192, 224, 512, 513, 193, 225, 256, 257, 256, 257, 195, 227, 260, 261, 260, 261, 260, 261, 7567, 65313, 65345 },
        ['b'] = { 7682, 7683, 7684, 7685, 7686, 7687, 579, 384, 7532, 7552, 385, 595, 386, 387, 65314, 65346 },
        ['c'] = { 231, 199, 231, 231, 269, 268, 269, 269, 265, 264, 263, 262, 7689, 7688, 267, 266, 572, 571, 42899, 42898, 65315, 65347 },
        ['d'] = { 271, 270, 273, 272, 396, 545, 7691, 7690, 7693, 7695, 7697, 7699, 598, 393, 599, 394, 240, 208, 240, 65316, 65348 },
        ['e'] = { 275, 274, 233, 201, 233, 283, 282, 283, 232, 200, 232, 517, 234, 202, 281, 280, 281, 235, 203, 279, 278, 7865, 7864, 7869, 7868, 277, 519, 553, 281, 7701, 7703, 7702, 7705, 7707, 7709, 279, 234, 234, 7867, 7866, 7875, 7874, 7873, 7877, 7876, 7871, 7870, 7879, 7878, 7865, 7864, 7865, 7864, 65317, 65349 },
        ['f'] = { 402, 401, 7711, 7710, 64256, 64257, 64258, 64259, 64260, 65318, 65350 },
        ['g'] = { 501, 500, 289, 288, 285, 284, 487, 486, 287, 286, 291, 290, 485, 484, 8513, 8370, 8458, 65319, 65351 },
        ['h'] = { 543, 542, 293, 292, 295, 294, 7721, 7720, 7723, 7722, 7830, 7715, 7714, 7717, 7716, 7718, 7719, 405, 502, 11368, 11367, 11382, 11381, 65320, 65352 },
        ['i'] = { 305, 299, 298, 237, 205, 464, 463, 301, 300, 236, 204, 238, 206, 304, 303, 302, 239, 207, 7726, 7727, 237, 205, 236, 204, 297, 296, 7881, 7880, 7883, 7882, 65321, 65353 },
        ['j'] = { 308, 309, 65322, 65354 },
        ['k'] = { 1050, 1082, 1036, 1116, 1178, 1179, 1180, 1181, 1082, 11277, 11325, 922, 954, 954, 922, 1008, 65323, 65355 },
        ['l'] = { 314, 313, 317, 7737, 7736, 7735, 7734, 318, 321, 322, 573, 410, 42825, 65324, 65356 },
        ['m'] = { 7743, 7745, 7747, 7535, 65325, 65357 },
        ['n'] = { 241, 209, 324, 326, 328, 626, 331, 414, 505, 565, 627, 7749, 7751, 7753, 7755, 65326, 65358 },
        ['o'] = { 9386, 9438, 9412, 65327, 65359, 8338, 7439, 7441, 7484, 7506, 333, 332, 333, 332, 7763, 7762, 699, 243, 211, 243, 466, 465, 242, 210, 244, 212, 246, 214, 245, 213, 337, 336, 7763, 248, 216, 42827, 42826, 491, 490, 491, 490, 561, 560, 7759, 7758, 559, 558, 42829, 42828, 7887, 7886, 244, 212, 7891, 7890, 7893, 7892, 7895, 7894, 7889, 7888, 7897, 7896, 417, 416, 7901, 7900, 7903, 7902, 7905, 7904, 7899, 7898, 7907, 7906, 7885, 7884, 7885, 7884, 7885, 7884, 42805, 42804, 7444, 339, 338, 630, 42831, 42830, 546, 547, 7445, 65327, 65359 },
        ['p'] = { 421, 7765, 7767, 65328, 65360 },
        ['q'] = { 672, 586, 587, 1306, 1307, 42840, 42841, 984, 985, 120110, 120214, 8474, 1382, 491, 65329, 65361 },
        ['r'] = { 174, 341, 344, 345, 529, 531, 636, 637, 638, 7769, 7771, 7773, 7775, 65330, 65362 },
        ['s'] = { 350, 351, 348, 349, 537, 7784, 7785, 7780, 7781, 7776, 7777, 7782, 7783, 352, 353, 346, 347, 7779, 65331, 65363 },
        ['t'] = { 427, 538, 539, 354, 355, 430, 648, 358, 359, 356, 357, 7786, 7787, 7788, 7789, 772, 7831, 7790, 7791, 65332, 65364 },
        ['u'] = { 363, 362, 250, 218, 468, 467, 249, 217, 365, 364, 251, 219, 252, 220, 367, 366, 371, 370, 361, 360, 369, 368, 533, 532, 7795, 7794, 7797, 7796, 7799, 7798, 7801, 7800, 7803, 7802, 470, 469, 472, 471, 474, 473, 476, 475, 7911, 7910, 361, 360, 7909, 7908, 432, 431, 7915, 7914, 7917, 7916, 7919, 7918, 7913, 7912, 7921, 7920, 7531, 65333, 65365 },
        ['v'] = { 7805, 7804, 7807, 7806, 42846, 65334, 65366 },
        ['w'] = { 7810, 7811, 7808, 7809, 372, 373, 7832, 7812, 7813, 7814, 7815, 7816, 7817, 653, 684, 65335, 65367 },
        ['x'] = { 1093, 1203, 1277, 1279, 926, 958, 935, 967, 885, 885, 967, 935, 967, 739, 215, 9587, 10005, 10006, 10799, 10007, 10008, 128500, 128502, 9746, 128501, 128503, 9747, 128937, 10060, 10062, 10761, 128473, 120091, 120117, 12584, 12490, 12513, 1488, 20034, 13317, 5815, 5816, 1604, 7821, 7820, 7819, 7818, 7565, 65336, 65368 },
        ['y'] = { 11433, 11432, 1091, 1059, 1118, 1038, 1091, 1091, 1141, 1140, 933, 910, 910, 8029, 8025, 8027, 8031, 8170, 8168, 8169, 65337, 65369 },
        ['z'] = { 11405, 11404, 918, 950, 918, 382, 381, 380, 379, 7826, 7827, 378, 7828, 7829, 7824, 7825, 377, 656, 657, 549, 437, 438, 20057, 20043, 8484, 65338, 65370 }
    }
end

function wordfilter:on_new_message(message)
    if message.chat.type == 'supergroup' and mattata.get_setting(message.chat.id, 'word filter') and not mattata.is_group_admin(message.chat.id, message.from.id) then
        local base = message.text:lower()
        for char, variations in pairs(wordfilter.bytes) do
            for _, variation in pairs(variations) do
                base = base:gsub(utf8.char(variation), char)
            end
        end
        base = base:gsub('[^%w \n\t\r]', '') -- Trim everything apart from alpha-numerical characters and spaces.
        local words = redis:smembers('word_filter:' .. message.chat.id)
        if words and #words > 0 then
            for _, v in pairs(words) do
                if base:match('^' .. v:lower() .. '$') or base:match('^' .. v:lower() .. ' ') or base:match(' ' .. v:lower() .. ' ') or base:match(' ' .. v:lower() .. '$') then
                    mattata.delete_message(message.chat.id, message.message_id)
                    local action = mattata.get_setting(message.chat.id, 'ban not kick') and mattata.ban_chat_member or mattata.kick_chat_member
                    local success = action(message.chat.id, message.from.id)
                    if success then
                        if mattata.get_setting(message.chat.id, 'log administrative actions') then
                            local log_chat = mattata.get_log_chat(message.chat.id)
                            mattata.send_message(log_chat, string.format('<pre>%s [%s] has kicked %s [%s] from %s [%s] for sending one or more prohibited words.</pre>', mattata.escape_html(self.info.first_name), self.info.id, mattata.escape_html(message.from.first_name), message.from.id, mattata.escape_html(message.chat.title), message.chat.id), 'html')
                        end
                        mattata.send_message(message.chat.id, string.format('Kicked %s for sending one or more prohibited words.', message.from.username and '@' .. message.from.username or message.from.first_name))
                        self.is_command_done = true
                        break
                    end
                end
            end
        end
    end
end

function wordfilter:on_message(message, configuration, language)
    if message.chat.type ~= 'supergroup' then
        mattata.send_reply(message, language.errors.supergroup)
    elseif not mattata.is_group_admin(message.chat.id, message.from.id) then
        return mattata.send_reply(message, language.errors.admin)
    end
    local words = redis:smembers('word_filter:' .. message.chat.id)
    if #words < 1 then
        return mattata.send_reply(message, 'There are no words filtered in this chat. To add words to the filter, use /filter <word(s)>.')
    end
    return mattata.send_message(message.chat.id, 'Filtered words: ' .. table.concat(words, ', '))
end

return wordfilter