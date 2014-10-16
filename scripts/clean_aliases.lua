--[[
Cmder adds aliases to its aliases file without caring for duplicates.
This can result in the aliases file becoming bloated. This script cleans
the aliases file.
]]

local aliases = {}
local alias_file = os.getenv('CMDER_ROOT') .. "/config/aliases"

-- from http://www.lua.org/pil/19.3.html
-- function to create an iterator that returns the key-value pairs
-- sorted by keys
local function pairsByKeys (t, f)

    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, f)

    local i = 0                 -- iterator variable
    local iter = function ()    -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end

    return iter
end

-- First step
-- Read the aliases file line by line, and put every entry in
-- a dictionary. The newer aliases being the last, the new will
-- always be kept over the old.
for line in io.lines(alias_file) do

    -- Doskey actually accepts a lot of weird characters in macros
    -- definitions.
    local key, value = line:match('([^=%s<>]+)=(.*)')

    if key then
        aliases[key] = value
    else
        print('Invalid macro definition:   '..line)
    end

end

-- Second step
-- Write back the aliases. Sort them to make the file look nice.
local f = io.open(alias_file, 'w')

for key, value in pairsByKeys(aliases) do
    -- write the pair only if the value is not empty
    if value then
        f:write(key .. '=' .. value .. '\n')
    end
end

f:close()