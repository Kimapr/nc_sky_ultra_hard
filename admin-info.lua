-- LUALOCALS < ---------------------------------------------------------
local minetest, string, vector
    = minetest, string, vector
local string_format, string_sub
    = string.format, string.sub
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]
local cmdpref = "skyhell"

minetest.register_privilege(cmdpref .. "_info", {
		description = "can access ownership info about islands",
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
		if cur and postrim(cur) == postrim(ipos) then
			disp = "HOME HERE"
		else
			disp = "home at " .. postrim(cur)
		end
	end
	return true, string_format("%s owned by %q (%s)", pstr, owner, disp)
end

minetest.register_chatcommand(cmdpref .. "_info", {
		description = "access info about island/player ownership",
		parameters = "[playername]",
		privs = {[cmdpref .. "_info"] = true},
		func = function(name, param)
			if param ~= "" then
				local ipos = api.player_to_island(param)
				if not ipos then return false, string_format("no island found for player %q", param) end
				return getinfo(ipos)
			end
			local player = minetest.get_player_by_name(name)
			if not player then return false, "must be online" end
			return getinfo(player:get_pos())
		end
	})
