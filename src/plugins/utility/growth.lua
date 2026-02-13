--[[
    mattata v2.0 - Growth Plugin
    Tracks member join/leave events and shows chat growth statistics over time.
    Uses Redis daily counters with 48h TTL for automatic cleanup.
]]

local plugin = {}
plugin.name = 'growth'
plugin.category = 'utility'
plugin.description = 'Chat growth statistics over time'
plugin.commands = { 'growth', 'chatgrowth' }
plugin.help = '/growth - Show chat member join/leave statistics for the last 7 days.'
plugin.group_only = true

local tools = require('telegram-bot-lua.tools')

local function format_number(n)
    local s = tostring(n)
    local pos = #s % 3
    if pos == 0 then pos = 3 end
    local result = s:sub(1, pos)
    for i = pos + 1, #s, 3 do
        result = result .. ',' .. s:sub(i, i + 2)
    end
    return result
end

-- Format a net value with +/- prefix and right-alignment
local function format_net(n, width)
    local s
    if n > 0 then
        s = '+' .. tostring(n)
    elseif n < 0 then
        s = tostring(n)
    else
        s = '0'
    end
    return string.format('%' .. width .. 's', s)
end

function plugin.on_member_join(api, message, ctx)
    if not ctx.is_group then return end
    local date = os.date('!%Y-%m-%d')
    local key = string.format('growth:joins:%s:%s', message.chat.id, date)
    local count = ctx.redis.incr(key)
    if count == 1 then ctx.redis.expire(key, 691200) end
end

function plugin.on_chat_member_update(api, update, ctx)
    if not update.chat then return end
    local new_status = update.new_chat_member and update.new_chat_member.status
    if new_status == 'left' or new_status == 'kicked' then
        local date = os.date('!%Y-%m-%d')
        local key = string.format('growth:leaves:%s:%s', update.chat.id, date)
        local count = ctx.redis.incr(key)
        if count == 1 then ctx.redis.expire(key, 691200) end
    end
end

function plugin.on_message(api, message, ctx)
    local chat_id = message.chat.id
    local days = {}
    local total_joins = 0
    local total_leaves = 0

    -- Collect data for the last 7 days
    for i = 0, 6 do
        local timestamp = os.time() - (i * 86400)
        local date = os.date('!%Y-%m-%d', timestamp)
        local join_key = string.format('growth:joins:%s:%s', chat_id, date)
        local leave_key = string.format('growth:leaves:%s:%s', chat_id, date)
        local joins = tonumber(ctx.redis.get(join_key)) or 0
        local leaves = tonumber(ctx.redis.get(leave_key)) or 0
        local net = joins - leaves
        total_joins = total_joins + joins
        total_leaves = total_leaves + leaves
        table.insert(days, { date = date, joins = joins, leaves = leaves, net = net })
    end

    local total_net = total_joins - total_leaves

    -- Build output table
    local lines = {}
    table.insert(lines, 'Chat Growth \xe2\x80\x94 Last 7 Days')
    table.insert(lines, '')
    table.insert(lines, string.format('%-12s %6s %7s %6s', 'Date', 'Joins', 'Leaves', 'Net'))
    table.insert(lines, string.rep('-', 33))

    for _, day in ipairs(days) do
        table.insert(lines, string.format('%-12s %6d %7d %s',
            day.date, day.joins, day.leaves, format_net(day.net, 6)
        ))
    end

    table.insert(lines, string.rep('-', 33))
    table.insert(lines, string.format('%-12s %6d %7d %s',
        'Total:', total_joins, total_leaves, format_net(total_net, 6)
    ))

    -- Get current member count
    local member_count_text = ''
    local count_result = api.get_chat_member_count(chat_id)
    if count_result and count_result.result then
        member_count_text = '\n\nCurrent members: ' .. format_number(count_result.result)
    end

    local output = '<pre>' .. tools.escape_html(
        table.concat(lines, '\n')
    ) .. '</pre>' .. member_count_text

    return api.send_message(chat_id, output, { parse_mode = 'html' })
end

return plugin
