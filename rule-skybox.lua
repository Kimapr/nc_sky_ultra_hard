-- LUALOCALS < ---------------------------------------------------------
local math, minetest, nodecore
    = math, minetest, nodecore
local math_ceil
    = math.ceil
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]

local function png(n) return modname .. "_skybox_" .. n .. ".png" end

nodecore.register_playerstep({
		label = "ultra skybox",
		priority = -100,
		action = function(_, data)
			if data.sky and data.sky.textures then
				local bot = data.sky.textures[2]
				if bot then
					local newbot = bot
					.. "^[resize:256x256"
					.. "^[multiply:#ff0000"
					.. "^" .. png("swirl")

					local mask = api.get_island_ttl(data.pname)
					/ api.assign_ttl
					mask = mask ^ 0.5
					mask = math_ceil(mask * 32) * 4
					if mask > 0 then
						if mask > 256 then mask = 256 end
						newbot = newbot .. "^(" .. png("grid")
						.. "^[mask:" .. png("swirl")
						.. "\\^[invert\\:rgb"
						.. "^[opacity:" .. mask .. ")"
					end

					data.sky.textures[2] = newbot
				end
				for i = 3, 6 do
					local side = data.sky.textures[i]
					if side then
						data.sky.textures[i] = side
						.. "^[resize:256x256"
						.. "^[multiply:#ff0000"
						.. "^(" .. side
						.. "^[resize:256x256"
						.. "^[mask:" .. png("mask") .. ")"
					end
				end
			end
		end
	})
