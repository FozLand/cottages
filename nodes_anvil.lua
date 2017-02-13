--------------------------------------------------------------------------------
-- Hammers and anvil that can be used to repair tools.
--------------------------------------------------------------------------------

local is_hammer = function(stack)
	return string.sub(stack:get_name(), 1, 15) == 'cottages:hammer'
end

local repairable = function(stack)
	if not stack then return false end

	local wear = stack:get_wear()
	if wear == 0 then return false end

	local name = stack:get_name()
	if name == 'fire:flint_and_steel' or
	   name == 'fake_fire:flint_and_steel' or
	   name == 'technic:water_can' or
	   name == 'technic:lava_can' or
	   name == 'utechnic:chainsaw' or
	   string.sub(name, 1, 15) == 'cottages:hammer' or
	   string.sub(name, 1, 8) == 'shooter:' then
		return false
	end

	return true
end

HAMMERS = {
	hammersteel = {
		desc   = 'Steel',
		recipe = 'default:steel_ingot',
		image  = 'cottages_tool_steelhammer.png',
		-- 92 uses 2.5 full repairs
		repair = -1800,
		damage = 720,
	},
	hammerbronze = {
		desc   = 'Bronze',
		recipe = 'default:bronze_ingot',
		image  = 'cottages_tool_bronzehammer.png',
		-- 137 uses 4 full repairs
		repair = -1920,
		damage = 480,
	},
	hammermese = {
		desc   = 'Mese',
		recipe = 'default:mese_crystal',
		image  = 'cottages_tool_mesehammer.png',
		-- 158 uses 6 full repairs
		repair = -2496,
		damage = 416,
	},
	hammerdiamond = {
		desc   = 'Diamond',
		recipe = 'default:diamond',
		image  = 'cottages_tool_diamondhammer.png',
		-- 216 uses 10 full repairs
		repair = -3040,
		damage = 304,
	},
	hammerobsidian = {
		desc   = 'Obsidian',
		recipe = 'default:obsidian',
		image  = 'cottages_tool_obsidianhammer.png',
		-- 256 uses 8 full repairs
		repair = -2048,
		damage = 256,
	},
}

for hammer,def in pairs(HAMMERS) do
	minetest.register_craft({
		output = 'cottages:'..hammer,
		recipe = {
			{ def.recipe, def.recipe,    def.recipe },
			{ def.recipe, 'group:stick', ''         },
			{ '',         'group:stick', ''         },
		}
	})

	minetest.register_tool('cottages:'..hammer, {
		description       = def.desc..' hammer',
		inventory_image   = def.image,
		tool_capabilities = {
			full_punch_interval = 0.8,
			max_drop_level=1,
			groupcaps={ -- about equal to a stone pick (it's not intended as a tool)
				cracky={times={[2]=2.00, [3]=1.20}, uses=30, maxlevel=1},
			},
			damage_groups = {fleshy=6},
		},
	})
end
minetest.register_alias('cottages:hammer', 'cottages:hammersteel')

--------------------------------------------------------------------------------
-- Anvil
--------------------------------------------------------------------------------

minetest.register_craft({
	output = 'cottages:anvil',
	recipe = {
		{'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
		{'',                   'default:steel_ingot',''                   },
		{'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
	},
})

-- Allow converting between the castle mod anvil and cottages anvil.
if minetest.get_modpath('castle') then
	minetest.register_craft({
		output = 'cottages:anvil',
		recipe = {
			{'castle:anvil'},
		},
	})

	minetest.register_craft({
		output = 'castle:anvil',
		recipe = {
			{'cottages:anvil'},
		},
	})
end

local anvil_form = function(pos, owner)
	local nodemeta = 'nodemeta:'..pos.x..','..pos.y..','..pos.z
	local formspec =
		'size[8,8.5]'..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		'label[0,0;'..owner..'\'s Anvil]'..
		'label[0.2,1.5;Workpiece:]'..
		'list['..nodemeta..';input;2,1.3;1,1;]'..
		'label[4,0.3;Place a damaged tool]'..
		'label[4,0.7;in the workpiece slot.]'..
		'label[4,1.3;Hit the anvil with a hammer]'..
		'label[4,1.7;to repair your workpiece.]'..
		'list['..nodemeta..';hammers;3,3;4,1;]'..
		'label[0.2,3.2;Hammer storage:]'..
		'list[current_player;main;0,4.5;8,1;]'..
		default.get_hotbar_bg(0,4.5)..
		'list[current_player;main;0,5.75;8,3;8]'..
		'listring['..nodemeta..';input]'..
		'listring[current_player;main]'..
		'listring['..nodemeta..';hammers]'..
		'listring[current_player;main]'
	return formspec
end

minetest.register_node('cottages:anvil', {
	description = 'Anvil',
	groups      = {oddly_breakable_by_hand=1},
	drawtype    = 'nodebox',
	tiles       = {'default_coal_block.png'},
	paramtype   = 'light',
	paramtype2  = 'facedir',
	is_ground_content = false,
	node_box = {
		type = 'fixed',
		fixed = {
			{-6/16,-8/16,-5/16,6/16,-6/16,5/16},
			{-4/16,-6/16,-4/16,4/16,-4/16,4/16},
			{-4/16,-4/16,-3/16,4/16,-1/16,3/16},
			{-8/16,-1/16,-3/16,8/16, 2/16,3/16},
		},
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string('infotext', 'Anvil')
		local inv = meta:get_inventory()
		inv:set_size('input', 1)
		inv:set_size('hammers', 4)
	end,

	after_place_node = function(pos, placer)
		local player_name = placer:get_player_name() or ''
		local meta = minetest.get_meta(pos)
		meta:set_string('owner', player_name)
		meta:set_string('infotext', 'Anvil (owned by '..player_name..')')
	end,

	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos)
		local inv  = meta:get_inventory()
		local permitted = player and
			( player:get_player_name() == meta:get_string('owner') or
				minetest.check_player_privs(player, 'protection_bypass') )

		if permitted and inv:is_empty('input') and inv:is_empty('hammers') then
			return true
		end
		return false
	end,

	on_punch = function(pos, node, puncher)
		if not pos or not node or not puncher then
			return
		end

		-- Only allow punching with a hammer.
		local wielded = puncher:get_wielded_item()
		local wielded_name = wielded:get_name() or ''
		local hammer = string.sub(wielded_name, 10)
		if string.sub(wielded_name, 1, 15) ~= 'cottages:hammer' or
		   hammer == '' or
		   HAMMERS[hammer] == nil then
			return
		end

		local meta  = minetest.get_meta(pos)
		local inv   = meta:get_inventory()
		local input = inv:get_stack('input',1)
		local player_name = puncher:get_player_name()

		if not input or input:is_empty() then return end

		-- Use sounds and visuals to indicate progress.
		local wear = input:get_wear()
		if wear > 0 then
			minetest.log('action', player_name..' repaired a '..input:get_name()..
				' '..wear..' by '..HAMMERS[hammer].repair..' with a '..hammer)

			minetest.sound_play('default_place_node_metal', {pos = pos})

			local pp = pos
			pp.y = pp.y + 0.1
			minetest.add_particlespawner({
				amount = 8,
				time = 0.01,
				minpos = pp,
				maxpos = pp,
				minvel = {x=-10, y=0, z=-10},
				maxvel = {x=10, y=1, z=10},
				minexptime = 0.05,
				maxexptime = 0.1,
				collisiondetection = false,
				texture = 'cottages_anvil_hit.png',
			})
		end

		-- Damage the hammer.
		wielded:add_wear(HAMMERS[hammer].damage)
		puncher:set_wielded_item(wielded)

		-- Repair the tool.
		input:add_wear(HAMMERS[hammer].repair)
		inv:set_stack('input', 1, input)

		-- Message the player when finished.
		if wear == 0 then
			minetest.chat_send_player(player_name, 'Your tool has been repaired.')
		end

	end,

	on_rightclick = function(pos, node, clicker)
		local player_name = clicker:get_player_name()
		local owner = minetest.get_meta(pos):get_string('owner')
		minetest.show_formspec(player_name, 'cottages:anvil', anvil_form(pos, owner))
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
		if from_list == to_list then
			return count
		end
		return 0
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		local permitted = player and
			( player:get_player_name() == meta:get_string('owner') or
				minetest.check_player_privs(player, 'protection_bypass') )

		if not permitted then
			return 0
		end

		if listname == 'hammers' and not is_hammer(stack) then
			return 0
		end

		if listname == 'input' and not repairable(stack) then
			minetest.chat_send_player(player:get_player_name(),
				'The workpiece slot is for damaged tools only.')
			return 0
		end

		return stack:get_count()
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)

		local permitted = player and
			( player:get_player_name() == meta:get_string('owner') or
				minetest.check_player_privs(player, 'protection_bypass') )

		if permitted then
			return stack:get_count()
		end
		return 0
	end,

	on_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
	end,

	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local who   = player:get_player_name()
		local stuff = stack:get_count()..' '..stack:get_name()
		local what  = ' puts '..stuff..' in cottages anvil'
		local where = ' at '..core.pos_to_string(pos)
		minetest.log('action', who..what..where)
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		-- Handle builtin inventory swapping.
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local swap_stack = inv:get_stack(listname, index)
		if not swap_stack:is_empty() and
		   ((listname == 'input'   and not repairable(swap_stack)) or
		    (listname == 'hammers' and not is_hammer(swap_stack))) then
			inv:remove_item(listname, swap_stack)
			local player_inv = player:get_inventory()
			if player_inv:room_for_item('main', swap_stack) then
				player_inv:add_item('main', swap_stack)
			else
				minetest.item_drop(swap_stack, player, player:get_pos())
			end
		end

		local who   = player:get_player_name()
		local stuff = stack:get_count()..' '..stack:get_name()
		local what  = ' takes '..stuff..' from cottages anvil'
		local where = ' at '..core.pos_to_string(pos)
		minetest.log('action', who..what..where)
	end,

	on_blast = function(pos)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		local drops = inv:get_list('hammers')
		table.insert(drops,inv:get_list('input'))
		table.insert(drops,'cottages:anvil')
		minetest.remove_node(pos)
		return drops
	end,
})

minetest.register_lbm({
	name = 'cottages:update_anvil_formspec_and_meta',
	nodenames = {'cottages:anvil'},
	action = function(pos, node)
		local meta = minetest.get_meta(pos);
		meta:set_string('formspec', nil)
		local inv = meta:get_inventory()
		inv:set_list('hammers', inv:get_list('hammer'))
		inv:set_size('hammers', 4)
		inv:set_size('hammer', 0)
		minetest.log('action','lbm updated cottages:anvil at ' ..
			minetest.pos_to_string(pos))
	end,
})
