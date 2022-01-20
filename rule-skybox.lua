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
					local botred = bot
					.. "^[resize:256x256"
					.. "^[multiply:#ff0000"
					local newbot = botred
					.. "^" .. png("swirl")

					local s = api.get_island_ttl(data.pname)
					/ api.assign_ttl
					s = math_ceil(s * 16) * 4
					if s > 0 then
						if s > 128 then s = 128 end
						local o = 128 - s
						local w = 2 * s
						newbot = newbot .. "^(" .. botred
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
