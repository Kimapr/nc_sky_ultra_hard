-- LUALOCALS < ---------------------------------------------------------
local ItemStack, minetest, nodecore, string
    = ItemStack, minetest, nodecore, string
local string_format, string_gsub
    = string.format, string.gsub
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]

local function destroycheck(getname)
	return function(self)
		local obj = self.object
		local pos = obj and obj:get_pos()
		if (not pos) or (pos.y >= api.barrier_ymax) then return end
		local itemname = getname(self)
		nodecore.log("action", string_format(
				"%s %q at %s lost to the void",
				string_gsub(self.name, "__builtin:", ""),
				itemname, minetest.pos_to_string(pos, 0)))
		local def = minetest.registered_items[itemname]
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
