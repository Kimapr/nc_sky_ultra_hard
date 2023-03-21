-- LUALOCALS < ---------------------------------------------------------
local ipairs, math, minetest, nodecore, string, vector
    = ipairs, math, minetest, nodecore, string, vector
local math_ceil, math_floor, string_format
    = math.ceil, math.floor, string.format
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]
local cmdpref = "skyhell"

minetest.register_privilege(cmdpref .. "_delete", {
		description = "can delete islands",
		give_to_singleplayer = false,
		give_to_admin = true
	})

local queue = {}
do
	local batch
	local batchpos = 1
	local quiescent = true
	local function procstep()
		if not batch then
			if #queue > 0 then
				batch = queue
				queue = {}
				batchpos = 1
				if quiescent then
					quiescent = nil
					nodecore.log("action", "deletion queue starting")
				end
			else
				if quiescent then return end
				quiescent = true
				return nodecore.log("action", "deletion queue finished")
			end
		end
		(batch[batchpos])()
		batchpos = batchpos + 1
		if batchpos > #batch then batch = nil end
		return true
	end
	local count = 0
	local rpttime = 10
	minetest.register_globalstep(function(dtime)
			local expire = minetest.get_us_time() + 100000
			while procstep() and minetest.get_us_time() < expire do
				count = count + 1
			end
			rpttime = rpttime - dtime
			if rpttime > 0 then return end
			if count > 0 or #queue > 0 then
				nodecore.log("action", string_format("island delete queue ran %d, queued %d",
						count, #queue + (batch and (#batch - batchpos) or 0)))
			end
			count = 0
			rpttime = 10
		end)
end

local function delmapchunk(pos)
	return minetest.delete_area(pos, vector.add(pos, {
		x = 79, y = 79, z = 79
	}))
end

local deleting = {}
local function island_delete(pos, pname, full)
	if not pos then return false, "invalid pos" end
	local ipos, minp, maxp = api.island_near(pos)
	if not ipos then return false, "not an island" end

	local key = minetest.pos_to_string(ipos)
	if deleting[key] then return false, "already deleting " .. key end
	deleting[key] = true

	if not full then
		minp = {
			x = ipos.x - 32,
			y = minp.y,
			z = ipos.z - 32
		}
		max = {
			x = ipos.x + 32,
			y = ipos.y + 32,
			z = ipos.z + 32
		}
	end

	local start
	local queueb4 = #queue
	queue[#queue + 1] = function() start = minetest.get_us_time() / 1000000 end

	local deferred = {}
	-- scan downward due to liquid flow
	for y = math_ceil(maxp.y / 16) * 16, math_floor((api.barrier_ymax - 8) / 16) * 16, -16 do
		for x = math_ceil(minp.x / 16) * 16, math_floor(maxp.x / 16) * 16, 16 do
			for z = math_ceil(minp.z / 16) * 16, math_floor(maxp.z / 16) * 16, 16 do
				local delpos = {x = x, y = y, z = z}
				if delpos.x >= ipos.x - 20 and delpos.x <= ipos.x + 4
				and delpos.z >= ipos.z - 20 and delpos.z <= ipos.z + 4
				and delpos.y >= ipos.y - 20 and delpos.y <= ipos.y + 20 then
					deferred[#deferred + 1] = delpos
					-- ALSO delete now, to handle liquids
				end
				queue[#queue + 1] = function() return minetest.delete_area(delpos, delpos) end
			end
		end
	end
	-- re-delete island pos one more time to force mapgen, which only runs if
	-- there is air at this pos, otherwise island can be cut across mapblocks
	if #deferred > 0 then
		queue[#queue + 1] = function()
			for _, delpos in ipairs(deferred) do
				minetest.delete_area(delpos, delpos)
			end
		end
	end
	queue[#queue + 1] = function() api.island_unassign(ipos) end
	queue[#queue + 1] = function()
		deleting[key] = nil
		local finished = minetest.get_us_time() / 1000000
		local msg = string_format("finished deleting island %s in %0.2fs", key, finished - start)
		nodecore.log("action", msg)
		return minetest.chat_send_player(pname, msg)
	end
	return true, string_format("deleting island at %s: queued %d, deferred %d", key, #queue - queueb4, #deferred)
end

local function mkfunc(full)
	return function(name, param)
		param = minetest.string_to_pos(param)
		if not param then
			local player = minetest.get_player_by_name(name)
			if not player then return false, "must be online to use without pos" end
			param = player:get_pos()
		end
		return island_delete(param, name, full)
	end
end

minetest.register_chatcommand(cmdpref .. "_delete", {
		description = "destroy and reset an island (quick version)",
		parameters = "[pos]",
		privs = {[cmdpref .. "_delete"] = true},
		func = mkfunc(false)
	})
minetest.register_chatcommand(cmdpref .. "_delete_full", {
		description = "destroy and reset an island (full version)",
		parameters = "[pos]",
		privs = {[cmdpref .. "_delete"] = true},
		func = mkfunc(true)
	})
