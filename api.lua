-- LUALOCALS < ---------------------------------------------------------
local math, minetest, pairs, rawset, tonumber, type, vector
    = math, minetest, pairs, rawset, tonumber, type, vector
local math_floor
    = math.floor
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()

local api = {}
rawset(_G, modname, api)

local function numsetting(suff, def)
	local key = modname .. "_" .. suff
	local val = tonumber(minetest.settings:get(key)) or def
	minetest.log(key .. " = " .. val)
	api[suff] = val
end
numsetting("islands_grid", 200)
numsetting("islands_ymin", 256 - api.islands_grid / 2)
numsetting("islands_ymax", 256 + api.islands_grid / 2)
numsetting("barrier_ymax", api.islands_ymin - 50)
numsetting("barrier_ymin", api.islands_ymin - 100)
numsetting("assign_ttl", 60)

local perlins = {x = 0, y = 1, z = 2}
minetest.after(0, function()
		for k, v in pairs(perlins) do
			perlins[k] = minetest.get_perlin(v, 1, 0, 1)
		end
	end)

local island_baseline = {x = 0, y = api.islands_ymin, z = 0}
function api.island_grid_round(pos, adjust)
	adjust = adjust or 0
	if type(adjust) ~= "table" then adjust = {x = adjust, y = adjust, z = adjust} end
	return vector.add(
		vector.multiply(
			vector.floor(
				vector.add(
					vector.multiply(
						vector.subtract(pos, island_baseline),
						1 / api.islands_grid
					),
					adjust)
			),
			api.islands_grid),
		island_baseline)
end

function api.island_near(pos, adjust)
	local gpos = api.island_grid_round(pos, adjust)
	if gpos.y < api.islands_ymin or gpos.y > api.islands_ymax then return end
	local ipos = {
		x = perlins.x:get_3d(gpos),
		y = perlins.y:get_3d(gpos),
		z = perlins.z:get_3d(gpos)
	}
	local function fixup(ip, gp)
		return math_floor(((ip - math_floor(ip)) / 2 + 1/4)
			* api.islands_grid + 0.5) + gp
	end
	ipos.y = fixup(ipos.y, gpos.y)
	if ipos.y < api.islands_ymin or ipos.y > api.islands_ymax then return end
	ipos.x = fixup(ipos.x, gpos.x)
	ipos.z = fixup(ipos.z, gpos.z)
	return ipos
end
