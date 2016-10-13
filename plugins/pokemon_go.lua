local pokemon_go = {}
local functions = require('functions')
function pokemon_go:init(configuration)
	pokemon_go.command = 'pokego <team>'
	pokemon_go.triggers = functions.triggers(self.info.username, configuration.command_prefix):t('pokego', true):t('pokégo', true):t('pokemongo', true):t('pokémongo', true):t('pogo', true):t('mongo', true).table
	pokemon_go.documentation = configuration.command_prefix .. 'pokego <team> Set your Pokémon Go team for statistical purposes. The team must be valid, and can be referred to by name or color (or the first letter of either). Giving no team name will show statistics.'
	local db = self.database.pokemon_go
	if not db then
		self.database.pokemon_go = {}
		db = self.database.pokemon_go
	end
	if not db.membership then
		db.membership = {}
	end
	for _, set in pairs(db.membership) do
		setmetatable(set, functions.set_meta)
	end
end
local team_ref = {
	mystic = "Mystic",
	m = "Mystic",
	valor = "Valor",
	v = "Valor",
	instinct = "Instinct",
	i = "Instinct",
	blue = "Mystic",
	b = "Mystic",
	red = "Valor",
	r = "Valor",
	yellow = "Instinct",
	y = "Instinct"
}
function pokemon_go:action(msg, configuration)
	local output
	local input = functions.input(msg.text)
	if input then
		local team = team_ref[input]
		if not team then
			output = 'Invalid team.'
		else
			local id_str = tostring(msg.from.id)
			local db = self.database.pokemon_go
			local db_membership = db.membership
			if not db_membership[team] then
				db_membership[team] = functions.new_set()
			end

			for t, set in pairs(db_membership) do
				if t ~= team then
					set:remove(id_str)
				else
					set:add(id_str)
				end
			end
			output = 'Your team is now ' .. team .. '.'
		end
	else
		local db = self.database.pokemon_go
		local db_membership = db.membership
		local output_temp = {'Membership:'}
		for t, set in pairs(db_membership) do
			table.insert(output_temp, t .. ': ' .. #set)
		end
		output = table.concat(output_temp, '\n')
	end
	functions.send_reply(msg, output)
end
return pokemon_go