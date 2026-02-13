--[[
    mattata v2.0 - Game Plugin
    Tic-tac-toe with inline keyboard buttons. Two players take turns.
    Game state stored in Redis as JSON.
]]

local plugin = {}
plugin.name = 'game'
plugin.category = 'fun'
plugin.description = 'Play tic-tac-toe with another user'
plugin.commands = { 'game', 'tictactoe' }
plugin.help = '/game - Start a tic-tac-toe game. Another user clicks a cell to join as O.'

local json = require('dkjson')

local EMPTY = ' '
local X = 'X'
local O = 'O'

-- Symbols for display on buttons
local DISPLAY = {
    [EMPTY] = '\xE2\xAC\x9C',  -- white square
    [X]     = '\xE2\x9D\x8C',  -- cross mark
    [O]     = '\xE2\xAD\x95',  -- hollow circle
}

local function game_key(chat_id, message_id)
    return 'ttt:' .. chat_id .. ':' .. message_id
end

local function new_board()
    return {
        EMPTY, EMPTY, EMPTY,
        EMPTY, EMPTY, EMPTY,
        EMPTY, EMPTY, EMPTY
    }
end

local WIN_LINES = {
    {1, 2, 3}, {4, 5, 6}, {7, 8, 9},  -- rows
    {1, 4, 7}, {2, 5, 8}, {3, 6, 9},  -- columns
    {1, 5, 9}, {3, 5, 7}              -- diagonals
}

local function check_winner(board)
    for _, line in ipairs(WIN_LINES) do
        local a, b, c = board[line[1]], board[line[2]], board[line[3]]
        if a ~= EMPTY and a == b and b == c then
            return a
        end
    end
    -- Check for draw
    for _, cell in ipairs(board) do
        if cell == EMPTY then
            return nil  -- game still in progress
        end
    end
    return 'draw'
end

local function build_keyboard(api, board, game_over)
    local keyboard = api.inline_keyboard()
    for row = 0, 2 do
        local r = api.row()
        for col = 1, 3 do
            local idx = row * 3 + col
            local label = DISPLAY[board[idx]]
            if game_over then
                r:callback_data_button(label, 'game:noop')
            else
                r:callback_data_button(label, 'game:move:' .. idx)
            end
        end
        keyboard:row(r)
    end
    return keyboard
end

local function format_status(game_state, winner)
    local tools = require('telegram-bot-lua.tools')
    local x_name = tools.escape_html(game_state.x_name or 'Player X')
    local o_name = tools.escape_html(game_state.o_name or '???')

    if winner == 'draw' then
        return string.format(
            '<b>Tic-Tac-Toe</b>\n%s %s vs %s %s\n\nIt\'s a draw!',
            DISPLAY[X], x_name, DISPLAY[O], o_name
        )
    elseif winner == X then
        return string.format(
            '<b>Tic-Tac-Toe</b>\n%s %s vs %s %s\n\n%s %s wins!',
            DISPLAY[X], x_name, DISPLAY[O], o_name, DISPLAY[X], x_name
        )
    elseif winner == O then
        return string.format(
            '<b>Tic-Tac-Toe</b>\n%s %s vs %s %s\n\n%s %s wins!',
            DISPLAY[X], x_name, DISPLAY[O], o_name, DISPLAY[O], o_name
        )
    else
        local turn_name = game_state.turn == X and x_name or o_name
        local turn_symbol = DISPLAY[game_state.turn]
        if not game_state.o_id then
            return string.format(
                '<b>Tic-Tac-Toe</b>\n%s %s vs %s ???\n\n%s is waiting for an opponent. Click a cell to join!',
                DISPLAY[X], x_name, DISPLAY[O], x_name
            )
        end
        return string.format(
            '<b>Tic-Tac-Toe</b>\n%s %s vs %s %s\n\n%s %s\'s turn',
            DISPLAY[X], x_name, DISPLAY[O], o_name, turn_symbol, turn_name
        )
    end
end

function plugin.on_message(api, message, ctx)
    local board = new_board()
    local game_state = {
        board = board,
        turn = X,
        x_id = message.from.id,
        x_name = message.from.first_name or 'Player X',
        o_id = nil,
        o_name = nil
    }

    local status = format_status(game_state, nil)
    local keyboard = build_keyboard(api, board, false)

    local result = api.send_message(message.chat.id, status, { parse_mode = 'html', link_preview_options = { is_disabled = true }, reply_markup = keyboard })
    if result and result.result and result.result.message_id then
        local key = game_key(message.chat.id, result.result.message_id)
        ctx.redis.setex(key, 3600, json.encode(game_state))
    end
end

function plugin.on_callback_query(api, callback_query, message, ctx)
    local data = callback_query.data

    if data == 'noop' then
        return api.answer_callback_query(callback_query.id)
    end

    local idx = tonumber(data:match('^move:(%d+)$'))
    if not idx or idx < 1 or idx > 9 then
        return api.answer_callback_query(callback_query.id, { text = 'Invalid move.' })
    end

    local key = game_key(message.chat.id, message.message_id)
    local raw = ctx.redis.get(key)
    if not raw then
        return api.answer_callback_query(callback_query.id, { text = 'This game has expired.' })
    end

    local game_state, _ = json.decode(raw)
    if not game_state then
        return api.answer_callback_query(callback_query.id, { text = 'Failed to load game state.' })
    end

    local user_id = callback_query.from.id
    local user_name = callback_query.from.first_name or 'Unknown'

    -- If no opponent yet, the first person who clicks (that isn't X) becomes O
    if not game_state.o_id then
        if user_id == game_state.x_id then
            return api.answer_callback_query(callback_query.id, { text = 'Waiting for an opponent to join. Another user must click a cell.' })
        end
        game_state.o_id = user_id
        game_state.o_name = user_name
    end

    -- Check it's this user's turn
    local expected_id = game_state.turn == X and game_state.x_id or game_state.o_id
    if user_id ~= expected_id then
        if user_id ~= game_state.x_id and user_id ~= game_state.o_id then
            return api.answer_callback_query(callback_query.id, { text = 'You are not a player in this game.' })
        end
        return api.answer_callback_query(callback_query.id, { text = 'It\'s not your turn.' })
    end

    -- Check cell is empty
    if game_state.board[idx] ~= EMPTY then
        return api.answer_callback_query(callback_query.id, { text = 'That cell is already taken.' })
    end

    -- Make the move
    game_state.board[idx] = game_state.turn
    local winner = check_winner(game_state.board)

    if winner then
        -- Game over
        local status = format_status(game_state, winner)
        local keyboard = build_keyboard(api, game_state.board, true)
        ctx.redis.del(key)
        api.answer_callback_query(callback_query.id)
        return api.edit_message_text(message.chat.id, message.message_id, status, { parse_mode = 'html', link_preview_options = { is_disabled = true }, reply_markup = keyboard })
    end

    -- Switch turns
    game_state.turn = game_state.turn == X and O or X
    local status = format_status(game_state, nil)
    local keyboard = build_keyboard(api, game_state.board, false)

    ctx.redis.setex(key, 3600, json.encode(game_state))
    api.answer_callback_query(callback_query.id)
    return api.edit_message_text(message.chat.id, message.message_id, status, { parse_mode = 'html', link_preview_options = { is_disabled = true }, reply_markup = keyboard })
end

return plugin
