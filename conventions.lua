--[[
	btw: coding convention is as follows
	stick to it as best as possible, it'll help keep confusion low

	
	-- locals to be snake_case
	local some_thing = 3
	-- constants to be capital SNAKE_CASE
	local SOME_PHYSICS_CONSTANT = 42069

	-- local functions snake_case
	local function perform_operation(arg_one, arg_two)
	-- arguments as well

	-- Non-Class modules (in&out of module)
	local Singleton = ...
	Singleton.RunSomeCode()

	-- CapCase for class definitions
		local ClassObject = ...
	
		function ClassObject:Method()
		end

		ClassObject:Method()
	-- use _CapCase if method should be internally used
		ClassObject:_PrivateMethod()
	-- ditto for properties
		ClassObject.Property = 5
		ClassObject._PrivateProperty = 420

		local class_inst = ClassObject:new()


]]