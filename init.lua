
-- Version: 2.0
-- Autor:   Sokomine
-- License: GPLv3

local load_time_start = os.clock()
cottages = {}

local modpath = minetest.get_modpath('cottages')
dofile(modpath..'/nodes_furniture.lua')
dofile(modpath..'/nodes_historic.lua')
dofile(modpath..'/nodes_straw.lua')
dofile(modpath..'/nodes_anvil.lua')
dofile(modpath..'/nodes_doorlike.lua')
dofile(modpath..'/nodes_fences.lua')
dofile(modpath..'/nodes_roof.lua')
dofile(modpath..'/nodes_barrel.lua')

if minetest.setting_get("log_mods") then
	minetest.log('action', string.format('['..minetest.get_current_modname()..']'..
			' loaded in %.3fs', os.clock() - load_time_start))
end
