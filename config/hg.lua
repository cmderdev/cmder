---
 -- Find out current branch
 -- @return {false|mercurial branch name}
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
function get_hg_status()
    for line in io.popen("hg status"):lines() do
        return false
    end
    return true
end

function hg_prompt_filter()

    -- Colors for mercurial status
    local colors = {
        clean = "\x1b[1;37;40m",
        dirty = "\x1b[31;1m",
    }

    local branch = get_hg_branch()
    if branch then
        -- Has branch => therefore it is a mercurial folder, now figure out status
        if get_hg_status() then
            color = colors.clean
        else
            color = colors.dirty
        end

        clink.prompt.value = string.gsub(clink.prompt.value, "{hg}", color.."("..branch..")")
        clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "")
        return true
    end

    -- No mercurial present or not in mercurial file
    clink.prompt.value = string.gsub(clink.prompt.value, "{hg}", "")
    return false
end

clink.prompt.register_filter(hg_prompt_filter, 50)
