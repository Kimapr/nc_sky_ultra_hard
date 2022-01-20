-- LUALOCALS < ---------------------------------------------------------
local assert, ipairs, math, minetest, nodecore, pairs, string,
      tonumber, vector
    = assert, ipairs, math, minetest, nodecore, pairs, string,
      tonumber, vector
local math_floor, math_random, string_format, string_match
    = math.floor, math.random, string.format, string.match
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]

local store = minetest.get_mod_storage()
local tbplr, ibplr, ibpos

local function dload()
	tbplr = minetest.deserialize(store:get_string("next_reassign_by_player")) or {}
	ibplr = minetest.deserialize(store:get_string("islands_by_player")) or {}
	ibpos = minetest.deserialize(store:get_string("islands_by_pos")) or {}
end

local function dsave()
	store:set_string("next_reassign_by_player", minetest.serialize(tbplr))
	store:set_string("islands_by_player", minetest.serialize(ibplr))
	store:set_string("islands_by_pos", minetest.serialize(ibpos))
end

dload()
dsave()

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
	for _, fx in pairs(nodecore.registered_healthfx) do
		if fx.setqty then
			fx.setqty(player, 0)
		end
	end
	nodecore.inventory_dump(player)
	player:set_pos(vector.add(resolve(x, z), {x = 0, y = 8, z = 0}))
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

function api.get_island_ttl(name)
	local nextime = tbplr[name] or 0
	if nextime > nodecore.gametime then
		return nextime - nodecore.gametime
	end
	return 0
end

function api.give_island(player)
	local name = player:get_player_name()
	local ttl = api.get_island_ttl(name)
	if ttl > 0 then
		nodecore.log("action", string_format("%s reusing island, ttl %ds",
				name, ttl))
	else
		local is = find_new_island_id()
		local x, z = id_to_pos(is)
		nodecore.log("action", string_format("%s assigned to"
				.. " island (%d,%d) at %s", name, x, z,
				minetest.pos_to_string(resolve(x, z))))
		ibplr[name] = is
		ibpos[is] = name
		tbplr[name] = nodecore.gametime + api.assign_ttl
	end
	api.send_to_island(player)
	dsave()
end

nodecore.register_playerstep({
		label = "ultra sky spawnz",
		priority = -100,
		action = function(player, data)
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
					dsave()
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
