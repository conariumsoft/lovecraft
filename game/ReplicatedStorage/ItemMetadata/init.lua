_G.using "RBX.UserInputService"
_G.using "RBX.Workspace"
_G.using "RBX.Debris"
----------------------------------------------------------------------

--[[
	im thinking ill need different grip configurations for different objects:
All of these describe information about how bodymovers are applied to the hands+grabbed object
All values will be applied local-coordinates from the center of the grabbed part.
```
GripBase
	PullStrength
	HandFollows
	HandAnimation

GripPoint -- hand is locked to a point
  Offset CFrame
  AllowRotation bool -- whether hand can rotate freely around the point

GripPointAligned -- ditto, but rotation is locked to specific orientation
  Orientation CFrame
  Offset CFrame

GripLine -- hand is locked to a line, centere
  bool AllowPerpendicularRotation -- can hand rotate along opposite axis
  bool AllowMovement -- can the hand slide up and down the gripline
  bool HandSlidesOff -- if hand will disconnect when slid off the end
  CFrame LineCenter
  CFrame LineOrientation
  CFrame LineLength

GripLineCurve -- ditto, but i'll use a formula to describe a curved shape (MAY NOT IMPLEMENT)

GripSurface -- hand can grab anywhere on the object
	-- perhaps work in corner checking on rectangular objects
	-- and play a corner grab anim on the hand.
	-- won't be perfect, but could look quite decent at a glance
	-- also should probably have a sphere animation.
```
]]

local GripInformation = _G.newclass("GripInformation")

function GripInformation:__ctor(props)
	self.Animation = nil -- string
	
end

function GripInformation:__default(propname, t, default) -- default
	if t[propname] then
		self[propname] = t[propname]
	else
		self[propname] = default
	end
end

function GripInformation:__pullfrom(t)
	for key, val in pairs(t) do
		if self[key] then
			self[key] = val
		end
	end
end

function GripInformation:ToWeldConfiguration()
	error("NotImplemented! Use subclass methods.")
end


local function default(propname, props, default)
	if props[propname] then
		return props[propname]
	else
		return default
	end
end

local GripPoint = GripInformation:subclass("GripPoint")

function GripPoint:__ctor(Animation, Offset, PullForce, RotationForce, ApplyRotation)
	--GripInformation.__ctor(self, props)

	--self:__default("AllowRotation", props, false)

	self.Offset = Offset or CFrame.new(0, 0, 0)
	self.PullForce = PullForce or 100000
	self.RotationForce = RotationForce or 50000
	self.PullMax = 25000   -- max velocity that can be exerted on the assembly
	self.RotateMax = 50000 -- max angular velocity (rotation)
	self.ApplyRotation = (ApplyRotation ~= nil) and ApplyRotation or false -- lock at initial grip rotation?
	self.AnimationForHand = Animation or nil

	--self:__pullfrom(props)
end

function GripPoint:ToWeldConfiguration()
	return {

		pos_max_force = self.PullForce,
		rot_max_torque = self.RotationForce,
		pos_max_velocity = self.PullMax,
		rot_max_angular_velocity = self.RotateMax,
		rot_enabled = self.ApplyRotation,
		rot_responsiveness = 200,
		pos_responsiveness = 200,
		cframe_offset = self.Offset,
	}
end


local GripPointAligned = GripPoint:subclass("GripPointAligned")

function GripPointAligned:__ctor(props)
	GripPoint.__ctor(self, props)

	self.Orientation = CFrame.Angles(0, 0, 0)
end

local GripLine = GripInformation:subclass("GripLine")

function GripLine:__ctor()

end


local GripLineCurve = GripInformation:subclass("GripLineCurve")

function GripLineCurve:__ctor()


end

local GripSurface = GripInformation:subclass("GripSurface")


function GripSurface:__ctor()

end


--------------------------------------------------------------------------
local Skorpion = require(script.Skorpion)

local marker_grip_animation
local skorpion_grip_animation

-- setup code finished. --
local ItemMetadata = {

	["Environment"] = {
		grip_data = {
			DoorHandle = GripPoint:new()
		}
	},
	["Marker"] = {
		class = require(script.Marker),
		name = "Marker",
		--grip_type = "GripPoint",
		--grip_data = {
		--	MarkerBase = {
		--		animation = marker_grip_animation,
		--		offset = CFrame.new(0,0,0) * CFrame.Angles(0,0,0),
		--	}
		--}
	},
	["Eraser"] = {
		name = "Eraser",
		grip_type = "Anywhere",
		class = require(script.Eraser),
	},
	["Skorpion"] = {
		name = "Skorpion",
		grip_type = "GripPoint",
		grip_data = {
				-- GripPoint:new(anim, offset+rotation, pullforce, rotforce, applyrotation)
			Handle         = GripPoint:new(nil, CFrame.new(0, 0, 0),   20000,     250,   true),
			Magazine       = GripPoint:new(nil, CFrame.new(0,0,0),     15000,       0,   false),
			ChargingHandle = GripPoint:new(), 
		},
		class = Skorpion,
	},
	["Saiga"] = {
		name = "Saiga",
		grip_type = "GripPoint",
		grip_data = {
			--[[
				lhandmaxvel - 600
				lhandposforce - 15000
				rhandmaxangular - 250
				rhandmaxvel - 1000
				rhandposforce - 20000
				rhandrottorque - 250
			]]--
			Handle = GripPoint:new(nil, CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0)),
			Barrel = GripPoint:new(nil, CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, -math.rad(180))),
		},
		class = Skorpion,
	},
	["SkorpionMagazine"] = {
		name = "Magazine",
		grip_type = "Anywhere",
		grip_data = {
			Magazine = GripPoint:new()
		}
	},
	["LightSaber"] = {
		name = "LightSaber",
		grip_type = "GripPoint",
		grip_data = {
			MeshPart = GripPoint:new()
		}
	}
}

return ItemMetadata