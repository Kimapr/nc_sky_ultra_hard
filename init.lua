-- LUALOCALS < ---------------------------------------------------------
local assert, math, minetest, nodecore, pairs, string, tonumber, type,
      vector
    = assert, math, minetest, nodecore, pairs, string, tonumber, type,
      vector
local math_floor, math_random, string_match
    = math.floor, math.random, string.match
-- LUALOCALS > ---------------------------------------------------------

local api = {}
local modname = minetest.get_current_modname()
_G[modname] = api
local store = minetest.get_mod_storage()
local ibplr, ibpos

local function dload()
	ibplr = minetest.deserialize(store:get_string("islands_by_player")) or {}
	ibpos = minetest.deserialize(store:get_string("islands_by_pos")) or {}
end

local function dsave()
	store:set_string("islands_by_player", minetest.serialize(ibplr))
	store:set_string("islands_by_pos", minetest.serialize(ibpos))
end

dload()
dsave()

local function numsetting(suff, def)
	local key = modname .. "_" .. suff
	local val = tonumber(minetest.settings:get(key)) or def
	minetest.log(key .. " = " .. val)
	api[suff] = val
end
numsetting("islands_grid", 200)
numsetting("islands_ymin", 256 - api.islands_grid / 2)
numsetting("islands_ymax", 256 + api.islands_grid / 2)
numsetting("islands_xzextent", 25000)

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

local slices = {
	{
		".......",
		".......",
		".......",
		"...m...",
		".......",
		".......",
		"......."
	},
	{
		".......",
		".......",
		"...d...",
		"..dpd..",
		"...d...",
		".......",
		"......."
	},
	{
		".......",
		"...d...",
		"..dpd..",
		".dpppd.",
		"..dpd..",
		"...d...",
		"......."
	},
	{
		".......",
		"...l...",
		"..lcl..",
		".lcccl.",
		"..lcl..",
		"...l...",
		"......."
	},
	{
		".......",
		"..dld..",
		".ddsdd.",
		".lsssl.",
		".ddsdd.",
		"..dld..",
		"......."
	},
	{
		"...d...",
		".ddldd.",
		".ddwdd.",
		"dlwSwld",
		".ddwdd.",
		".ddldd.",
		"...d..."
	},
	{
		"..ddd..",
		".ddddd.",
		"dddwddd",
		"ddwWwdd",
		"dddwddd",
		".ddddd.",
		"..ddd.."
	},
	{
		"..ggg..",
		".ggggg.",
		"ggggggg",
		"ggggggg",
		"ggggggg",
		".ggggg.",
		"..ggg.."
}}
api.isle_schematic = nodecore.ezschematic(
	{
		["."] = {name = "air", prob = 0},
		m = {name = "nc_lode:ore", prob = 255},
		l = {name = "nc_lux:stone", prob = 255},
		p = {name = "nc_terrain:lava_source", prob = 255},
		c = {name = "nc_terrain:cobble", prob = 255},
		s = {name = "nc_terrain:sand", prob = 255},
		S = {name = "nc_sponge:sponge_living", prob = 255},
		w = {name = "nc_terrain:water_flowing", param2 = 15, prob = 255},
		W = {name = "nc_terrain:water_source", prob = 255},
		d = {name = "nc_terrain:dirt", prob = 255},
		g = {name = "nc_terrain:dirt_with_grass", prob = 255}
	},
	slices
)

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
						pos.x = pos.x - 2
						pos.z = pos.z - 2
						minetest.place_schematic_on_vmanip(vm, pos,
							nodecore.tree_schematic)
						pos.x = pos.x - 1
						pos.z = pos.z - 1
						pos.y = pos.y - 8
						minetest.place_schematic_on_vmanip(vm, pos,
							api.isle_schematic)
					end
				end
			end
		end
		vm:write_to_map()
	end)

local function pos_to_id(x, z)
	return math.floor(x) .. "_" .. math.floor(z)
end

local function id_to_pos(i)
	local x, z = string_match(i, "(.-)_(.+)")
	x, z = tonumber(x), tonumber(z)
	assert(x, z)
	return x, z
end

local function resolve(x, z)
	x, z = x * api.islands_grid, z * api.islands_grid
	local y = (api.islands_ymin + api.islands_ymax) / 2
	return api.island_near({x = x, y = y, z = z})
end

function api.send_to_island(player)
	local x, z = id_to_pos(ibplr[player:get_player_name()])
	player:set_hp(1, "fell off island")
	nodecore.inventory_dump(player)
	player:set_pos(vector.add(resolve(x, z), {x = 0, y = 16, z = 0}))
end

local function find_new_island_id()
	local pos = pos_to_id(0, 0)
	local q = {pos}
	local seen = {}
	for _ = 0, math_floor(32768 / api.islands_grid) do
		local nxt = {}
		for _, is in ipairs(q) do
			if not ibpos[is] then return is end
			local x, z = id_to_pos(is)
			is = pos_to_id(x + 1, z)
			if not seen[is] then nxt[#nxt + 1] = is end
			is = pos_to_id(x - 1, z)
			if not seen[is] then nxt[#nxt + 1] = is end
			is = pos_to_id(x, z + 1)
			if not seen[is] then nxt[#nxt + 1] = is end
			is = pos_to_id(x, z - 1)
			if not seen[is] then nxt[#nxt + 1] = is end
		end
		if #nxt < 1 then return end
		for i = #nxt, 2, -1 do
			local j = math_random(1, i)
			nxt[i], nxt[j] = nxt[j], nxt[i]
		end
		q = nxt
	end
end

function api.give_island(player)
	local is = find_new_island_id()
	local name = player:get_player_name()
	ibplr[name] = is
	ibpos[is] = name
	api.send_to_island(player)
	dsave()
end

nodecore.register_playerstep({
		label = "ultra_sky",
		priority = -100,
		action = function(player, data)
			local name = player:get_player_name()
			if minetest.check_player_privs(player, "interact") then
				if not ibplr[name] then
					api.give_island(player)
				elseif player:get_pos().y < api.islands_ymin -50
				and ibplr[name] then
					api.give_island(player)
				end
			elseif not minetest.check_player_privs(player, "fly") then
				data.physics.speed = 0
				data.physics.gravity = 0
			end
		end
	})