require(script.Parent.Importer)

local DEBUG_LOGGING_ENABLED = true


_G.log = function(fmt, ...)
    if DEBUG_LOGGING_ENABLED then
        return print(string.format(fmt, ...))
    end
end

local Lovecraft = {}

return Lovecraft