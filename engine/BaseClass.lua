--[[
	borrowed from my jutils module. just a barebones class implementation.
	if multiple-inheritance or property protection is needed, upgrade to something like YACI or middleclass
	- josj
  ]]--
-- remember, this is ugly prototype code :D.

-- recursive copy table (including metatables)
local function jutils_table_copy(orig)
	local orig_type = type(orig)
		local copy
		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
				copy[jutils_table_copy(orig_key)] = jutils_table_copy(orig_value)
			end
			setmetatable(copy, jutils_table_copy(getmetatable(orig)))
		else -- number, string, boolean, etc
			copy = orig
		end
		return copy
end

local function jutils_table_contains(t, val)
	for idx, value in pairs(t) do
		if value == val then return true end
	end
	return false
end

local obj = {}

obj.__index = obj
obj.types = {"BaseObject"}


--- Instance creation callback, User defines class:init(...) and jutils calls it when class:new(...) is called.
-- @usage function myClass:init(arg) self.property = arg end
-- @name jutils.object:init
-- @see jutils.object:new
-- @see jutils.object:subclass
function obj:__ctor(...)

end

--- Returns a new instance of the class. Passes arguments to obj:init().
-- @see jutils.object:init
-- @see jutils.object:subclass
-- @usage local myInst = myClass:new(...)
-- @name jutils.object:new
function obj:new(...)
    local inst = setmetatable({}, {__index = self})
    inst:__ctor(...)
    return inst
end

    --- Creates a subclass object that can be extended.
    -- Used for basic OOP.
    -- @usage local myClass = jutils.obj:subclass("myclass")
    -- @name jutils.object:subclass
    -- @param classname
    -- @return object
    -- @see jutils.object:init
    -- @see jutils.object:new
function obj:subclass(classname)
	local t = setmetatable({}, {__index = self})
	t.__index = t
	t.classname = classname
	t.types = jutils_table_copy(self.types)
	table.insert(t.types, classname)
	t.super = self
	return t
end

    --- Returns true if object is of the specified type.
    -- @name jutils.object:isA
    -- @return boolean
function obj:isA(objtype)
    if jutils_table_contains(self.types, objtype) then
        return true
    end
    return false
end

function obj:__tostring()
    print(self.classname)
end

return obj