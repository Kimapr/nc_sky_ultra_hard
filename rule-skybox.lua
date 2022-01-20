-- LUALOCALS < ---------------------------------------------------------
local math, minetest, nodecore, string
    = math, minetest, nodecore, string
local math_ceil, string_gsub
    = math.ceil, string.gsub
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]

local function png(n) return modname .. "_skybox_" .. n .. ".png" end
local function esc(t) return string_gsub(string_gsub(t, "%^", "\\^"), ":", "\\:") end

nodecore.register_playerstep({
		label = "ultra skybox",
		priority = -100,
		action = function(_, data)
			if data.sky and data.sky.textures then
				local bot = data.sky.textures[2]
				if bot then
					local botsized = bot
					.. "^[resize:256x256"
					local newbot = botsized
					.. "^[multiply:#ff0000"
					.. "^" .. png("swirl")

					local s = api.get_island_ttl(data.pname)
					/ api.assign_ttl
					s = math_ceil(s * 24) * 2
					if s > 0 then
						if s > 48 then s = 48 end
						local o = 128 - s
						local w = 2 * s
						newbot = newbot .. "^(" .. botsized
						.. "^[multiply:#ff4040"
						.. "^[resize:256x256"
						.. "^[mask:" .. esc(
							"[combine:256x256:"
							.. o .. "," .. o .. "="
							.. esc(
								png("cutout")
								.. "^[resize:"
								.. w .. "x" .. w
							)
						) .. ")"
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
