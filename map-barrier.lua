-- LUALOCALS < ---------------------------------------------------------
local minetest, nodecore
    = minetest, nodecore
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]

local barriername = modname .. ":barrier"
minetest.register_node(barriername, {
		description = "SkyRealm Barrier",
		drawtype = "airlike",
		walkable = false,
		climbable = false,
		pointable = false,
		buildable_to = false,
		paramtype = "light",
		sunlight_propagates = true
	})

local barrierid = minetest.get_content_id(barriername)
nodecore.register_mapgen_shared({
		label = "skyrealm barrier",
		enabled = true, -- including singlenode
		func = function(minp, maxp, area, data)
			local barriermax = api.barrier_ymax
			if minp.y > barriermax then return end

			local ai = area.index

			local maxy = barriermax
			if maxp.y < maxy then maxy = maxp.y end

			for z = minp.z, maxp.z do
				for y = minp.y, maxy do
					local offs = ai(area, 0, y, z)
					for x = minp.x, maxp.x do
						if y < barriermax or (x + z) % 2 == 0 then
							data[offs + x] = barrierid
						end
					end
				end
			end
		end
	})
