std = 'lua53'
max_line_length = 200

-- Globally ignore: unused self (212), unused loop vars (213),
-- value assigned to variable is unused (311) - common for error handling
ignore = { '212', '213', '311' }

-- Test files: busted std, plus allow unused locals (211) for test variables,
-- setting read-only globals (131) for mocking, empty if branches (542)
files['spec/'] = {
    std = 'lua53+busted',
    max_line_length = 200,
    ignore = { '211', '212', '213', '311', '122', '131', '142', '143', '542' }
}
