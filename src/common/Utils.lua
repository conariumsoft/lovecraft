local function ripairs(t)
    return function(t, n)
        n = n - 1
        if n > 0 then
            return n, t[n]
        end
    end,
    t, #t+1
end
local function matches(inst, t)
    for _, v in pairs(t) do
        if inst == v then return true end
    end
    return false
end


local function log(fmt, ...)
    return print(string.format(fmt, ...))
end


return {
    Matches = matches,
    ReverseIPairs = ripairs,
    FPrint = log,
}