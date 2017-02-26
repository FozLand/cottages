---------------------------------------------------------------------
-- A barrel than can store liquids and a tub.
---------------------------------------------------------------------
-- TODO add more VESSELS and more liquids (cider, orange juice, oil)
-- TODO: Add an API for adding vessels (volume, liquid, full_name, empty_name)

--local V_GLASS  =    125
--local V_CUP    =    250
--local V_BOTTLE =    750
--local V_CIDER  =   1500
local V_BUCKET =   9000
local V_BARREL = 216000

local VESSELS = {
	['bucket:bucket_water'] = {
		liquid = 'water',
		volume = V_BUCKET,
		empty  = 'bucket:bucket_empty',
	},
	['bucket:bucket_lava'] = {
		liquid = 'lava',
		volume = V_BUCKET,
		empty  = 'bucket:bucket_empty',
	},
	['bucket:bucket_river_water'] = {
		liquid = 'river water',
		volume = V_BUCKET,
		empty  = 'bucket:bucket_empty',
	},
	['bucket:bucket_empty'] = {
		volume = V_BUCKET,
		['water']       = 'bucket:bucket_water',
		['lava']        = 'bucket:bucket_lava',
		['river water'] = 'bucket:bucket_river_water',
	},
}

local can_access = function(pos, player)
	return pos and player and
		( player:get_player_name() == minetest.get_meta(pos):get_string('owner') or
			minetest.check_player_privs(player, 'protection_bypass') )
end

local give_or_eject = function(stack, player, pos)
	print('give_or_eject')
	local player_inv = player and player:get_inventory()
	if player_inv then
		stack = player_inv:add_item('main', stack)
	end
	minetest.item_drop(stack, player, pos)
end

local pour_in = function(pos, inv, listname, index, player)
	local meta   = minetest.get_meta(pos)
	local level  = meta:get_int('liquid_level')
	local liquid = meta:get_string('liquid_type')

	local stack  = inv:get_stack(listname, index)
	local item   = stack:get_name()
	local vessel = VESSELS[item]

	-- If the barrel is empty, set the liquid type to whatever is poured in.
	if level == 0 then
		liquid = vessel.liquid
		meta:set_string('liquid_type', liquid)
	end

	-- If the liquids are the same and there is enough room left ...
	if vessel.liquid == liquid and vessel.volume <= V_BARREL - level then
		-- add the liquid to the barrel,
		level = level + vessel.volume
		meta:set_int('liquid_level', level)

		-- and return an empty vessel inventory.
		stack:take_item(1)
		local emptied_vessel_stack = ItemStack(vessel.empty)
		if stack:is_empty() then
			inv:set_stack(listname, index, emptied_vessel_stack)
		else
			inv:set_stack(listname, index, stack)
			give_or_eject(emptied_vessel_stack, player, player:get_pos())
		end

		-- TODO: Find a better sound.
		minetest.sound_play('default_water_footstep', {pos = pos})

		-- Log what happened.
		local who   = player:get_player_name()
		local stuff = vessel.volume..' ml of '..liquid..' from a '..item
		local what  = ' pours '..stuff..' into the cottages barrel ('..level..' mL)'
		local where = ' at '..minetest.pos_to_string(pos)
		minetest.log('action', who..what..where)
	end
end

local draw_off = function(pos, inv, listname, index, player)
	local meta   = minetest.get_meta(pos)
	local level  = meta:get_int('liquid_level')
	local liquid = meta:get_string('liquid_type')

	local stack  = inv:get_stack(listname, index)
	local item   = stack:get_name()
	local vessel = VESSELS[item]

	-- If the vessel can hold liquid and the barrel has enough to fill the vessel
	if vessel[liquid] and level >= vessel.volume then
		-- remove the vessel's volume from the barrel,
		level = level - vessel.volume
		meta:set_int('liquid_level', level)

		-- and return a vessel filled with liquid to the inventory.
		stack:take_item(1)
		local filled_vessel_stack = ItemStack(vessel[liquid])
		if stack:is_empty() then
			inv:set_stack(listname, index, filled_vessel_stack)
		else
			inv:set_stack(listname, index, stack)
			give_or_eject(filled_vessel_stack, player, player:get_pos())
		end

		-- TODO: Find a better sound.
		minetest.sound_play('default_water_footstep', {pos = pos})

		-- Log what happened.
		local who   = player:get_player_name()
		local stuff = vessel.volume..' ml of '..liquid..' into a '..item
		local what  = ' draws '..stuff..' from the cottages barrel ('..level..' mL)'
		local where = ' at '..minetest.pos_to_string(pos)
		minetest.log('action', who..what..where)
	end

	-- If the barrel is empty, reset its liquid type so it can be filled with
	-- something new.
	if level == 0 and liquid ~= '' then
		meta:set_string('liquid_type', '')
	end
end

local is_full = function(stack)
	-- Return true if the stack contains a single empty-able item.

	if not stack or stack:get_count() ~= 1 then
		return false
	end

	local vessel = VESSELS[stack:get_name()]
	if vessel and vessel.empty then
		return true
	end

	return false
end

local is_fillable = function(stack)
	-- Return true if the stack contains a single fillable item.

	if not stack or stack:get_count() ~= 1 then
		return false
	end

	local vessel = VESSELS[stack:get_name()]
	if vessel and not vessel.empty then
		return true
	end

	return false
end

-- pipes: table with the following entries for each pipe-part:
--    f: radius factor; if 1, it will have a radius of half a nodebox.
--    h1, h2: height at witch the nodebox shall start and end.
--    b: make a horizontal part/shelf
-- horizontal: if 1, then x and y coordinates will be swapped

local barrel = {}

barrel.make_pipe = function(pipes, horizontal)
	local result = {}
	for _,v in pairs(pipes) do
		local f  = v.f
		local h1 = v.h1
		local h2 = v.h2
		if not v.b or v.b == 0 then
			table.insert(result, {-0.37*f, h1, -0.37*f, -0.28*f, h2, -0.28*f})
			table.insert(result, {-0.37*f, h1,  0.28*f, -0.28*f, h2,  0.37*f})
			table.insert(result, { 0.37*f, h1, -0.28*f,  0.28*f, h2, -0.37*f})
			table.insert(result, { 0.37*f, h1,  0.37*f,  0.28*f, h2,  0.28*f})

			table.insert(result, {-0.30*f, h1, -0.42*f, -0.20*f, h2, -0.34*f})
			table.insert(result, {-0.30*f, h1,  0.34*f, -0.20*f, h2,  0.42*f})
			table.insert(result, { 0.20*f, h1, -0.42*f,  0.30*f, h2, -0.34*f})
			table.insert(result, { 0.20*f, h1,  0.34*f,  0.30*f, h2,  0.42*f})

			table.insert(result, {-0.42*f, h1, -0.30*f, -0.34*f, h2, -0.20*f})
			table.insert(result, { 0.34*f, h1, -0.30*f,  0.42*f, h2, -0.20*f})
			table.insert(result, {-0.42*f, h1,  0.20*f, -0.34*f, h2,  0.30*f})
			table.insert(result, { 0.34*f, h1,  0.20*f,  0.42*f, h2,  0.30*f})

			table.insert(result, {-0.25*f, h1, -0.45*f, -0.10*f, h2, -0.40*f})
			table.insert(result, {-0.25*f, h1,  0.40*f, -0.10*f, h2,  0.45*f})
			table.insert(result, { 0.10*f, h1, -0.45*f,  0.25*f, h2, -0.40*f})
			table.insert(result, { 0.10*f, h1,  0.40*f,  0.25*f, h2,  0.45*f})

			table.insert(result, {-0.45*f, h1, -0.25*f, -0.40*f, h2, -0.10*f})
			table.insert(result, { 0.40*f, h1, -0.25*f,  0.45*f, h2, -0.10*f})
			table.insert(result, {-0.45*f, h1,  0.10*f, -0.40*f, h2,  0.25*f})
			table.insert(result, { 0.40*f, h1,  0.10*f,  0.45*f, h2,  0.25*f})

			table.insert(result, {-0.15*f, h1, -0.50*f,  0.15*f, h2, -0.45*f})
			table.insert(result, {-0.15*f, h1,  0.45*f,  0.15*f, h2,  0.50*f})

			table.insert(result, {-0.50*f, h1, -0.15*f, -0.45*f, h2,  0.15*f})
			table.insert(result, { 0.45*f, h1, -0.15*f,  0.50*f, h2,  0.15*f})

		else -- filled horizontal part
			table.insert(result, {-0.35*f, h1, -0.40*f,  0.35*f, h2,  0.40*f})
			table.insert(result, {-0.40*f, h1, -0.35*f,  0.40*f, h2,  0.35*f})
			table.insert(result, {-0.25*f, h1, -0.45*f,  0.25*f, h2,  0.45*f})
			table.insert(result, {-0.45*f, h1, -0.25*f,  0.45*f, h2,  0.25*f})
			table.insert(result, {-0.15*f, h1, -0.50*f,  0.15*f, h2,  0.50*f})
			table.insert(result, {-0.50*f, h1, -0.15*f,  0.50*f, h2,  0.15*f})
		end
	end

	-- make the whole thing horizontal
	if horizontal == 1 then
		for i,v in ipairs(result) do
			result[i] = {v[2], v[1], v[3], v[5], v[4], v[6]}
		end
	end

	return result
end

--------------------------------------------------------------------------------
-- Barrel
--------------------------------------------------------------------------------

minetest.register_craft({
	output = 'cottages:barrel',
	recipe = {
		{'group:wood',          '',           'group:wood'         },
		{'default:steel_ingot', '',           'default:steel_ingot'},
		{'group:wood',          'group:wood', 'group:wood'         },
	},
})

local barrel_form = function(pos)
	local meta   = minetest.get_meta(pos)
	local owner  = meta:get_string('owner')
	local liquid = meta:get_string('liquid_type')
	local level  = meta:get_int('liquid_level')

	local nodemeta = 'nodemeta:'..pos.x..','..pos.y..','..pos.z

	return loadfile(minetest.get_modpath('cottages')..'/form.lua')(nodemeta,owner,liquid,level)
	--[[
	local formspec =
		'size[8,8.5]'..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		'label[3.2,0.7;Pour:]'..
		'list['..nodemeta..';input;4,0.5;1,1;]'..
		'label[0,0;'..owner..'\'s Barrel]'..
		'image[3.5,1.5;2.5,3;default_sandstone.png^[lowpart:'..
		level..':default_desert_stone.png]'..
		'label[1.5,3.2;Fill:]'..
		'list['..nodemeta..';output;2,3;1,1;]'..
		'list[current_player;main;0,4.5;8,1;]'..
		default.get_hotbar_bg(0,4.5)..
		'list[current_player;main;0,5.75;8,3;8]'..
		'listring['..nodemeta..';output]'..
		'listring[current_player;main]'..
		'listring['..nodemeta..';input]'..
		'listring[current_player;main]'
	return formspec
	--]]
end

minetest.register_node('cottages:barrel', {
	description = 'Wooden Barrel',
	groups      = {snappy=1, choppy=2, oddly_breakable_by_hand=1, flammable=2},
	drawtype    = 'nodebox',
	tiles       = {
		'cottages_minimal_wood.png',
		'cottages_minimal_wood.png',
		'cottages_barrel.png'
	},
	paramtype   = 'light',
	paramtype2  = 'facedir',
	is_ground_content = false,
	node_box = {
		type = 'fixed',
		fixed = barrel.make_pipe({
			{f=0.9,  h1=-0.2,  h2= 0.2,  b=0},
			{f=0.75, h1=-0.50, h2=-0.35, b=0},
			{f=0.75, h1= 0.35, h2= 0.5,  b=0},
			{f=0.82, h1=-0.35, h2=-0.2,  b=0},
			{f=0.82, h1= 0.2,  h2= 0.35, b=0},
			{f=0.75, h1= 0.37, h2= 0.42, b=1}, -- top closed
			{f=0.75, h1=-0.42, h2=-0.37, b=1}, -- bottom closed
		}, 0),
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string('infotext', 'Wooden Barrel')
		meta:set_string('liquid_type', '') -- Which liquid is in the barrel.
		meta:set_int('liquid_level', 0) -- How many units of liquid are in there.

		local inv = meta:get_inventory()
		inv:set_size('input', 1)
		inv:set_size('output', 1)
	end,

	after_place_node = function(pos, placer)
		local player_name = placer:get_player_name() or ''
		local meta = minetest.get_meta(pos)
		meta:set_string('owner', player_name)
		meta:set_string('infotext', 'Wooden Barrel (owned by '..player_name..')')
	end,

	can_dig = function(pos,player)
		local meta  = minetest.get_meta(pos)
		local inv   = meta:get_inventory()
		local level = meta:get_int('liquid_level')

		-- TODO: Possibly define a filled barrel drop that stores the liquid type
		-- and level in item meta. This would allow filled barrels to be moved
		-- around so the level check could be removed.
		if inv:is_empty('input') and inv:is_empty('output') and level == 0 and
		   can_access(pos, player) then
			return true
		end
		return false
	end,

	on_punch = function(pos, node, puncher)
		if not pos or not node or not puncher or not can_access(pos, puncher) then
			return
		end

		local wielded_name = puncher:get_wielded_item():get_name() or ''
		local vessel = VESSELS[wielded_name]
		if vessel then

			-- Require a brief delay between punches to prevent double punching caused
			-- by the wielded item being changed while the mouse button is still down.
			-- Also note the use of float to store the last punch time because
			-- minetest.get_us_time() returns an unsigned integer which will overflow
			-- within an hour if stored with meta:set_int().
			local meta       = minetest.get_meta(pos)
			local now        = minetest.get_us_time()
			local last_punch = meta:get_float('last_punch')
			meta:set_float('last_punch', now)
			if now > last_punch and now - last_punch < 0.3e6 then
				return
			end

			local inv      = puncher:get_inventory()
			local listname = puncher:get_wield_list()
			local index    = puncher:get_wield_index()

			-- If the vessel is full
			if vessel.empty then
				-- pour it into the barrel.
				pour_in(pos, inv, listname, index, puncher)
			else
				-- fill it from the barrel.
				draw_off(pos, inv, listname, index, puncher)
			end
		end
	end,

	on_rightclick = function(pos, node, clicker)
		local player_name = clicker:get_player_name()
		minetest.show_formspec(player_name, 'cottages:barrel', barrel_form(pos))
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)

		if can_access(pos, player) then
			local inv = minetest.get_meta(pos):get_inventory()
			local from_stack = inv:get_stack(from_list, from_index)
			local to_stack   = inv:get_stack(to_list, to_index)

			if to_list == 'input' and is_full(from_stack) and
			  (to_stack:is_empty() or is_fillable(to_stack)) then
				return 1
			end

			if to_list == 'output' and is_fillable(from_stack) and
			  (to_stack:is_empty() or  is_full(to_stack)) then
				return 1
			end
		end

		return 0
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if can_access(pos, player) and stack:get_count() == 1 then
			if listname == 'input' and is_full(stack) then
				return 1
			end

			if listname == 'output' and is_fillable(stack) then
				return 1
			end
		end
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if can_access(pos, player) then
			return stack:get_count()
		end
		return 0
	end,

	on_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)

		local inv = minetest.get_meta(pos):get_inventory()
		local from_stack = inv:get_stack(from_list, from_index)
		local to_stack   = inv:get_stack(to_list, to_index)

		if to_list == 'input' then
			if is_full(to_stack) then
				pour_in(pos, inv, to_list, to_index, player)
			end
			if is_fillable(from_stack) then
				draw_off(pos, inv, from_list, from_index, player)
			end
		end

		if to_list == 'output' then
			if is_full(from_stack) then
				pour_in(pos, inv, from_list, from_index, player)
			end
			if is_fillable(to_stack) then
				draw_off(pos, inv, to_list, to_index, player)
			end
		end

		local player_name = player:get_player_name()
		minetest.show_formspec(player_name, 'cottages:barrel', barrel_form(pos))
	end,

	on_metadata_inventory_put = function(pos, listname, index, stack, player)

		-- Eject items added via builtin inventory globbing.
		local inv = minetest.get_meta(pos):get_inventory()
		local result_stack = inv:get_stack(listname, index)
		if result_stack:get_count() ~= stack:get_count() then -- globbed!
			inv:set_stack(listname, index, stack)
			result_stack:take_item(1)
			give_or_eject(result_stack, player, player:get_pos())
		end

		if listname == 'input' then
			pour_in(pos, inv, listname, index, player)
		end

		if listname == 'output' then
			draw_off(pos, inv, listname, index, player)
		end

		local player_name = player:get_player_name()
		minetest.show_formspec(player_name, 'cottages:barrel', barrel_form(pos))
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)

		-- Handle items added via builtin inventory swapping.
		local inv = minetest.get_meta(pos):get_inventory()
		local result_stack = inv:get_stack(listname, index)
		if not result_stack:is_empty() then -- swapped!
			if listname == 'input' and is_full(result_stack) then
				pour_in(pos, inv, listname, index, player)
			elseif listname == 'output' and is_fillable(result_stack) then
				draw_off(pos, inv, listname, index, player)
			else -- Invalid swap.
				inv:remove_item(listname, result_stack)
				give_or_eject(result_stack, player, player:get_pos())
			end

			local player_name = player:get_player_name()
			minetest.show_formspec(player_name, 'cottages:barrel', barrel_form(pos))
		end
	end,

	on_blast = function(pos)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		local drops = inv:get_list('output')
		table.insert(drops,inv:get_list('input'))
		minetest.remove_node(pos)
		return drops
	end,
})

--[[
-- horizontal barrel
minetest.register_node('cottages:barrel_lying', {
	description = 'Barrel (closed), lying somewhere',
	groups = {
		snappy=1,
		choppy=2,
		oddly_breakable_by_hand=1,
		flammable=2,
		not_in_creative_inventory=1
	},
	drawtype    = 'nodebox',
	tiles = {
		'cottages_barrel_lying.png',
		'cottages_barrel_lying.png',
		'cottages_minimal_wood.png',
		'cottages_minimal_wood.png',
		'cottages_barrel_lying.png'
	},
	paramtype   = 'light',
	paramtype2  = 'facedir',
	is_ground_content = false,
	node_box = {
		type = 'fixed',
		fixed = barrel.make_pipe({
			{f=0.9,  h1=-0.2,  h2= 0.2,  b=0},
			{f=0.75, h1=-0.50, h2=-0.35, b=0},
			{f=0.75, h1= 0.35, h2= 0.5,  b=0},
			{f=0.82, h1=-0.35, h2=-0.2,  b=0},
			{f=0.82, h1= 0.2,  h2= 0.35, b=0},
			{f=0.75, h1= 0.37, h2= 0.42, b=1}, -- top closed
			{f=0.75, h1=-0.42, h2=-0.37, b=1}, -- bottom closed
		}, 1 ),
	},
	drop = 'cottages:barrel',
	on_rightclick = function(pos, node, puncher)
		minetest.add_node(pos, {name = 'cottages:barrel_lying_open', param2 = node.param2})
	end,

	on_punch = function(pos, node, puncher)
		if( node.param2 < 4 ) then
			minetest.add_node(pos,
				{name = 'cottages:barrel_lying', param2 = (node.param2+1)})
		else
			minetest.add_node(pos, {name = 'cottages:barrel', param2 = 0})
		end
	end,
})
--]]

--[[
minetest.register_lbm({
	name = 'cottages:convert_barrel_lying to barrel',
	nodenames = {'cottages:barrel_lying'},
	action = function(pos, node)
		local meta = minetest.get_meta(pos);
		meta:set_string('formspec', nil)
		local inv = meta:get_inventory()
		inv:set_list('hammers', inv:get_list('hammer'))
		inv:set_size('hammers', 4)
		inv:set_size('hammer', 0)
		minetest.log('action','lbm updated cottages:barrel_lying at ' ..
			minetest.pos_to_string(pos))
	end,
})
--]]

--[[
-- this barrel is opened at the top
minetest.register_node('cottages:barrel_open', {
	description = 'Barrel (open)',
	groups = {
		snappy=1,
		choppy=2,
		oddly_breakable_by_hand=1,
		flammable=2,
		not_in_creative_inventory=1
	},
	drawtype    = 'nodebox',
	tiles = {
		'cottages_minimal_wood.png',
		'cottages_minimal_wood.png',
		'cottages_barrel.png'
	},
	paramtype   = 'light',
	is_ground_content = false,
	node_box = {
		type = 'fixed',
		fixed = barrel.make_pipe({
			{f=0.9,  h1=-0.2,  h2= 0.2,  b=0},
			{f=0.75, h1=-0.50, h2=-0.35, b=0},
			{f=0.75, h1= 0.35, h2= 0.5,  b=0},
			{f=0.82, h1=-0.35, h2=-0.2,  b=0},
			{f=0.82, h1= 0.2,  h2= 0.35, b=0},
			{f=0.75, h1=-0.42, h2=-0.37, b=1}, -- bottom closed
		}, 0 ),
	},
	drop = 'cottages:barrel',

	on_punch      = function(pos, node, puncher)
		minetest.add_node(pos, {name = 'cottages:barrel_lying_open', param2 = node.param2})
	end,
})

minetest.register_node('cottages:barrel_lying_open', {
	description = 'Barrel (opened), lying somewhere',
	groups = {
		tree=1,
		snappy=1,
		choppy=2,
		oddly_breakable_by_hand=1,
		flammable=2,
		not_in_creative_inventory=1,
	},
	drawtype    = 'nodebox',
	tiles = {
		'cottages_barrel_lying.png',
		'cottages_barrel_lying.png',
		'cottages_minimal_wood.png',
		'cottages_minimal_wood.png',
		'cottages_barrel_lying.png',
	},
	paramtype   = 'light',
	paramtype2  = 'facedir',
	is_ground_content = false,
	node_box = {
		type = 'fixed',
		fixed = barrel.make_pipe({
			{f=0.9,  h1=-0.2,  h2= 0.2,  b=0},
			{f=0.75, h1=-0.50, h2=-0.35, b=0},
			{f=0.75, h1= 0.35, h2= 0.5,  b=0},
			{f=0.82, h1=-0.35, h2=-0.2,  b=0},
			{f=0.82, h1= 0.2,  h2= 0.35, b=0},
			{f=0.75, h1=-0.42, h2=-0.37, b=1} -- bottom closed
		}, 1),
	},
	drop = 'cottages:barrel',

	on_rightclick = function(pos, node, puncher)
		minetest.add_node(pos, {name = 'cottages:barrel_lying', param2 = node.param2})
	end,

	on_punch = function(pos, node, puncher)
		if( node.param2 < 4 ) then
			minetest.add_node(pos,
				{name = 'cottages:barrel_lying_open', param2 = (node.param2+1)})
		else
			minetest.add_node(pos, {name = 'cottages:barrel_open', param2 = 0})
		end
	end,
})
--]]

--------------------------------------------------------------------------------
-- Tub
--------------------------------------------------------------------------------

minetest.register_craft({
	output = 'cottages:tub 2',
	recipe = {
		{'cottages:barrel'},
	},
})

minetest.register_craft({
	output = 'cottages:barrel',
	recipe = {
		{'cottages:tub'},
		{'cottages:tub'},
	},
})

minetest.register_node('cottages:tub', {
	description = 'Vat',
	groups      = {snappy=1, choppy=2, oddly_breakable_by_hand=1, flammable=2},
	drawtype    = 'nodebox',
	tiles       = {
		'cottages_minimal_wood.png',
		'cottages_minimal_wood.png',
		'cottages_barrel.png',
	},
	paramtype   = 'light',
	is_ground_content = false,
	node_box = {
		type = 'fixed',
		fixed = barrel.make_pipe({
			{f=1.0,h1=-0.5,h2=0.0,b=0},
			{f=1.0,h1=-0.46,h2=-0.41,b=1}
		}, 0),
	},
})
