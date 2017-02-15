--[[
    Copyright 2017 wrxck <matthew@matthewhesketh.com>
    This code is licensed under the MIT. See LICENSE for details.
]]

local game = {}

local mattata = require('mattata')
local socket = require('socket')
local json = require('dkjson')
local redis = require('mattata-redis')

function game:init()
    game.commands = mattata.commands(
        self.info.username
    ):command('game').table
    game.help = [[/game [stats] - Play a game of Tic-Tac-Toe. Use /game stats to view your current game statistics.]]
end

function game.get_stats(user_id, chat_id)
    local user_won = redis:get('games_won:' .. user_id)
    if not user_won then
        user_won = 0
    end
    local chat_won = redis:get('games_won:' .. chat_id .. ':' .. user_id)
    if not chat_won then
        chat_won = 0
    end
    local user_lost = redis:get('games_lost:' .. user_id)
    if not user_lost then
        user_lost = 0
    end
    local chat_lost = redis:get('games_lost:' .. chat_id .. ':' .. user_id)
    if not chat_lost then
        chat_lost = 0
    end
    local balance = redis:get('balance:' .. user_id)
    if not balance then
        balance = 0
    end
    return string.format(
        'Total wins: %s\nTotal wins in this chat: %s\nTotal losses: %s\nTotal losses in this chat: %s\nBalance: %s mattacoins',
        user_won,
        chat_won,
        user_lost,
        chat_lost,
        balance
    )
end

function game.set_stats(user_id, chat_id, set_type)
    local user_won = redis:get('games_won:' .. user_id)
    if not user_won then
        user_won = 0
    end
    local chat_won = redis:get('games_won:' .. chat_id .. ':' .. user_id)
    if not chat_won then
        chat_won = 0
    end
    local user_lost = redis:get('games_lost:' .. user_id)
    if not user_lost then
        user_lost = 0
    end
    local chat_lost = redis:get('games_lost:' .. chat_id .. ':' .. user_id)
    if not chat_lost then
        chat_lost = 0
    end
    local balance = redis:get('balance:' .. user_id)
    if not balance then
        balance = 0
    end
    if set_type == 'won' then
        user_won = tonumber(user_won) + 1
        redis:set(
            'games_won:' .. user_id,
            user_won
        )
        chat_won = tonumber(chat_won) + 1
        redis:set(
            'games_won:' .. chat_id .. ':' .. user_id,
            chat_won
        )
        balance = tonumber(balance) + 100
        redis:set(
            'balance:' .. user_id,
            balance
        )
    elseif set_type == 'lost' then
        user_lost = tonumber(user_lost) + 1
        redis:set(
            'games_lost:' .. user_id,
            user_lost
        )
        chat_lost = tonumber(chat_lost) + 1
        redis:set(
            'games_lost:' .. chat_id .. ':' .. user_id,
            chat_lost
        )
        balance = tonumber(balance) - 50
        redis:set(
            'balance:' .. user_id,
            balance
        )
    end
end

function game.get_keyboard(session_id, join_game)
    join_game = join_game or false
    local g = redis:get('games:noughts_and_crosses:' .. session_id)
    if not g then
        return false
    end
    g = json.decode(g)
    local keyboard = {
        ['inline_keyboard'] = {
            {
                {
                    ['text'] = g.moves.a1,
                    ['callback_data'] = 'game:' .. session_id .. ':a1'
                },
                {
                    ['text'] = g.moves.a2,
                    ['callback_data'] = 'game:' .. session_id .. ':a2'
                },
                {
                    ['text'] = g.moves.a3,
                    ['callback_data'] = 'game:' .. session_id .. ':a3'
                }
            },
            {
                {
                    ['text'] = g.moves.b1,
                    ['callback_data'] = 'game:' .. session_id .. ':b1'
                },
                {
                    ['text'] = g.moves.b2,
                    ['callback_data'] = 'game:' .. session_id .. ':b2'
                },
                {
                    ['text'] = g.moves.b3,
                    ['callback_data'] = 'game:' .. session_id .. ':b3'
                }
            },
            {
                {
                    ['text'] = g.moves.c1,
                    ['callback_data'] = 'game:' .. session_id .. ':c1'
                },
                {
                    ['text'] = g.moves.c2,
                    ['callback_data'] = 'game:' .. session_id .. ':c2'
                },
                {
                    ['text'] = g.moves.c3,
                    ['callback_data'] = 'game:' .. session_id .. ':c3'
                }
            }
        }
    }
    if join_game then
        table.insert(
            keyboard.inline_keyboard,
            {
                {
                    ['text'] = 'Join game',
                    ['callback_data'] = 'game:' .. session_id .. ':join_game'
                }
            }
        )
    end
    return keyboard
end


function game:on_callback_query(callback_query, message, configuration)
    local session_id = callback_query.data:match('^(%d+)%:')
    local g = redis:get('games:noughts_and_crosses:' .. session_id)
    if not g then
        return
    end
    g = json.decode(g)
    if g.is_over == true then
        return mattata.answer_callback_query(
            callback_query.id,
            'This game has already ended!'
        )
    elseif g.has_opponent == true and g.is_over == false then
        if callback_query.from.id == g.opponent.id then
            if g.opponent.is_go == false then
                return mattata.answer_callback_query(
                    callback_query.id,
                    'It\'s not your turn!'
                )
            end
        elseif callback_query.from.id == g.player.id then
            if g.player.is_go == false then
                return mattata.answer_callback_query(
                    callback_query.id,
                    'It\'s not your turn!'
                )
            end
        end
        if not callback_query.data:match('^%d+%:%a%d$') then
            return
        end
        local pos = callback_query.data:match('^%d+%:(%a%d)$')
        local move = false
        if callback_query.from.id ~= g.opponent.id and callback_query.from.id ~= g.player.id then
            return mattata.answer_callback_query(
                callback_query.id,
                'You are not part of this game!'
            )
        elseif callback_query.from.id == g.player.id then
            g.player.is_go = false
            g.opponent.is_go = true
            move = g.player.move
        elseif callback_query.from.id == g.opponent.id then
            g.player.is_go = true
            g.opponent.is_go = false
            move = g.opponent.move
        end
        if not move then
            return
        elseif g.moves[pos] ~= '-' then
            return mattata.answer_callback_query(
                callback_query.id,
                'You cannot go here!'
            )
        end
        g.moves[pos] = move
        if g.moves.a1 == g.moves.a2 and g.moves.a2 == g.moves.a3 and g.moves.a2 ~= '-' then
            g.winner = g.opponent.id
            g.loser = g.player.id
            if g.player.move == g.moves.a1 then
                g.winner = g.player.id
                g.loser = g.opponent.id
            end
            g.is_over = true
            g.was_won = true
        elseif g.moves.b1 == g.moves.b2 and g.moves.b2 == g.moves.b3 and g.moves.b2 ~= '-' then
            g.winner = g.opponent.id
            g.loser = g.player.id
            if g.player.move == g.moves.b1 then
                g.winner = g.player.id
                g.loser = g.opponent.id
            end
            g.is_over = true
            g.was_won = true
        elseif g.moves.c1 == g.moves.c2 and g.moves.c2 == g.moves.c3 and g.moves.c2 ~= '-' then
            g.winner = g.opponent.id
            g.loser = g.player.id
            if g.player.move == g.moves.c1 then
                g.winner = g.player.id
                g.loser = g.opponent.id
            end
            g.is_over = true
            g.was_won = true
        elseif g.moves.a1 == g.moves.b2 and g.moves.b2 == g.moves.c3 and g.moves.b2 ~= '-' then
            g.winner = g.opponent.id
            g.loser = g.player.id
            if g.player.move == g.moves.a1 then
                g.winner = g.player.id
                g.loser = g.opponent.id
            end
            g.is_over = true
            g.was_won = true
        elseif g.moves.a3 == g.moves.b2 and g.moves.b2 == g.moves.c1 and g.moves.b2 ~= '-' then
            g.winner = g.opponent.id
            g.loser = g.player.id
            if g.player.move == g.moves.a3 then
                winner = g.player.id
                loser = g.opponent.id
            end
            g.is_over = true
            g.was_won = true
        elseif g.moves.a2 == g.moves.b2 and g.moves.b2 == g.moves.c2 and g.moves.b2 ~= '-' then
            g.winner = g.opponent.id
            g.loser = g.player.id
            if g.player.move == g.moves.a2 then
                g.winner = g.player.id
                g.loser = g.opponent.id
            end
            g.is_over = true
            g.was_won = true
        elseif g.moves.b1 == g.moves.b2 and g.moves.b2 == g.moves.b3 and g.moves.b2 ~= '-' then
            g.winner = g.opponent.id
            g.loser = g.player.id
            if g.player.move == g.moves.b1 then
                g.winner = g.player.id
                g.loser = g.opponent.id
            end
            g.is_over = true
            g.was_won = true
        elseif g.moves.a1 ~= '-' and g.moves.a2 ~= '-' and g.moves.a3 ~= '-' and g.moves.b1 ~= '-' and g.moves.b2 ~= '-' and g.moves.b3 ~= '-' and g.moves.c1 ~= '-' and g.moves.c2 ~= '-' and g.moves.c3 ~= '-' then
            g.is_over = true
        end
        redis:set(
            'games:noughts_and_crosses:' .. session_id,
            json.encode(g)
        )
    elseif callback_query.data:match('^%d+%:join%_game$') then
        if callback_query.from.id == g.player.id then
            return mattata.answer_callback_query(
                callback_query.id,
                'You are already part of this game!'
            )
        end
        g.has_opponent = true
        g.opponent.id = callback_query.from.id
        redis:set(
            'games:noughts_and_crosses:' .. session_id,
            json.encode(g)
        )
    else
        return mattata.answer_callback_query(
            callback_query.id,
            'This game has already started!'
        )
    end
    local keyboard = game.get_keyboard(session_id)
    if not keyboard then
        return
    end
    local currently = g.player.id
    if g.player.is_go == false then
        currently = g.opponent.id
    end
    local output = mattata.get_linked_name(g.player.id) .. ' [' .. g.player.move .. '] is playing against ' .. mattata.get_linked_name(g.opponent.id) .. ' [' .. g.opponent.move .. ']\nIt is currently ' .. mattata.get_linked_name(currently) .. '\'s turn!'
    if g.is_over == true then
        if g.was_won == true then
            game.set_stats(
                g.winner,
                message.chat.id,
                'won'
            )
            game.set_stats(
                g.loser,
                message.chat.id,
                'lost'
            )
            output = mattata.get_linked_name(g.winner) .. ' won the game against ' .. mattata.get_linked_name(g.loser) .. '!'
        else
            output = mattata.get_linked_name(g.player.id) .. ' drew the game against ' .. mattata.get_linked_name(g.opponent.id) .. '!'
        end
    end
    return mattata.edit_message_text(
        message.chat.id,
        message.message_id,
        output,
        'html',
        true,
        json.encode(keyboard)
    )
end

function game:on_message(message)
    if message.chat.type == 'private' then
        return mattata.send_reply(
            message,
            'You can\'t use this command in private chat!'
        )
    elseif mattata.input(message.text) == 'stats' then
        local stats = game.get_stats(
            message.from.id,
            message.chat.id
        )
        return mattata.send_reply(
            message,
            stats
        )
    end
    local session_id = tostring(socket.gettime())
    session_id = session_id:gsub('%.', '')
    local rnd = math.random(10)
    local g = {
        is_over = false,
        was_won = false,
        has_opponent = false,
        player = {
            id = message.from.id,
            move = '❌',
            is_go = true
        },
        opponent = {
            id = '-',
            move = '⭕',
            is_go = false
        },
        moves = {
            a1 = '-',
            a2 = '-',
            a3 = '-',
            b1 = '-',
            b2 = '-',
            b3 = '-',
            c1 = '-',
            c2 = '-',
            c3 = '-'
        }
    }
    if rnd == 2 then
        g.player.move = '😂'
        g.opponent.move = '😱'
    elseif rnd == 3 then
        g.player.move = '🍆'
        g.opponent.move = '🍑'
    elseif rnd == 4 then
        g.player.move = '❤'
        g.opponent.move = '🖤'
    elseif rnd == 5 then
        g.player.move = '🙈'
        g.opponent.move = '🙉'
    elseif rnd == 6 then
        g.player.move = '🌚'
        g.opponent.move = '🌝'
    elseif rnd == 7 then
        g.player.move = '🔥'
        g.opponent.move = '❄'
    elseif rnd == 8 then
        g.player.move = '🍏'
        g.opponent.move = '🍍'
    elseif rnd == 9 then
        g.player.move = 'Ayy'
        g.opponent.move = 'Lmao'
    elseif rnd == 10 then
        g.player.move = '💦'
        g.opponent.move = '😈'
    end
    redis:set(
        'games:noughts_and_crosses:' .. session_id,
        json.encode(g)
    )
    local status = 'Waiting for opponent...'
    local keyboard = game.get_keyboard(session_id, true)
    return mattata.send_message(
        message.chat.id,
        status,
        nil,
        true,
        false,
        message.message_id,
        json.encode(keyboard)
    )
end

return game