--- A barebones class implementation, supporting only single inheritance.
-- @copyright Conarium Software
-- @release blah
-- @author Joshuu Oleary
-- @class file
-- @name BaseClass
local BaseClass = {}
BaseClass.__index = BaseClass
BaseClass.types = {"BaseClass"}

-- recursive copy table (including metatables)
local function table_copy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[table_copy(orig_key)] = table_copy(orig_value)
		end
		setmetatable(copy, table_copy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local function table_contains(t, val)
	for idx, value in pairs(t) do
		if value == val then return true end
	end
	return false
end

--- Instance creation callback, User defines class:__ctor(...) (AKA Class constructor) 
-- @usage function myClass:__ctor(arg) self.property = arg end
-- @name Constructor
-- @see BaseClass:new
-- @see BaseClass:subclass
function BaseClass:__ctor(...)

end

--- Returns a new instance of the class. Passes arguments to class:__ctor(...).
-- @usage local myInst = UserDefinedClass:new(...)
-- @param ... varargs
-- @return instance
function BaseClass:new(...)
    local inst = setmetatable({}, {__index = self})
    inst:__ctor(...)
    return inst
end

--- Creates a subclass object that can be extended.
-- Used for basic OOP.
-- @usage local Subclass = BaseClass:subclass("Sub")
-- @param classname string
-- @return Subclass
function BaseClass:subclass(classname)
	local t = setmetatable({}, {__index = self})
	t.__index = t
	t.classname = classname
	t.types = table_copy(self.types)
	table.insert(t.types, classname)
	t.super = self
	return t
end

--- Checks whether class instance is of a certain type.
-- @name BaseClass:isA
-- @return boolean
-- @param objtype string
function BaseClass:isA(objtype)
    if table_contains(self.types, objtype) then
        return true
    end
    return false
end

---
--
-- @usage print(tostring(class_or_instance)) --> classname

function BaseClass:__tostring()
    print(self.classname)
end

return BaseClass