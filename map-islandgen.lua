-- LUALOCALS < ---------------------------------------------------------
local math, minetest, nodecore
    = math, minetest, nodecore
local math_floor
    = math.floor
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]

local slices = api.schematic_slices

minetest.register_on_generated(function(minp, maxp)
		if maxp.y < api.islands_ymin then return end
		if minp.y > api.islands_ymax then return end
		local vm = minetest.get_mapgen_object("voxelmanip")
		local gmin = api.island_grid_round(minp)
		local gmax = api.island_grid_round(maxp, 1)
		for x = gmin.x, gmax.x, api.islands_grid do
			for y = gmin.y, gmax.y, api.islands_grid do
				for z = gmin.z, gmax.z, api.islands_grid do
					local pos = api.island_near({x = x, y = y, z = z})
					if pos and minetest.get_node(pos).name == "air" then
						pos.y = pos.y - 1
						pos.x = pos.x - 2
						pos.z = pos.z - 2
						minetest.place_schematic_on_vmanip(vm, pos,
							nodecore.tree_schematic)
						local isw = #slices[1]
						local hisw = math_floor(isw / 2)
						pos.x = pos.x - (hisw -2)
						pos.z = pos.z - (hisw -2)
						pos.y = pos.y + 1 - #slices
						minetest.place_schematic_on_vmanip(vm, pos,
							api.isle_schematic)
					end
				end
			end
		end
		vm:calc_lighting()
		vm:write_to_map()
	end)
