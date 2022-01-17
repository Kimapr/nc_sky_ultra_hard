-- LUALOCALS < ---------------------------------------------------------
local ipairs, minetest, nodecore, type
    = ipairs, minetest, nodecore, type
-- LUALOCALS > ---------------------------------------------------------

local modname = minetest.get_current_modname()
local api = _G[modname]

local slices = {
	{
		".....",
		"..l..",
		"tplp.",
		"..p..",
		".....",
	},
	{
		".lll.",
		"laSal",
		"llSml",
		"lasal",
		".lll.",
	},
	{
		".ggg.",
		"ggggg",
		"gg.gg",
		"ggggg",
		".ggg.",
	},
}
api.schematic_slices = slices

for k, v in ipairs(slices) do
	if type(v) == "number" then
		slices[k] = slices[k + v]
	end
end

api.isle_schematic = nodecore.ezschematic(
	{
		["."] = {name = "air", prob = 0},
		m = {name = "nc_lode:ore", prob = 255},
		l = {name = "nc_lux:stone", prob = 255},
		a = {name = "nc_igneous:amalgam", prob = 255},
		p = {name = "nc_igneous:pumice", prob = 255},
		s = {name = "nc_terrain:sand", prob = 255},
		S = {name = "nc_sponge:sponge_living", prob = 255},
		g = {name = "nc_tree:humus", prob = 255},
		t = {name = modname .. ":treestarter", prob = 255}
	},
	slices
)
