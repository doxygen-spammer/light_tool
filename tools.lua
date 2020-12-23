-- Which tools to create
local tier = tonumber(minetest.settings:get("light_tool_max_tier")) or -1
local make_default_recipes = minetest.get_modpath("default")
local make_mcl_recipes = minetest.get_modpath("mcl_core")

-- Range limit for the tools
local setting_active_block_range = tonumber(minetest.settings:get("active_block_range")) or 100
local setting_max_block_send_distance = tonumber(minetest.settings:get("max_block_send_distance")) or 100

local max_range = setting_active_block_range * 16 - 16
local max_range_limiting_string = "\n[Distance limited by active_block_range setting.]"

if setting_max_block_send_distance < setting_active_block_range + 1 then
	max_range = setting_max_block_send_distance * 16 - 32
	max_range_limiting_string = "\n[Distance limited by max_block_send_distance setting.]"
end

-- Divergence for tools?
local allow_divergence = minetest.settings:get("light_tool_divergent_tools")

-- Original light_tool flashlight
if tier == -1 then
	minetest.register_tool("light_tool:light_tool", {
		description = "Light Tool",
		inventory_image = "light_tool_light_tool.png",
	})
	
	if make_default_recipes then
		minetest.register_craft({
			output = "light_tool:light_tool",
			recipe = {
				{"","default:mese_crystal_fragment","default:mese_crystal"},
				{"default:mese_crystal_fragment","default:steel_ingot","default:mese_crystal_fragment"},
				{"default:steel_ingot", "default:mese_crystal_fragment",""},
			}
		})
	elseif make_mcl_recipes then
		minetest.register_craft({
			output = "light_tool:light_tool",
			recipe = {
				{"","mobs_mc:blaze_rod","mcl_nether:glowstone"},
				{"mobs_mc:blaze_rod","mcl_core:steel_ingot","mobs_mc:blaze_rod"},
				{"mcl_core:steel_ingot", "mobs_mc:blaze_rod",""},
			},
		})
	end
	
	light_tool.add_tool("light_tool:light_tool", 20)
end

-- Tiered flashlights.
-- Not all tiers are available in MineClone, but they are less useful there because of the height limit.
if make_default_recipes then
	if tier >= 1 then
		minetest.register_craftitem("light_tool:reflector_bronze_tin", {
			description = "Bronce Disc with Tin\nA concave bronze disc with some tin applied.",
			inventory_image = "light_tool_reflector_bronze_tin.png"
		})

		minetest.register_craft({
			output = "light_tool:reflector_bronze_tin",
			recipe = {
				{"default:bronze_ingot", "default:tin_ingot", "default:bronze_ingot"},
				{"", "default:bronze_ingot", ""}
			}
		})

		minetest.register_craftitem("light_tool:reflector_tin", {
			description = "Primitive Reflector\nA concave bronze disc coated with a glossy layer of tin.",
			inventory_image = "light_tool_reflector_tin.png"
		})
	
		minetest.register_craft({
			type = "cooking",
			output = "light_tool:reflector_tin",
			recipe = "light_tool:reflector_bronze_tin",
			cooktime = 10
		})

		local limit_string = ""
		if max_range < 20 then
			limit_string = max_range_limiting_string
		end
		minetest.register_tool("light_tool:flashlight_copper", {
			description = "Mini Flashlight\nBundles the light of a light source to a 20m long beam." .. limit_string,
			inventory_image = "light_tool_flashlight_copper.png",
		})
	
		minetest.register_craft({
			output = "light_tool:flashlight_copper",
			recipe = {
				{"default:glass", "default:glass", "default:glass"},
				{"group:coal", "group:torch", "group:coal"},
				{"default:bronze_ingot", "light_tool:reflector_tin", "default:bronze_ingot"}
			}
		})
		light_tool.add_tool("light_tool:flashlight_copper", math.min(max_range, 20))
	end

	if tier >= 2 then
		local limit_string = ""
		if max_range < 40 then
			limit_string = max_range_limiting_string
		end
		minetest.register_tool("light_tool:flashlight_iron", {
			description = "Midi Flashlight\nBurns wood gas to make enough light for a 40m long beam." .. limit_string,
			inventory_image = "light_tool_flashlight_iron.png",
		})

		minetest.register_craft({
			output = "light_tool:flashlight_iron",
			recipe = {
				{"group:wood", "default:steel_ingot", "group:wood"},
				{"default:steel_ingot", "light_tool:flashlight_copper", "default:steel_ingot"}
			}
		})
		light_tool.add_tool("light_tool:flashlight_iron", math.min(max_range, 40))
	end

	if tier >= 3 then
		minetest.register_craftitem("light_tool:reflector_tin_gold", {
			description = "Reflector with Gold\nA tin reflector with some gold.",
			inventory_image = "light_tool_reflector_tin_gold.png"
		})

		minetest.register_craft({
			type = "shapeless",
			output = "light_tool:reflector_tin_gold",
			recipe = {"light_tool:reflector_tin", "default:gold_ingot", "default:gold_ingot", "default:gold_ingot"}
		})

		minetest.register_craftitem("light_tool:reflector_gold", {
			description = "Parabolic Mirror\nA concave disc, coated with a highly reflective gold layer.",
			inventory_image = "light_tool_reflector_gold.png"
		})
	
		minetest.register_craft({
			type = "cooking",
			output = "light_tool:reflector_gold",
			recipe = "light_tool:reflector_tin_gold",
			cooktime = 10
		})

		local limit_string = ""
		if max_range < 70 then
			limit_string = max_range_limiting_string
		end
		minetest.register_tool("light_tool:flashlight_gold", {
			description = "Maxi Flashlight\nUses advanced optics to form a 70m long beam." .. limit_string,
			inventory_image = "light_tool_flashlight_gold.png",
		})

		minetest.register_craft({
			output = "light_tool:flashlight_gold",
			recipe = {
				{"default:gold_ingot", "light_tool:flashlight_iron", "default:gold_ingot"},
				{"default:steel_ingot", "light_tool:reflector_gold", "default:steel_ingot"}
			}
		})
		light_tool.add_tool("light_tool:flashlight_gold", math.min(max_range, 70), allow_divergence and 9 or nil)
	end

	if tier >= 4 then
		local limit_string = ""
		if max_range < 110 then
			limit_string = max_range_limiting_string
		end
		minetest.register_tool("light_tool:flashlight_mese", {
			description = "Super Flashlight\nCollimates the light of an advanced light source to an 110m long beam." .. limit_string,
			inventory_image = "light_tool_flashlight_mese.png",
		})

		minetest.register_craft({
			output = "light_tool:flashlight_mese",
			recipe = {
				{"default:glass", "default:glass", "default:glass"},
				{"default:mese_post_light", "light_tool:reflector_gold", "default:mese_post_light"},
				{"default:steel_ingot", "light_tool:flashlight_gold", "default:steel_ingot"}
			}
		})
		light_tool.add_tool("light_tool:flashlight_mese", math.min(max_range, 110), allow_divergence and 10 or nil)
	end

	if tier >= 5 then
		local limit_string = ""
		if max_range < 110 then
			limit_string = max_range_limiting_string
		end
		minetest.register_tool("light_tool:flashlight_diamond", {
			description = "Ultra Flashlight\nEmits an 160m long beam of light. Useful for finding the light switch in your basement." .. limit_string,
			inventory_image = "light_tool_flashlight_diamond.png",
		})

		minetest.register_craft({
			output = "light_tool:flashlight_diamond",
			recipe = {
				{"default:steel_ingot", "default:glass", "default:steel_ingot"},
				{"default:mese_post_light", "default:diamond", "default:mese_post_light"},
				{"light_tool:flashlight_mese", "default:diamond", "light_tool:flashlight_mese"}
			}
		})
		light_tool.add_tool("light_tool:flashlight_diamond", math.min(max_range, 160), allow_divergence and 14 or nil)
	end

elseif make_mcl_recipes then
	if tier >= 2 then
		minetest.register_craftitem("light_tool:reflector_clay_iron", {
			description = "Clay Bowl with Iron\nA concave clay disc with some iron applied.",
			inventory_image = "light_tool_reflector_bronze_tin.png"
		})

		minetest.register_craft({
			output = "light_tool:reflector_clay_iron",
			recipe = {
				{"mcl_core:brick", "mcl_core:iron_ingot", "mcl_core:brick"},
				{"", "mcl_core:brick", ""}
			}
		})

		minetest.register_craftitem("light_tool:reflector_iron", {
			description = "Primitive Reflector\nA concave clay disc coated with a glossy layer of iron.",
			inventory_image = "light_tool_reflector_tin.png"
		})
	
		minetest.register_craft({
			type = "cooking",
			output = "light_tool:reflector_iron",
			recipe = "light_tool:reflector_clay_iron",
			cooktime = 15
		})

		local limit_string = ""
		if max_range < 30 then
			limit_string = max_range_limiting_string
		end
		minetest.register_tool("light_tool:flashlight_iron", {
			description = "Mini Flashlight\nBundles the light of a light source to a 30m long beam." .. limit_string,
			inventory_image = "light_tool_flashlight_iron.png",
		})

		minetest.register_craft({
			output = "light_tool:flashlight_iron",
			recipe = {
				{"mcl_core:glass", "mcl_core:glass", "mcl_core:glass"},
				{"mcl_core:iron_ingot", "group:torch", "mcl_core:iron_ingot"},
				{"mcl_core:iron_ingot", "light_tool:reflector_iron", "mcl_core:iron_ingot"}
			}
		})
		light_tool.add_tool("light_tool:flashlight_iron", math.min(max_range, 30))
	end

	if tier >= 3 then
		minetest.register_craftitem("light_tool:reflector_iron_gold", {
			description = "Reflector with Gold\nAn iron reflector with some gold.",
			inventory_image = "light_tool_reflector_tin_gold.png"
		})

		minetest.register_craft({
			type = "shapeless",
			output = "light_tool:reflector_iron_gold",
			recipe = {"light_tool:reflector_iron", "mcl_core:gold_ingot", "mcl_core:gold_ingot", "mcl_core:gold_ingot"}
		})

		minetest.register_craftitem("light_tool:reflector_gold", {
			description = "Parabolic Mirror\nA concave disc, coated with a highly reflective gold layer.",
			inventory_image = "light_tool_reflector_gold.png"
		})
	
		minetest.register_craft({
			type = "cooking",
			output = "light_tool:reflector_gold",
			recipe = "light_tool:reflector_iron_gold",
			cooktime = 10
		})

		local limit_string = ""
		if max_range < 70 then
			limit_string = max_range_limiting_string
		end
		minetest.register_tool("light_tool:flashlight_gold", {
			description = "Midi Flashlight\nUses advanced optics to form a 70m long beam." .. limit_string,
			inventory_image = "light_tool_flashlight_gold.png",
		})

		minetest.register_craft({
			output = "light_tool:flashlight_gold",
			recipe = {
				{"mcl_core:gold_ingot", "light_tool:flashlight_iron", "mcl_core:gold_ingot"},
				{"mcl_core:iron_ingot", "light_tool:reflector_gold", "mcl_core:iron_ingot"}
			}
		})
		light_tool.add_tool("light_tool:flashlight_gold", math.min(max_range, 70), allow_divergence and 10 or nil)
	end

	if tier >= 5 then
		local limit_string = ""
		if max_range < 160 then
			limit_string = max_range_limiting_string
		end
		minetest.register_tool("light_tool:flashlight_diamond", {
			description = "Maxi Flashlight\nEmits an 160m long beam of light. Useful for finding the light switch in your basement." .. limit_string,
			inventory_image = "light_tool_flashlight_diamond.png",
		})

		minetest.register_craft({
			output = "light_tool:flashlight_diamond",
			recipe = {
				{"mcl_core:glass", "mcl_core:glass", "mcl_core:glass"},
				{"mcl_core:iron_ingot", "mcl_core:diamond", "mcl_core:iron_ingot"},
				{"light_tool:flashlight_gold", "mcl_core:diamond", "light_tool:flashlight_gold"}
			}
		})
		light_tool.add_tool("light_tool:flashlight_diamond", math.min(max_range, 160), allow_divergence and 14 or nil)
	end
end
