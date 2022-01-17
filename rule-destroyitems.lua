-- LUALOCALS < ---------------------------------------------------------
local ItemStack, minetest, nodecore
    = ItemStack, minetest, nodecore
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]

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
