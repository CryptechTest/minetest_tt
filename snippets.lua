local S = minetest.get_translator("tt")

local function get_min_digtime(caps)
	local mintime
	local unique = true
	if caps.maxlevel and caps.maxlevel > 1 then
		unique = false
	end
	if caps.times then
		for r=1,3 do
			local time = caps.times[r]
			if caps.maxlevel and caps.maxlevel > 1 then
				time = time / caps.maxlevel
			end
			if (not mintime) or (time and time < mintime) then
				if time and mintime and (time < mintime) then
					unique = false
				end
				mintime = time
			end
		end
	end
	return mintime, unique
end

-- CORE SNIPPETS --

-- Custom text (_tt_help)
tt.register_snippet(function(itemstring)
	local def = minetest.registered_items[itemstring]
	if def._tt_help then
		return def._tt_help, false
	end
end)

-- Tool information (digging times, weapon stats)
tt.register_snippet(function(itemstring)
	local def = minetest.registered_items[itemstring]
	local desc = ""
	if def.tool_capabilities then
		-- Digging times
		local digs = ""
		local d
		if def.tool_capabilities.groupcaps then
			for group, caps in pairs(def.tool_capabilities.groupcaps) do
				local mintime, unique_mintime
				if caps.times then
					mintime, unique_mintime = get_min_digtime(caps)
					if mintime and (mintime > 0 and (not unique_mintime)) then
						d = S("Digs @1 blocks", group) .. "\n"
						d = d .. S("Minimum dig time: @1s", string.format("%.2f", mintime))
						digs = digs .. "\n" .. d
					elseif mintime and mintime == 0 then
						d = S("Digs @1 blocks instantly", group)
						digs = digs .. "\n" .. d
					end
				end
			end
			if digs ~= "" then
				desc = desc .. digs
			end
		end
		-- Weapon stats
		if def.tool_capabilities.damage_groups then
			for group, damage in pairs(def.tool_capabilities.damage_groups) do
				local msg
				if group == "fleshy" then
					if damage >= 0 then
						msg = S("Damage: @1", damage)
					else
						msg = S("Healing: @1", math.abs(damage))
					end
				else
					if damage >= 0 then
						msg = S("Damage (@1): @2", group, damage)
					else
						msg = S("Healing (@1): @2", group, math.abs(damage))
					end
				end
				desc = desc .. "\n" .. msg
			end
			local full_punch_interval = def.tool_capabilities.full_punch_interval
			if not full_punch_interval then
				full_punch_interval = 1
			end
			desc = desc .. "\n" .. S("Full punch interval: @1s", full_punch_interval)
		end
	end
	if desc == "" then
		desc = nil
	end
	return desc
end)

-- Food
tt.register_snippet(function(itemstring)
	local def = minetest.registered_items[itemstring]
	local desc
	if def._tt_food then
		desc = S("Food item")
		if def._tt_food_hp then
			local msg = S("+@1 food points", def._tt_food_hp)
			desc = desc .. "\n" .. msg
		end
	end
	return desc
end)

-- Node info
tt.register_snippet(function(itemstring)
	local def = minetest.registered_items[itemstring]
	local desc = ""

	-- Health-related node facts
	if def.damage_per_second then
		if def.damage_per_second > 0 then
			desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DANGER, S("Contact damage: @1 per second", def.damage_per_second))
		elseif def.damage_per_second < 0 then
			desc = desc .. "\n" .. minetest.colorize(tt.COLOR_GOOD, S("Contact healing: @1 per second", math.abs(def.damage_per_second)))
		end
	end
	if def.drowning and def.drowning ~= 0 then
		desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DANGER, S("Drowning damage: @1", def.drowning))
	end
	local tmp = minetest.get_item_group(itemstring, "fall_damage_add_percent")
	if tmp > 0 then
		desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DANGER, S("Fall damage: +@1%", tmp))
	elseif tmp == -100 then
		desc = desc .. "\n" .. minetest.colorize(tt.COLOR_GOOD, S("No fall damage"))
	elseif tmp < 0 then
		desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DEFAULT, S("Fall damage: @1%", tmp))
	end

	-- Movement-related node facts
	if minetest.get_item_group(itemstring, "disable_jump") == 1 and not def.climbable then
		if def.liquidtype == "none" then
			desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DEFAULT, S("No jumping"))
		else
			desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DEFAULT, S("No swimming upwards"))
		end
	end
	if def.climbable then
		if minetest.get_item_group(itemstring, "disable_jump") == 1 then
			desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DEFAULT, S("Climbable (only downwards)"))
		else
			desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DEFAULT, S("Climbable"))
		end
	end
	if minetest.get_item_group(itemstring, "slippery") >= 1 then
		desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DEFAULT, S("Slippery"))
	end
	local tmp = minetest.get_item_group(itemstring, "bouncy")
	if tmp >= 1 then
		desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DEFAULT, S("Bouncy (@1%)", tmp))
	end

	-- Node appearance
	tmp = def.light_source
	if tmp and tmp >= 1 then
		desc = desc .. "\n" .. minetest.colorize(tt.COLOR_DEFAULT, S("Luminance: @1", tmp))
	end


	if desc == "" then
		desc = nil
	end
	return desc, false
end)

