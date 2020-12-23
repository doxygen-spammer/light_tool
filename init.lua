local name = minetest.get_current_modname()
local path = minetest.get_modpath(name)

dofile(path.."/api.lua")
dofile(path.."/tools.lua")

-- This is a temporary light source which forms the light beam of a flashlight.
-- When you constructed it, call minetest.get_node_timer(pos):start(lifetime) to make it delete itself.
-- Call start() again to extend the lifetime.
minetest.register_node("light_tool:light", {
	drawtype = "airlike",
	tiles = {"blank.png"},
	paramtype = "light",
	walkable = false,
	sunlight_propagates = true,
	light_source = 8,
	pointable = false,
	buildable_to = true, 
	on_timer = function(pos)
		minetest.set_node(pos, {name = "air"})
	end,
})

minetest.register_lbm({
	name = "light_tool:remove_light",
	nodenames = {"light_tool:light"},
	run_at_every_load = true, 
	action = function(pos, node)
		minetest.set_node(pos, {name = "air"})
	end,
})

if minetest.get_modpath("default") then
	light_tool.register_glow_node("default:water_source")
	light_tool.register_glow_node("default:water_flowing")
	light_tool.register_glow_node("default:river_water_source")
	light_tool.register_glow_node("default:river_water_flowing")
elseif minetest.get_modpath("mcl_core") then
	light_tool.register_glow_node("mcl_core:water_source")
	light_tool.register_glow_node("mcl_core:water_flowing")
	light_tool.register_glow_node("mclx_core:river_water_source")
	light_tool.register_glow_node("mclx_core:river_water_flowing")
end

minetest.register_globalstep(function()
	for _, user in ipairs(minetest.get_connected_players()) do
		local stack = ItemStack(user:get_wielded_item())
		local wielded = stack:get_definition()
		if light_tool.tools[wielded.name] then
			local dir = user:get_look_dir()
			local pos = user:get_pos()
			light_tool.light_beam({x = pos.x, y = pos.y+1, z = pos.z}, dir, light_tool.tools[wielded.name].range)
		end
	end
end)
