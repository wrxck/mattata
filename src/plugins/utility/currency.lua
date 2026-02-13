--[[
    mattata v2.0 - Currency Plugin
    Currency conversion using the frankfurter.app API (free, no key needed).
    Frankfurter uses ECB (European Central Bank) rates.
]]

local plugin = {}
plugin.name = 'currency'
plugin.category = 'utility'
plugin.description = 'Convert between currencies'
plugin.commands = { 'currency', 'convert', 'cash' }
plugin.help = '/currency <amount> <from> to <to> - Convert between currencies.\nExample: /currency 10 USD to EUR'

local http = require('src.core.http')

local tools = require('telegram-bot-lua.tools')

local function convert(amount, from, to)
    local request_url = string.format(
        'https://api.frankfurter.app/latest?amount=%.2f&from=%s&to=%s',
        amount, from:upper(), to:upper()
    )
    local data, _ = http.get_json(request_url)
    if not data then
        return nil, 'Currency conversion request failed. Check that the currency codes are valid.'
    end
    if data.message then
        return nil, 'API error: ' .. tostring(data.message)
    end
    if not data.rates then
        return nil, 'No conversion rates returned. Check your currency codes.'
    end
    local target_key = to:upper()
    if not data.rates[target_key] then
        return nil, 'Currency "' .. target_key .. '" is not supported.'
    end
    return {
        amount = data.amount,
        from = data.base,
        to = target_key,
        result = data.rates[target_key],
        date = data.date
    }
end

local function format_number(n)
    if n >= 1 then
        return string.format('%.2f', n)
    elseif n >= 0.01 then
        return string.format('%.4f', n)
    else
        return string.format('%.6f', n)
    end
end

function plugin.on_message(api, message, ctx)
    local input = message.args
    if not input or input == '' then
        return api.send_message(
            message.chat.id,
            'Please provide a conversion query.\nUsage: <code>/currency 10 USD to EUR</code>',
            { parse_mode = 'html' }
        )
    end

    -- Parse: <amount> <from> to <to>
    -- Also support: <amount> <from> <to>, <from> to <to> (assume amount=1)
    local amount, from, to

    -- Try: 10 USD to EUR / 10 USD in EUR
    amount, from, to = input:match('^([%d%.]+)%s*(%a+)%s+[tT][oO]%s+(%a+)$')
    if not amount then
        amount, from, to = input:match('^([%d%.]+)%s*(%a+)%s+[iI][nN]%s+(%a+)$')
    end
    -- Try: 10 USD EUR
    if not amount then
        amount, from, to = input:match('^([%d%.]+)%s*(%a+)%s+(%a+)$')
    end
    -- Try: USD to EUR (amount=1)
    if not amount then
        from, to = input:match('^(%a+)%s+[tT][oO]%s+(%a+)$')
        if from then
            amount = '1'
        end
    end
    -- Try: USD EUR (amount=1)
    if not amount then
        from, to = input:match('^(%a+)%s+(%a+)$')
        if from then
            amount = '1'
        end
    end

    if not amount or not from or not to then
        return api.send_message(
            message.chat.id,
            'Invalid format. Please use:\n<code>/currency 10 USD to EUR</code>\n<code>/currency USD EUR</code>',
            { parse_mode = 'html' }
        )
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        return api.send_message(message.chat.id, 'Please enter a valid positive number for the amount.')
    end
    if amount > 999999999 then
        return api.send_message(message.chat.id, 'Amount is too large.')
    end

    from = from:upper()
    to = to:upper()

    if from == to then
        return api.send_message(
            message.chat.id,
            string.format('<b>%s %s</b> = <b>%s %s</b>', format_number(amount), tools.escape_html(from), format_number(amount), tools.escape_html(to)),
            { parse_mode = 'html' }
        )
    end

    local result, err = convert(amount, from, to)
    if not result then
        return api.send_message(message.chat.id, err)
    end

    local output = string.format(
        '<b>%s %s</b> = <b>%s %s</b>\n<i>Rate as of %s (ECB)</i>',
        format_number(result.amount),
        tools.escape_html(result.from),
        format_number(result.result),
        tools.escape_html(result.to),
        tools.escape_html(result.date)
    )

    return api.send_message(message.chat.id, output, { parse_mode = 'html' })
end

return plugin
