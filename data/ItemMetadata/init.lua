_G.using "RBX.UserInputService"
_G.using "RBX.Workspace"
_G.using "RBX.Debris"
----------------------------------------------------------------------

--[[
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

function GripInformation:ToWeldConfiguration(master_part, follower_part)
	error("NotImplemented! Use subclass methods.")
end

local GripPoint = GripInformation:subclass("GripPoint")

function GripPoint:__ctor(Animation, Offset, PullForce, RotationForce, ApplyRotation, PullMax, RotateMax, PullResponsiveness, RotResponsiveness, PosRigid)
	self.Offset = Offset or CFrame.new(0, 0, 0)
	self.PullForce = PullForce or 100000
	self.RotationForce = RotationForce or 250
	self.PullMax = PullMax or 120000   -- max velocity that can be exerted on the assembly
	self.RotateMax = RotateMax or 500 -- max angular velocity (rotation)
	self.ApplyRotation = (ApplyRotation ~= nil) and ApplyRotation or false -- lock at initial grip rotation?
	self.AnimationForHand = Animation or nil
	self.PullResponsiveness = PullResponsiveness or 5
	self.RotResponsiveness = RotResponsiveness or 200
	self.PosRigid = PosRigid
end

function GripPoint:ToWeldConfiguration(master_part, follower_part)
	return  {
		pos_max_force = self.PullForce,
		rot_max_torque = self.RotationForce,
		pos_max_velocity = self.PullMax,
		rot_max_angular_velocity = self.RotateMax,
		rot_enabled = self.ApplyRotation,
		rot_responsiveness = self.RotResponsiveness,
		pos_responsiveness = self.PosResponsiveness,
		cframe_offset = self.Offset,
		pos_is_rigid = false,
	}
end

local GripLine = GripInformation:subclass("GripLine")

function GripLine:__ctor(Animation, Offset, AlignmentForce)
	
end

function GripLine:ToWeldConfiguration(master_part, follower_part)

end

--
local GripSocket = GripPoint:subclass("GripSocket")
function GripSocket:__ctor(props)
	GripInformation.__ctor(self, props)
end

local GripSurface = GripInformation:subclass("GripSurface")
function GripSurface:__ctor()

end


--------------------------------------------------------------------------
local Skorpion = require(script.Skorpion)
local Hecate   = require(script.Hecate)
local Saiga    = require(script.Saiga)

local marker_grip_animation
local skorpion_grip_animation

-- setup code finished. --
local ItemMetadata = {
	---------------------------------------------------------------------
	-- @section Static Environment Objects --
	["Environment"] = {
		grip_data = {
			DoorHandle = GripPoint:new()
		}
	},
	
	---------------------------------------------------------------------
	-- @section Guns --
	["Skorpion"] = {
		name = "Skorpion",
		grip_type = "GripPoint",
		grip_data = {
				-- GripPoint:new(anim, offset+rotation, pullforce, rotforce, applyrotation)
			Handle         = GripPoint:new(nil, CFrame.new(0, 0, 0),   80000,     350,   true,   math.huge),
			Magazine       = GripPoint:new(nil, CFrame.new(0,0,0),     15000,       0,   false,  math.huge),
			ChargingHandle = GripPoint:new(nil, CFrame.new(0, 0, 0),   500, 		0,   false), 
		},
		class = Skorpion,
	},
	["Saiga"] = {
		name = "Saiga",
		grip_type = "GripPoint",
		grip_data = {
			Handle = GripPoint:new(nil, CFrame.Angles(0, math.rad(180), 0), 100000, 400, true, math.huge),-- * CFrame.Angles(0, -math.rad(180), 0)),
			BarrelGrip = GripPoint:new(nil, CFrame.new(0, 0, 0), 15000, 0, false, math.huge),-- * CFrame.Angles(0, 0, -math.rad(180))),
			Magazine = GripPoint:new(),
		},
		class = Saiga,
	},
	["stupidSniper"] = {
		class = Hecate,
		name = "stupidSniper",
		grip_type = "GripPoint",
		grip_data = {
			Handle = GripPoint:new(nil, CFrame.new(0, 0, 0), 10000, 1500, true, 50000),-- * CFrame.Angles(0, -math.rad(180), 0)),
			BarrelShroud = GripPoint:new(nil, CFrame.new(0, 0, 0), 1000, 25, false, math.huge),-- * CFrame.Angles(0, 0, -math.rad(180))),
			Magazine = GripPoint:new(),
		},
	},
	---------------------------------------------------------------------
	-- @section Guns mags --
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
	},
	---------------------------------------------------------------------
	-- @section Guns --
	["Eraser"] = {
		name = "Eraser",
		grip_type = "Anywhere",
		class = require(script.Eraser),
	},
	["Marker"] = {
		class = require(script.Marker),
		name = "Marker",
		grip_type = "GripPoint",
		grip_data = {
			MarkerBase = GripPoint:new(),
		}
	},
}

return ItemMetadata