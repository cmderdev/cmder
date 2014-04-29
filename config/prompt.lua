-- This file wraps the windows prompt defined in /vendor/init.bat
-- with lambda

local CMDER_ROOT = clink.get_env('CMDER_ROOT')
-- Using this function other lua packages
-- for clink can be loaded from vendor folder
function extend_package_path(path)
    package.path = CMDER_ROOT..'/vendor'..path..';'..package.path
end

function lambda_prompt_filter()
    clink.prompt.value = string.gsub(clink.prompt.value, ">", "\n\x1b[1;30;40mλ")
end

clink.prompt.register_filter(lambda_prompt_filter, 40)