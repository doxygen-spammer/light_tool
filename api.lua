-- You can use light_tool.add_tool(tool_name, range, [divergence]) to define your own torches
-- and you can use light_tool.light_beam(pos, dir, range) to define your own light beam
-- also you can use  light_tool.register_glow_node(name) to make it so the beam travels through that block (e.g. To make it work underwater)

light_tool = {}
light_tool.lightable_nodes = {}
light_tool.lit_nodes = {}

-- Creates a beam of temporary light sources from <pos> to <pos + dir * range>, but blocked by obstacles.
-- Returns the last position where a light source was placed, or nil when no light source could be placed.
light_tool.light_beam = function(pos, dir, range)
	local last_pos = nil

	for i = 0, range do
        local new_pos = light_tool.directional_pos(pos, dir, i)
		local node = minetest.get_node(new_pos)
		
		
		local lightable = light_tool.check(light_tool.lightable_nodes, node.name)
		local lightable_index = light_tool.check_index(light_tool.lightable_nodes, node.name)
		local lit = light_tool.check(light_tool.lit_nodes, node.name)

		if node.name == "air" then
			-- Place temporary light nodes in air:
			minetest.set_node(new_pos, {name = "light_tool:light"})
			minetest.get_node_timer(new_pos):start(0.2)
			last_pos = new_pos
		elseif node.name == "light_tool:light" then
			-- Reset destruction timer for this light node:
			minetest.get_node_timer(new_pos):start(0.2)
			last_pos = new_pos
        elseif lightable or node.name == lit then
	        
	        local index = light_tool.check_index(light_tool.lightable_nodes, node.name)
	        minetest.set_node(new_pos, {name = light_tool.lightable_nodes[index].."_glowing"})
			last_pos = new_pos
        elseif node.name and minetest.registered_nodes[node.name].sunlight_propagates == false and not lightable and not lit then
			break
		end
     end

	 return last_pos
end

-- Format: divergence_table[i] = { { x = 0.717, y = 0.717 }, ... }
-- where (x, y) form a circle with i points and a radius of 1.
light_tool.divergence_table = {}
setmetatable(light_tool.divergence_table, {
	__index = function(divergence_table, i)
		divergence_table[i] = {}
		for angle_step = 1, 4 * i do
			local angle = (2 * math.pi) * (angle_step - 0.5) / (4 * i)
			table.insert(divergence_table[i], { x = math.sin(angle), y = math.cos(angle) })
		end
		return divergence_table[i]
	end
})

light_tool.light_beam_with_divergence = function(pos, dir, range, divergence)
	local beam_end = light_tool.light_beam(pos, dir, range)

	if not beam_end then
		return
	end

	if not (divergence > 0) then
		return
	end

	local normalized_dir = vector.normalize(dir)

	-- Calculate horizontal and vertical orthogonal unit vectors on dir:
	local horizontal_on_dir = vector.normalize(vector.cross(normalized_dir, vector.new(0, 1, 0)))
	if (vector.length(horizontal_on_dir) == 0) then
		-- dir is vertical, create an artifical horizontal unit vector:
		horizontal_on_dir = vector.new(1, 0, 0)
	end
	local vertical_on_dir = vector.normalize(vector.cross(normalized_dir, horizontal_on_dir))

	-- Emit additional beam directions:
	local total_divergence = divergence * range / 100
	local beam_ring_count = math.ceil(total_divergence / 5)
	local beam_ring_spacing = total_divergence / beam_ring_count

	for i_ring = 1, beam_ring_count do
		local radius = beam_ring_spacing * i_ring / range
		for _, point in ipairs(light_tool.divergence_table[i_ring]) do
			light_tool.light_beam(pos, vector.add(vector.add(normalized_dir, vector.multiply(horizontal_on_dir, radius * point.x)), vector.multiply(vertical_on_dir, radius * point.y)), range)
		end
	end
end

-- Format: tools["tool_name"] = { range = int }
light_tool.tools = {}

-- Registers the item <tool_name> as flashlight.
-- When held by a player, it will create a temporary light beam of length <range>.
-- If divergence is given, the beam diameter will widen by <2 * divergence> nodes every 100 nodes.
light_tool.add_tool = function(tool_name, range, divergence)
	light_tool.tools[tool_name] = { ["range"] = range, ["divergence"] = divergence or 0 }

	if divergence then
		-- Initialize divergence table
		for i = 1, math.ceil(range * divergence / 100 / 5) do
			local _ = light_tool.divergence_table[i]
		end
	end
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
