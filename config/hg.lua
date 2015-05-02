---
 -- Find out current branch
 -- @return {false|hg branch name}
---
function get_hg_branch()
    for line in io.popen("hg branch 2>nul"):lines() do
        local m = line:match("(.+)$")
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
function is_repo_clean()
    for line in io.popen("hg identify -i 2>nul"):lines() do
        local m = line:match(".*%+$")
        if m then
            return false
        end
    end

    return true
end

function hg_prompt_filter()

    -- Colors for git status
    local colors = {
        clean = "\x1b[1;37;40m",
        dirty = "\x1b[31;1m",
    }

    local branch = get_hg_branch()
    if branch then
        -- Has branch => therefore it is a hg folder, now figure out status
        if is_repo_clean() then
            color = colors.clean
        else
            color = colors.dirty
        end
        clink.prompt.value = string.gsub(clink.prompt.value, "{hg}", color.."("..branch..")")
    end

    -- No hg
    clink.prompt.value = string.gsub(clink.prompt.value, "{hg}", "")

    return false
end

clink.prompt.register_filter(hg_prompt_filter, 45)
