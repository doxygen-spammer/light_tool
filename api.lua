-- You can use light_tool.add_tool(<ItemStack>, range) to define your own torches
-- and you can use light_tool.light_beam(pos, dir, range) to define your own light beam
-- also you can use  light_tool.register_glow_node(name) to make it so the beam travels through that block (e.g. To make it work underwater)

light_tool = {}
light_tool.tools = {}
light_tool.range = {}
light_tool.lightable_nodes = {}
light_tool.lit_nodes = {}
light_tool.light_beam = function(pos, dir, range, user)
	-- Normalize dir to have longest component == 1.
	local normalized_dir = vector.divide(dir, math.max(math.abs(dir.x), math.abs(dir.y), math.abs(dir.z), 0.01))

	-- Remember where light sources are placed, to send affected map block to player later:
	local light_positions = {}

	for i = 0, math.floor(range / vector.length(normalized_dir)) do
		local new_pos = vector.add(pos, vector.multiply(normalized_dir, i))

		local node = minetest.get_node(new_pos)
		local lightable = light_tool.check(light_tool.lightable_nodes, node.name)
		local lightable_index = light_tool.check_index(light_tool.lightable_nodes, node.name)
		local lit = light_tool.check(light_tool.lit_nodes, node.name)

        if node.name == "air" or node.name == "light_tool:light" then
			-- Place temporary light nodes in air:
			minetest.set_node(new_pos, {name = "light_tool:light"})
			light_positions[i] = new_pos
        elseif lightable or node.name == lit then
			-- Place temporary light nodes in registered glow nodes:
			local index = light_tool.check_index(light_tool.lightable_nodes, node.name)
			minetest.set_node(new_pos, {name = light_tool.lightable_nodes[index].."_glowing"})
			light_positions[i] = new_pos
        elseif node.name and minetest.registered_nodes[node.name].sunlight_propagates == false and not lightable and not lit then
			-- Hit an obstacle, beam ends heare.
			break
		end

		-- For better performance, only last 6 light sources cause map block updates directly to the player:
		light_positions[i - 6] = nil
	end

	-- Send affected map blocks to player. (Necessary for distances > 48 nodes.)
	light_tool.send_blocks_for_lights(pos, light_positions, light_tool.light_brightness)

	-- When light sources have been deleted, these map blocks must be sent again to player.
	minetest.after(0.5, function()
		light_tool.send_blocks_for_lights(pos, light_positions, light_tool.light_brightness)
	end)
end

-- Computes which blocks are affected by light sources of specified brightness,
-- and sends them to all players near `player_position`.
function light_tool.send_blocks_for_lights(player_position, light_positions, brightness)
	local affected_blocks = {}

	for _, np in pairs(light_positions) do
		local node_pos = vector.floor(np)
		local block_pos = vector.floor(vector.divide(node_pos, 16))

		-- Center block is always affected.
		affected_blocks[block_pos] = true

		-- For the 26 surrounding map blocks, check whether they are affected by lighting:
		for x_offset = -1, 1 do
			for y_offset = -1, 1 do
				for z_offset = -1, 1 do
					-- Calculate the manhattan length between light source and block center,
					-- and subtract the manhattan distance from block center to closest face/edge/corner.
					local block_to_check = vector.add(block_pos, vector.new(x_offset, y_offset, z_offset))
					local block_center = vector.add(vector.multiply(block_to_check, 16), vector.new(7.5, 7.5, 7.5))
					local distance_to_block_center = math.abs(node_pos.x - block_center.x) +
							math.abs(node_pos.y - block_center.y) +
							math.abs(node_pos.z - block_center.z)
					local block_center_to_outside = (math.abs(x_offset) + math.abs(y_offset) + math.abs(z_offset)) * 8
					local distance_to_block_outside = distance_to_block_center - block_center_to_outside

					-- If this manhattan distance is less than the light level, that block is affected.
					if distance_to_block_outside <= brightness then
						affected_blocks[block_to_check] = true
					end
				end
			end
		end
	end

	-- Search players standing near beam origin.
	-- Players standing elsewhere will not get these lighting updates,
	-- they will only see those parts of the beam which are close to them.
	local players = {}
	local objects = minetest.get_objects_inside_radius(player_position, 16)
	for _, object in pairs(objects) do
		if object:get_player_name() then
			table.insert(players, object)
		end
	end

	-- Send blocks to players
	for block_pos, _ in pairs(affected_blocks) do
		for _, player in pairs(players) do
			player:send_mapblock(block_pos)
		end
	end
end

light_tool.add_tool = function(toolname, range)
	table.insert(light_tool.tools, toolname)
	table.insert(light_tool.range, range)
end

light_tool.register_glow_node = function(name)
	-- Thanks to duane from the MT forums for helping me with this function
	if not (name and type(name) == 'string') then
		return
	end
	if not minetest.registered_nodes[name] then
		return
	end
	
	local node = minetest.registered_nodes[name]
	local def = table.copy(node)
	
	def.paramtype = "light"
	def.light_source = 4
	def.on_construct = function(pos)
		minetest.after(0.1, function()
	        minetest.set_node(pos, {name = name})
	    end)
    end
    
	minetest.register_lbm({
		name = ":"..name.."_glowing_removal",
		nodenames = {name.."_glowing"},
		run_at_every_load = true, 
		action = function(pos, node)
			minetest.set_node(pos, {name = name})
		end,
	})
	minetest.register_node(":"..name.."_glowing", def)
	table.insert(light_tool.lightable_nodes, name)
	table.insert(light_tool.lit_nodes, name.."_glowing")
end
light_tool.directional_pos = function(pos, direction, multiplier, addition)
	if addition == nil then
		addition = 0
	end
	return vector.floor({
		x = pos.x + (direction.x * multiplier+addition),
		y = pos.y  + (direction.y * multiplier+addition),
        z = pos.z + (direction.z * multiplier+addition),
	})
end
light_tool.falling_node_check = function(pos, dist)
	--return false --function is currently unstable
	local objects = minetest.get_objects_inside_radius(pos, dist)
	for i, ob in pairs(objects) do
		local en = ob:get_luaentity()
		if en and en.name == "__builtin:falling_node" then
			return true
		end
	end
	return false
	--
end

light_tool.check = function(table, value)
	for i,v in ipairs(table) do
		if v == value then
			return true
		else
			return false
		end
	end
end

light_tool.check_index = function(table, value)
	for i,v in ipairs(table) do
		if v == value then
			return i
		end
	end
end
