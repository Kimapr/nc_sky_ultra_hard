-- LUALOCALS < ---------------------------------------------------------
local minetest, string, vector
    = minetest, string, vector
local string_format, string_sub
    = string.format, string.sub
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]
local cmdpref = "skyhell"

minetest.register_privilege(cmdpref .. "_cycle", {
		description = "can teleport cycling through islands",
		give_to_singleplayer = false,
		give_to_admin = true
	})

local function postrim(pos)
	local str = minetest.pos_to_string(pos)
	return string_sub(str, 2, #str - 2)
end

local function getinfo(pos)
	if not pos then return false, "unable to determine position" end
	local ipos, minp, maxp = api.island_near(pos)
	if not ipos then return false, "island not found at " .. postrim(pos) end
	local pstr = string_format("island at %s (bounds %s to %s)",
		postrim(ipos), postrim(minp), postrim(maxp))
	local owner = api.pos_to_owner(pos)
	if not owner then return pstr .. " not owned" end
	local disp
	if not minetest.player_exists(owner) then
		disp = "player deleted"
	else
		local cur = api.player_to_island(owner)
		if cur and vector.equals(cur, ipos) then
			disp = "home here"
		else
			disp = "home at " .. postrim(ipos)
		end
	end
	return true, string_format("%s owned by %q (%s)", pstr, owner, disp)
end

minetest.register_chatcommand(cmdpref .. "_cycle", {
		description = "jump to next assigned island",
		privs = {[cmdpref .. "_cycle"] = true},
		func = function(name)
			local player = minetest.get_player_by_name(name)
			if not player then return false, "must be online" end
			local ipos = api.island_next(player:get_pos())
			ipos.y = ipos.y + 8
			player:set_pos(ipos)
			local info = minetest.registered_chatcommands[cmdpref .. "_info"]
			if info then return info.func(name, "") end
			return true, "teleported to " .. minetest.pos_to_string(ipos)
		end
	})
