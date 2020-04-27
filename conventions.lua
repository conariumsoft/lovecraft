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
--[[
		OBJECT GRABBING SCENARIOS:
		these are not final decisions on objects, or even objects that'll be in game
		i'm trying to cover the bases of interacting with objects in VR
		
		- marker
			* one handed
			* single grab
			* custom anim
			* special grip
		- .44 Magnum Revolver
			* one or two handed
			* first hand to grab controls trigger
			* grabs at cylinder/cylinder release (swings open)
			* secondary trigger = cock the hammer
		- M1911 pistol
			* grip can be one or two handed
			* secondary trigger = magazine release
			* slide grip point
			* custom anim, special grip
		- vz62 Skorpion
			* magazine grip point
			* secondary trigger = magazine release
			* one hand on handle
		- box
			* grip is held at the point of grabbing (no custom alignment)
			* can grab with inf hands
		- AkM
			* grip points
				charging handle
				barrel
				magazine
				handle (one hand at a time)
			* secondary trigger = magazine release
			* custom anim & grip alignment for primary hand

	]]
