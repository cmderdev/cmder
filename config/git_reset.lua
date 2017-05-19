function git_reset_match_generator(text, first, last)
	local found_matches = false;
	if rl_state.line_buffer:find("^git reset ") then
		local results = {}
		local has_ref = not rl_state.line_buffer:find("^git reset[ ]*$")
		local lineIndex = 1
		for line in io.popen("git log --oneline"):lines() do
			if not has_ref then
				results[#results+1] = line
				found_matches = true;
			elseif #text > 0 and line:find("^"..text) then
				results[#results+1] = line
				found_matches = true;
			end
		end
			
		if #results == 1 then
			local index = string.find(results[1], " ") - 1
			local commit_ref = string.sub(results[1], 1, index)
			clink.add_match(commit_ref)
		elseif #results > 1 then
			local padding = #(tostring(#results))
			for i=1,#results do
				-- Since you can't re-order the matches, we add a number at the beginning
				if (padding > 0) then
					local match_to_add = string.format("%0"..tostring(padding).."d", i)
					match_to_add = match_to_add.." "..results[i]
					clink.add_match(match_to_add)
				else
					clink.add_match(colors.padding..tostring(padding)..colors.normal.." "..results[i])
				end
			end
		end
	end
 
    return found_matches
end
 
clink.register_match_generator(git_reset_match_generator, 10)