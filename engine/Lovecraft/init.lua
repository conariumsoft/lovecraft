-- 
--
--
--
local using = require(script.using)
local baseclass = require(script.class)

-- reverse-order ipairs
local function ripairs(t)
    return function(t, n)
        n = n - 1
        if n > 0 then
            return n, t[n]
        end
    end,
    t, #t+1
end

local function newclass(cname)
    return baseclass:subclass(cname)
end


local function log(fmt, ...)
    return print(string.format(fmt, ...))
end

print("WTF?", script.Parent.Name)


_G.using = using
_G.newclass = newclass
_G.ripairs = ripairs
_G.baseclass = baseclass
_G.log = log


return {}