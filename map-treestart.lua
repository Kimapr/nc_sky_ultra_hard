-- LUALOCALS < ---------------------------------------------------------
local math, minetest, nodecore
    = math, minetest, nodecore
local math_random
    = math.random
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()

local treestarter = modname .. ":treestarter"

minetest.register_node(treestarter, {
		drawtype = "airlike",
		walkable = false,
		climbable = false,
		pointable = false,
		buildable_to = false,
		paramtype = "light",
		sunlight_propagates = true
	})

local function treestart(pos)
	-- To be placed at a very specific place on island relative to tree.
	local found = nodecore.find_nodes_in_area(
		{x = pos.x - 0, y = pos.y + 2, z = pos.z - 2},
		{x = pos.x + 4, y = pos.y + 7, z = pos.z + 2},
	"nc_tree:leaves")
	if #found < 5 then return end
	for i = #found, 2, -1 do
		local j = math_random(1, i)
		found[i], found[j] = found[j], found[i]
	end
	for i = 1, 2 do
		minetest.get_meta(found[i]):set_string("leaf_decay_forced",
			minetest.serialize({
					name = "air",
					item = "nc_tree:eggcorn"
				}))
	end
	for i = 3, 5 do
		minetest.get_meta(found[i]):set_string("leaf_decay_forced",
			minetest.serialize({
					name = "nc_tree:stick"
				}))
	end
	minetest.remove_node(pos)
end

minetest.register_abm({
		label = treestarter,
		interval = 1,
		chance = 1,
		nodenames = {treestarter},
		action = treestart
	})
minetest.register_lbm({
		name = treestarter,
		nodenames = {treestarter},
		run_at_every_load = true,
		action = treestart
	})
