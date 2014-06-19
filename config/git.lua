-- Make sure GitPromptClient.exe, GitPromptCache.exe and git2.dll are in the same folder and also part of %path%.
function get_repo_details()
    for line in io.popen("GitPromptClient 2>nul"):lines() do
        local m = line:match("^%(.+")
        if m then
            return m
        end
    end

    return false
end

function git_prompt_filter()

    -- Colors for git status
    local colors = {
        clean = "\x1b[1;37;40m",
        dirty = "\x1b[31;1m",
    }

    local details = get_repo_details()

    if details then

        local branch, addedIndex, deletedIndex, modifiedIndex, addedWorkdir, deletedWorkdir, modifiedWorkdir, repoState  = string.match(details, "%((.*)%) i%[%+(%d+), %-(%d+), %~(%d+)%] w%[%+(%d+), %-(%d+), %~(%d+)%] %((.*)%)")

        local added = addedIndex + addedWorkdir
        local deleted = deletedIndex + deletedWorkdir
        local modified = modifiedIndex + modifiedWorkdir

        local total = added + deleted + modified

        if total > 0 then
            color = colors.dirty
        else
            color = colors.clean
        end

        if repoState ~= "" then
            -- specifies if any operation(merge/rebase etc..) in progress.. 
            repoState = " ("..repoState..")"
        end

        clink.prompt.value = string.gsub(clink.prompt.value, "{git}", color.."("..branch..")"..colors.clean.." [+"..added..", -"..deleted..", ~"..modified.."]"..repoState)
        return true
    end
    clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "")
    return false
end

clink.prompt.register_filter(git_prompt_filter, 50)

