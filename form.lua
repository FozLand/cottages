	local nodemeta,owner,liquid,level = ...

	local formspec =
		'size[8,8.5]'..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		'label[2,0.7;Pour:]'..
		'list['..nodemeta..';input;3,0.5;1,1;]'..
		'label[0,0;'..owner..'\'s Barrel]'..
		'image[2.5,1.5;2.5,3;default_sandstone.png^[lowpart:'..
		(level/2160)..':default_desert_stone.png]'..
		'label[0.3,3.2;Fill:]'..
		'list['..nodemeta..';output;1,3;1,1;]'..
		'label[5.0,1.7;Contents:]'..
		'label[5.5,2.2;  '..(level/1000)..' L]'..
		'label[5.5,2.7;  '..liquid..']'..
		'label[5.0,0;Capacity: 216 L]'..
		'list[current_player;main;0,4.5;8,1;]'..
		default.get_hotbar_bg(0,4.5)..
		'list[current_player;main;0,5.75;8,3;8]'..
		'listring['..nodemeta..';output]'..
		'listring[current_player;main]'..
		'listring['..nodemeta..';input]'..
		'listring[current_player;main]'
	return formspec
