-- This file wraps the windows prompt defined in /vendor/init.bat
-- with lambda

local CMDER_ROOT = clink.get_env('CMDER_ROOT')
-- Using this function other lua packages
-- for clink can be loaded from vendor folder
function extend_package_path(path)
    package.path = CMDER_ROOT..'/vendor'..path..';'..package.path
end

-- Adds git status into prompt
function git_prompt_filter()
    extend_package_path('/clink-gitprompt/?.lua')
    local git_prompt = require('git_prompt_lib')
    local out = git_prompt.git_ps1()
    if out ~= '' then
        clink.prompt.value = clink.prompt.value..'('..out..')'
    end
end
clink.prompt.register_filter(git_prompt_filter, 39)

-- Adds nice lambda and a newline
function lambda_prompt_filter()
    clink.prompt.value = string.gsub(clink.prompt.value, ">", "")
    clink.prompt.value = clink.prompt.value .. '\n\x1b[1;30;40mλ '
end
clink.prompt.register_filter(lambda_prompt_filter, 40)
