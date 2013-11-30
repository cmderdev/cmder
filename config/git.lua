---
 -- Find out current branch
 -- @return {false|git branch name}
---
function get_git_branch()
    for line in io.popen("git branch 2>nul"):lines() do
        local m = line:match("%* (.+)$")
        if m then
            return m
        end
    end

    return false
end

---
 -- Get the status of working dir
 -- @return {bool}
---
function get_git_status()
    return os.execute("git diff --quiet --ignore-submodules HEAD")
end

function git_prompt_filter()

    -- Colors for git status
    local colors = {
        clean = "\x1b[1;37;40m",
        dirty = "\x1b[31;1m",
    }

    local branch = get_git_branch()
    if branch then
        -- Has branch => therefore it is a git folder, now figure out status
        if get_git_status() then
            color = colors.clean
        else
            color = colors.dirty
        end

        clink.prompt.value = string.gsub(clink.prompt.value, "{git}", color.."("..branch..")")
        return true
    end

    -- No git present or not in git file
    clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "")
    return false
end

clink.prompt.register_filter(git_prompt_filter, 50)