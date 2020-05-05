_G.using "RBX.UserInputService"
_G.using "RBX.Workspace"
_G.using "RBX.Debris"
_G.using "Lovecraft.BaseClass"
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

local GripInformation = BaseClass:subclass("GripInformation")

function GripInformation:__ctor(props)
	self.Animation = nil -- string
	self.RotationTorque = 0
	self.PositionForce = 0
	
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

local function default(propname, props, default)
	if props[propname] then
		return props[propname]
	else
		return default
	end
end

local GripPoint = GripInformation:subclass("GripPoint")

function GripPoint:__ctor(props)
	GripInformation.__ctor(self, props)

	--self:__default("AllowRotation", props, false)

	self.AllowRotation = false -- lock at initial grip rotation?
	self.Offset = CFrame.new(0, 0, 0)

	self:__pullfrom(props)
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

--[[
	Item Metadata API spec:
	ModelName = {
		BaseClass class,
		string name, (Required)
		string grip_type, <"GripPoint", "GripLine", "Anywhere"> (Required)
		table grip_data { (Required if grip_type == "GripPoint")
			PartName = {
				string animation,
				CFrame offset,
			},
			PartName2 = {
				string animation,
				CFrame offset,
			}
		}
	}	
]]
-- setup code finished. --
local ItemMetadata = {
	["Environment"] = {

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
			--[[
				lhandmaxvel - 600
				lhandposforce - 15000
				rhandmaxangular - 250
				rhandmaxvel - 1000
				rhandposforce - 20000
				rhandrottorque - 250
			]]--
			Handle = {
				offset = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0),
				animation = skorpion_grip_animation,
				not_rigid = true,
			},
			Magazine = {
				offset = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0),
				--not_rigid = true,
				
			},
			ChargingHandle = {
				offset = CFrame.new(0, 4, 0),
				not_rigid = true,
				stiff = false,
			},
		},
		class = Skorpion,
	},
	["SkorpionMagazine"] = {
		name = "Magazine",
		grip_type = "Anywhere",
		grip_data = {
			Magazine = {
				offset = CFrame.new(0, 0, 0),
			}
		}
	}
}
	
return ItemMetadata