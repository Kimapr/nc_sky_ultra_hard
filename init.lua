-- LUALOCALS < ---------------------------------------------------------
local ItemStack, assert, ipairs, math, minetest, nodecore, pairs,
      string, tonumber, type, vector
    = ItemStack, assert, ipairs, math, minetest, nodecore, pairs,
      string, tonumber, type, vector
local math_floor, math_random, string_format, string_match
    = math.floor, math.random, string.format, string.match
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
numsetting("barrier_ymax", api.islands_ymin - 50)
numsetting("barrier_ymin", api.islands_ymin - 100)

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
		".....",
		".....",
		"..c..",
		".....",
		"....."
	},
	{
		".....",
		"..l..",
		".lSl.",
		"..l..",
		"....."
	},
	{
		".....",
		"..l..",
		".lml.",
		"..l..",
		"....."
	},
	{
		"..l..",
		".lpl.",
		"lpspl",
		".lpl.",
		"..l.."
	},
	{
		".PPP.",
		"PPPPP",
		"PPSPP",
		"PPPPP",
		".PPP."
	},
	{
		".....",
		".....",
		"..d..",
		".....",
		"....."
	},
}
api.isle_schematic = nodecore.ezschematic(
	{
		["."] = {name = "air", prob = 0},
		m = {name = "nc_lode:ore", prob = 255},
		l = {name = "nc_lux:stone", prob = 255},
		p = {name = "nc_igneous:amalgam", prob = 255},
		P = {name = "nc_igneous:pumice", prob = 255},
		c = {name = "nc_terrain:stone", prob = 255},
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
						pos.x = pos.x
						pos.z = pos.z
						pos.y = pos.y - 6
						minetest.place_schematic_on_vmanip(vm, pos,
							api.isle_schematic)
					end
				end
			end
		end
		vm:write_to_map()
	end)

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
			print(maxy)

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

local function destroycheck(getname)
	return function(self)
		local obj = self.object
		local pos = obj and obj:get_pos()
		if (not pos) or (pos.y >= api.barrier_ymax) then return end
		local def = minetest.registered_items[getname(self)]
		if not def then return obj:remove() end
		nodecore.digparticles(def, {
				time = 0.05,
				amount = 50,
				minpos = pos,
				maxpos = pos,
				minvel = {x = -5, y = -5, z = -5},
				maxvel = {x = 5, y = 5, z = 5},
				minexptime = 0.5,
				maxexptime = 1,
				minsize = 1,
				maxsize = 8
			})
		return obj:remove()
	end
end
nodecore.register_item_entity_step(destroycheck(function(self)
			return ItemStack(self.itemstring):get_name()
		end))
nodecore.register_falling_node_step(destroycheck(function(self)
			return self.node.name
		end))

local function pos_to_id(x, z)
	return math_floor(x) .. "_" .. math_floor(z)
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

local function unresolve(pos)
	pos = api.island_grid_round(pos)
	return pos.x / api.islands_grid, pos.z / api.islands_grid
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
	local x, z = id_to_pos(is)
	nodecore.log("action", string_format("%s assigned to"
			.. " island (%d,%d) at %s", name, x, z,
			minetest.pos_to_string(resolve(x, z))))
end

nodecore.register_playerstep({
		label = "ultra_sky",
		priority = -100,
		action = function(player, data)
			if data.sky and data.sky.textures then
				local bot = data.sky.textures[2]
				if bot then
					data.sky.textures[2] = bot
					.. "^[multiply:#ff0000"
					.. "^" .. modname .. "_skybox_swirl.png"
				end
				for i = 3, 6 do
					local side = data.sky.textures[i]
					if side then
						data.sky.textures[i] = side
						.. "^[multiply:#ff0000"
						.. "^(" .. side .. "^[mask:"
						.. modname .. "_skybox_mask.png)"
					end
				end
			end
			local name = player:get_player_name()
			if minetest.check_player_privs(player, "interact") then
				if not ibplr[name] then
					return api.give_island(player)
				end
				local pos = player:get_pos()
				if pos.y < api.barrier_ymin then
					nodecore.log("action", name .. " fell")
					return api.give_island(player)
				elseif pos.y < api.barrier_ymax then
					nodecore.inventory_dump(player)
				end
				local is = pos_to_id(unresolve(pos))
				if is ~= ibplr[name] and not ibpos[is] then
					ibpos[is] = name
					local x, z = id_to_pos(is)
					nodecore.log("action", string_format(
							"%s captured island (%d,%d)",
							name, x, z))
				end
			elseif not minetest.check_player_privs(player, "fly") then
				data.physics.speed = 0
				data.physics.gravity = 0
			end
		end
	})
