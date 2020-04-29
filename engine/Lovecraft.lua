require(script.Parent.Importer)

local DEBUG_LOGGING_ENABLED = true

do
    _G.log = function(fmt, ...)
        if DEBUG_LOGGING_ENABLED then
            return print(string.format(fmt, ...))
        end
    end

    function _G.tableinspect(t, recursions)
        recursions = recursions or 0

        local tab = ""

        for i = 1, recursions do
            tab = tab .. "\t"
        end

        print(tab.."{ -- size "..#t)

        for index, value in pairs(t) do
            
            if type(value) == "table" then
                io.write(tab .."\t".. index .." =")
                _G.tableinspect(value, recursions+1)
            else
                print(tab .."\t".. index.." = "..value..",")
            end
        end

        print(tab.."}")

    end

    function _G.arrayinspect(t)
        io.write("{")

        for index, value in ipairs(t) do
            io.write(value..", ")
        end
        io.write("}\n")
    end

    function _G.foreach(t, func)
        for index, value in pairs(t) do
            func(index, value)
        end
    end

    function _G.tablecopy(orig)
        local orig_type = type(orig)
		local copy
		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
				copy[_G.tablecopy(orig_key)] = _G.tablecopy(orig_value)
			end
			setmetatable(copy, _G.tablecopy(getmetatable(orig)))
		else -- number, string, boolean, etc
			copy = orig
		end
		return copy
    end

    function _G.tablecontains(t, val)
        for idx, value in pairs(t) do
            if value == val then return true end
        end
        return false
    end

    --- Combines an arbitrary amount of tables, based on priority. The first table in gets to fill values first,
    -- and cannot have those values overridden by subsequent tables.
    -- @param ... any number of tables
    -- @return table
    function _G.tablecombine(...)
        local tabs = {...}
        local finalT = {}
        for idx, t in ipairs(tabs) do
            for index, value in pairs(t) do
                if finalT[index] == nil then
                    finalT[index] = value
                end
            end
        end
        return finalT
    end
end

local Lovecraft = {}

return Lovecraft