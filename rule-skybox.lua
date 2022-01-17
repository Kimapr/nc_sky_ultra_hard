-- LUALOCALS < ---------------------------------------------------------
local minetest, nodecore
    = minetest, nodecore
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()

nodecore.register_playerstep({
		label = "ultra skybox",
		priority = -100,
		action = function(_, data)
			if data.sky and data.sky.textures then
				local bot = data.sky.textures[2]
				if bot then
					data.sky.textures[2] = bot
					.. "^[resize:256x256"
					.. "^[multiply:#ff0000"
					.. "^" .. modname .. "_skybox_swirl.png"
				end
				for i = 3, 6 do
					local side = data.sky.textures[i]
					if side then
						data.sky.textures[i] = side
						.. "^[resize:256x256"
						.. "^[multiply:#ff0000"
						.. "^(" .. side
						.. "^[resize:256x256"
						.. "^[mask:" .. modname .. "_skybox_mask.png)"
					end
				end
			end
		end
	})
