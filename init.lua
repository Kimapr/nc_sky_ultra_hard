-- LUALOCALS < ---------------------------------------------------------
local include
    = include
-- LUALOCALS > ---------------------------------------------------------

include("api")

include("map-treestart")
include("map-schematic")
include("map-islandgen")
include("map-barrier")

include("rule-destroyitems")
include("rule-playerspawn")
include("rule-skybox")

include("admin-info")
