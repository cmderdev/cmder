-- default script for clink, called by init.bat when injecting clink

-- !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
-- !!! Use "%CMDER_ROOT%\config\<whatever>.lua" to add your lua startup scripts

-- luacheck: globals clink

-- At first, load the original clink.lua file
-- this is needed as we set the script path to this dir and therefore the original
-- clink.lua is not loaded.
local clink_lua_file = clink.get_env('CMDER_ROOT')..'\\vendor\\clink\\clink.lua'
dofile(clink_lua_file)

-- now add our own things...


local function get_uah_color()
  return uah_color or "\x1b[1;33;40m" -- Green = uah = [user]@[hostname]
end

local function get_cwd_color()
  return cwd_color or "\x1b[1;32;40m" -- Yellow cwd = Current Working Directory
end

local function get_lamb_color()
  return lamb_color or "\x1b[1;30;40m" -- Light Grey = Lambda Color
end


local function get_clean_color()
  return clean_color or "\x1b[1;37;40m"
end


local function get_dirty_color()
  return dirty_color or "\x1b[33;3m"
end


local function get_conflict_color()
  return conflict_color or "\x1b[31;1m"
end

local function get_unknown_color()
  return unknown_color or "\x1b[30;1m"
end

---
-- Makes a string safe to use as the replacement in string.gsub
---
local function verbatim(s)
    s = string.gsub(s, "%%", "%%%%")
    return s
end

-- Extracts only the folder name from the input Path
-- Ex: Input C:\Windows\System32 returns System32
---
local function get_folder_name(path)
  local reversePath = string.reverse(path)
  local slashIndex = string.find(reversePath, "\\")
  return string.sub(path, string.len(path) - slashIndex + 2)
end


---
-- Setting the prompt in clink means that commands which rewrite the prompt do
-- not destroy our own prompt. It also means that started cmds (or batch files
-- which echo) don't get the ugly '{lamb}' shown.
---
local function set_prompt_filter()
    -- get_cwd() is differently encoded than the clink.prompt.value, so everything other than
    -- pure ASCII will get garbled. So try to parse the current directory from the original prompt
    -- and only if that doesn't work, use get_cwd() directly.
    -- The matching relies on the default prompt which ends in X:\PATH\PATH>
    -- (no network path possible here!)
    local old_prompt = clink.prompt.value
    local cwd = old_prompt:match('.*(.:[^>]*)>')
    if cwd == nil then cwd = clink.get_cwd() end

    -- environment systems like pythons virtualenv change the PROMPT and usually
    -- set some variable. But the variables are differently named and we would never
    -- get them all, so try to parse the env name out of the PROMPT.
    -- envs are usually put in round or square parentheses and before the old prompt
    local env = old_prompt:match('.*%(([^%)]+)%).+:')
    -- also check for square brackets
    if env == nil then env = old_prompt:match('.*%[([^%]]+)%].+:') end

    -- Much of the below was 'borrowed' from https://github.com/AmrEldib/cmder-powerline-prompt
    -- Symbol displayed for the home dir in the prompt.
    if not prompt_homeSymbol then
      prompt_homeSymbol = "~"
    end

    -- Symbol displayed in the new line below the prompt.
    if not prompt_lambSymbol then
      prompt_lambSymbol = "λ"
    end

    if not prompt_type then
      prompt_type = "full"
    end

    if prompt_useHomeSymbol == nil then
      prompt_useHomeSymbol = false
    end

    if prompt_useUserAtHost == nil then
      prompt_useUserAtHost = false
    end

    if prompt_singleLine == nil then
      prompt_singleLine = false
    end

    if prompt_type == 'folder' then
        cwd = get_folder_name(cwd)
    end

    if prompt_useHomeSymbol and string.find(cwd, clink.get_env("HOME")) then
        cwd = string.gsub(cwd, clink.get_env("HOME"), prompt_homeSymbol)
    end

    uah = ''
    if prompt_useUserAtHost then
        uah = clink.get_env("USERNAME") .. "@" .. clink.get_env("COMPUTERNAME") .. ' '
    end

    cr = "\n"
    if prompt_singleLine then
      cr = ' '
    end

    if env ~= nil then env = "("..env..") " else env = "" end

    prompt = get_uah_color() .. "{uah}" .. get_cwd_color() .. "{cwd}{git}{hg}{svn}" .. get_lamb_color() .. cr .. "{lamb} \x1b[0m"
    prompt = string.gsub(prompt, "{uah}", uah)
    prompt = string.gsub(prompt, "{cwd}", cwd)
    prompt = string.gsub(prompt, "{env}", env)
    clink.prompt.value = string.gsub(prompt, "{lamb}", prompt_lambSymbol)
end

local function percent_prompt_filter()
    clink.prompt.value = string.gsub(clink.prompt.value, "{percent}", "%%")
end

---
-- Resolves closest directory location for specified directory.
-- Navigates subsequently up one level and tries to find specified directory
-- @param  {string} path    Path to directory will be checked. If not provided
--                          current directory will be used
-- @param  {string} dirname Directory name to search for
-- @return {string} Path to specified directory or nil if such dir not found
local function get_dir_contains(path, dirname)

    -- return parent path for specified entry (either file or directory)
    local function pathname(path)
        local prefix = ""
        local i = path:find("[\\/:][^\\/:]*$")
        if i then
            prefix = path:sub(1, i-1)
        end
        return prefix
    end

    -- Navigates up one level
    local function up_one_level(path)
        if path == nil then path = '.' end
        if path == '.' then path = clink.get_cwd() end
        return pathname(path)
    end

    -- Checks if provided directory contains git directory
    local function has_specified_dir(path, specified_dir)
        if path == nil then path = '.' end
        local found_dirs = clink.find_dirs(path..'/'..specified_dir)
        if #found_dirs > 0 then return true end
        return false
    end

    -- Set default path to current directory
    if path == nil then path = '.' end

    -- If we're already have .git directory here, then return current path
    if has_specified_dir(path, dirname) then
        return path..'/'..dirname
    else
        -- Otherwise go up one level and make a recursive call
        local parent_path = up_one_level(path)
        if parent_path == path then
            return nil
        else
            return get_dir_contains(parent_path, dirname)
        end
    end
end

-- adapted from from clink-completions' git.lua
local function get_git_dir(path)

    -- return parent path for specified entry (either file or directory)
    local function pathname(path)
        local prefix = ""
        local i = path:find("[\\/:][^\\/:]*$")
        if i then
            prefix = path:sub(1, i-1)
        end

        return prefix
    end

    -- Checks if provided directory contains git directory
    local function has_git_dir(dir)
        return clink.is_dir(dir..'/.git') and dir..'/.git'
    end

    local function has_git_file(dir)
        local gitfile = io.open(dir..'/.git')
        if not gitfile then return false end

        local git_dir = gitfile:read():match('gitdir: (.*)')
        gitfile:close()

        return git_dir and dir..'/'..git_dir
    end

    -- Set default path to current directory
    if not path or path == '.' then path = clink.get_cwd() end

    -- Calculate parent path now otherwise we won't be
    -- able to do that inside of logical operator
    local parent_path = pathname(path)

    return has_git_dir(path)
        or has_git_file(path)
        -- Otherwise go up one level and make a recursive call
        or (parent_path ~= path and get_git_dir(parent_path) or nil)
end

local function get_hg_dir(path)
    return get_dir_contains(path, '.hg')
end

local function get_svn_dir(path)
    return get_dir_contains(path, '.svn')
end

---
-- Find out current branch
-- @return {nil|git branch name}
---
local function get_git_branch(git_dir)
    git_dir = git_dir or get_git_dir()

    -- If git directory not found then we're probably outside of repo
    -- or something went wrong. The same is when head_file is nil
    local head_file = git_dir and io.open(git_dir..'/HEAD')
    if not head_file then return end

    local HEAD = head_file:read()
    head_file:close()

    -- if HEAD matches branch expression, then we're on named branch
    -- otherwise it is a detached commit
    local branch_name = HEAD:match('ref: refs/heads/(.+)')

    return branch_name or 'HEAD detached at '..HEAD:sub(1, 7)
end

---
-- Find out current branch
-- @return {false|mercurial branch name}
---
local function get_hg_branch()
    local file = io.popen("hg branch 2>nul")
    for line in file:lines() do
        local m = line:match("(.+)$")
        if m then
            file:close()
            return m
        end
    end
    file:close()

    return false
end

---
-- Find out current branch
-- @return {false|svn branch name}
---
local function get_svn_branch(svn_dir)
    local file = io.popen("svn info 2>nul")
    for line in file:lines() do
        local m = line:match("^Relative URL:")
        if m then
            file:close()
            return line:sub(line:find("/")+1,line:len())
        end
    end
    file:close()

    return false
end

---
-- Get the status of working dir
-- @return {bool}
---
local function get_git_status()
    local file = io.popen("git --no-optional-locks status --porcelain 2>nul")
    for line in file:lines() do
        file:close()
        return false
    end
    file:close()

    return true
end

---
-- Gets the conflict status
-- @return {bool} indicating true for conflict, false for no conflicts
---
function get_git_conflict()
    local file = io.popen("git diff --name-only --diff-filter=U 2>nul")
    for line in file:lines() do
        file:close()
        return true;
    end
    file:close()
    return false
end


---
-- Get the status of working dir
-- @return {bool}
---
local function get_hg_status()
    local file = io.popen("hg status -0")
    for line in file:lines() do
        file:close()
        return false
    end
    file:close()

    return true
end

---
-- Get the status of working dir
-- @return {bool}
---
local function get_svn_status()
    local file = io.popen("svn status -q")
    for line in file:lines() do
        file:close()
        return false
    end
    file:close()

    return true
end

---
-- Get the status of working dir
-- @return {bool}
---
local function get_git_status_setting()
    local gitStatusConfig = io.popen("git --no-pager config cmder.status 2>nul")

    for line in gitStatusConfig:lines() do
        if string.match(line, 'false') then
          gitStatusConfig:close()
          return false
        end
    end

    local gitCmdStatusConfig = io.popen("git --no-pager config cmder.cmdstatus 2>nul")
    for line in gitCmdStatusConfig:lines() do
        if string.match(line, 'false') then
          gitCmdStatusConfig:close()
          return false
        end
    end
    gitStatusConfig:close()
    gitCmdStatusConfig:close()

    return true
end

local function git_prompt_filter()

    -- Colors for git status
    local colors = {
        clean = get_clean_color(),
        dirty = get_dirty_color(),
        conflict = get_conflict_color(),
        unknown = get_unknown_color()
    }

    local git_dir = get_git_dir()
    cmderGitStatusOptIn = get_git_status_setting()

    if git_dir then
        -- if we're inside of git repo then try to detect current branch
        local branch = get_git_branch(git_dir)
        local color = colors.unknown
        if branch then
            if cmderGitStatusOptIn then
                -- Has branch => therefore it is a git folder, now figure out status
                local gitStatus = get_git_status()
                local gitConflict = get_git_conflict()

                color = colors.dirty
                if gitStatus then
                    color = colors.clean
                end

                if gitConflict then
                    color = colors.conflict
                end
            end

            clink.prompt.value = string.gsub(clink.prompt.value, "{git}", color.."("..verbatim(branch)..")")
            return false
        end
    end

    -- No git present or not in git file
    clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "")
    return false
end

local function hg_prompt_filter()

    local result = ""

    local hg_dir = get_hg_dir()
    if hg_dir then
        -- Colors for mercurial status
        local colors = {
            clean = get_clean_color(),
            dirty = get_dirty_color(),
        }

        local pipe = io.popen("hg branch 2>&1")
        local output = pipe:read('*all')
        local rc = { pipe:close() }

        -- strip the trailing newline from the branch name
        local n = #output
        while n > 0 and output:find("^%s", n) do n = n - 1 end
        local branch = output:sub(1, n)

        if branch ~= nil and
           string.sub(branch,1,7) ~= "abort: " and             -- not an HG working copy
           (not string.find(branch, "is not recognized")) then -- 'hg' not in path
            local color = colors.clean

            local pipe = io.popen("hg status -amrd 2>&1")
            local output = pipe:read('*all')
            local rc = { pipe:close() }

            if output ~= nil and output ~= "" then color = colors.dirty end
            result = color .. "(" .. branch .. ")"
        end
    end

    clink.prompt.value = string.gsub(clink.prompt.value, "{hg}", verbatim(result))
    return false
end

local function svn_prompt_filter()
    -- Colors for svn status
    local colors = {
        clean = get_clean_color(),
        dirty = get_dirty_color(),
    }

    if get_svn_dir() then
        -- if we're inside of svn repo then try to detect current branch
        local branch = get_svn_branch()
        local color
        if branch then
            if get_svn_status() then
                color = colors.clean
            else
                color = colors.dirty
            end

            clink.prompt.value = string.gsub(clink.prompt.value, "{svn}", color.."("..verbatim(branch)..")")
            return false
        end
    end

    -- No mercurial present or not in mercurial file
    clink.prompt.value = string.gsub(clink.prompt.value, "{svn}", "")
    return false
end

-- insert the set_prompt at the very beginning so that it runs first
clink.prompt.register_filter(set_prompt_filter, 1)
clink.prompt.register_filter(hg_prompt_filter, 50)
clink.prompt.register_filter(git_prompt_filter, 50)
clink.prompt.register_filter(svn_prompt_filter, 50)
clink.prompt.register_filter(percent_prompt_filter, 51)

local completions_dir = clink.get_env('CMDER_ROOT')..'/vendor/clink-completions/'
-- Execute '.init.lua' first to ensure package.path is set properly
dofile(completions_dir..'.init.lua')
for _,lua_module in ipairs(clink.find_files(completions_dir..'*.lua')) do
    -- Skip files that starts with _. This could be useful if some files should be ignored
    if not string.match(lua_module, '^_.*') then
        local filename = completions_dir..lua_module
        -- use dofile instead of require because require caches loaded modules
        -- so config reloading using Alt-Q won't reload updated modules.
        dofile(filename)
    end
end

if clink.get_env('CMDER_USER_CONFIG') then
  local cmder_config_dir = clink.get_env('CMDER_ROOT')..'/config/'
  for _,lua_module in ipairs(clink.find_files(cmder_config_dir..'*.lua')) do
    local filename = cmder_config_dir..lua_module
    -- use dofile instead of require because require caches loaded modules
    -- so config reloading using Alt-Q won't reload updated modules.
    dofile(filename)
  end
end
