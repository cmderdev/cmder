-- This file wraps the windows prompt defined in /vendor/init.bat
-- with lambda

function lambda_prompt_filter()
    clink.prompt.value = string.gsub(clink.prompt.value, ">", "\n\x1b[1;30;40mλ")
end

clink.prompt.register_filter(lambda_prompt_filter, 40)