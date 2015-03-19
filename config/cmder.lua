function lambda_prompt_filter()
    clink.prompt.value = string.gsub(clink.prompt.value, "{lamb}", "λ")
end

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
        clink.prompt.value = string.gsub(clink.prompt.value, "{hg}", "")
        return true
    end

    -- No git present or not in git file
    clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "")
    return false
end

clink.prompt.register_filter(lambda_prompt_filter, 40)
clink.prompt.register_filter(hg_prompt_filter, 50)
clink.prompt.register_filter(git_prompt_filter, 50)

local completions_dir = clink.get_env('CMDER_ROOT')..'/vendor/clink-completions/'
for _,lua_module in ipairs(clink.find_files(completions_dir..'*.lua')) do
    -- Skip files that starts with _. This could be useful if some files should be ignored
    if not string.match(lua_module, '^_.*') then
        local filename = completions_dir..lua_module
        -- use dofile instead of require because require caches loaded modules
        -- so config reloading using Alt-Q won't reload updated modules.
        dofile(filename)
    end
end