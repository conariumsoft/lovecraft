_G.using "RBX.UserInputService"
_G.using "RBX.Workspace"
_G.using "RBX.Debris"

----------------------------------------------------------------------
-- Grip Information Abstract Class -- 

local GripInformation = _G.newclass("GripInformation")

---------------------------------
local GripPoint = GripInformation:subclass("GripPoint")


function GripPoint:__ctor(Animation, Offset)
	self.Offset = Offset or nil
	self.AnimationForHand = Animation or nil
end

local GripLine = GripInformation:subclass("GripLine")

function GripLine:__ctor(Animation, Offset, AlignmentForce)
	
end

--
local GripSocket = GripPoint:subclass("GripSocket")
function GripSocket:__ctor(props)
	GripInformation.__ctor(self, props)
end

local GripSurface = GripInformation:subclass("GripSurface")
function GripSurface:__ctor()

end

--[[
	-- thanks to DevLuke
	transform.rotation = rotOffset * Quaternion.LookRotation(reverseSecondaryAim ? 
	(primaryGrip.EquippedHand.lastControllerPos - (secondaryGrip.EquippedHand.lastControllerPos)) : 
	((secondaryGrip.EquippedHand.lastControllerPos) - primaryGrip.EquippedHand.lastControllerPos), 
	primaryGrip.EquippedHand.lastControllerRot * Vector3.forward) * recoilOffset;
]]

--------------------------------------------------------------------------
local Skorpion = require(script.Parent.ItemClasses.Firearms.Skorpion)
local Hecate   = require(script.Parent.ItemClasses.Firearms.Hecate)
local Saiga    = require(script.Parent.ItemClasses.Firearms.Saiga)
local Glock17  = require(script.Parent.ItemClasses.Firearms.Glock17)
local Tec9	   = require(script.Parent.ItemClasses.Firearms.Tec9)
local Glock18  = require(script.Parent.ItemClasses.Firearms.Glock18)
local Vector   = require(script.Parent.ItemClasses.Firearms.Vector)
local Magazine = require(script.Parent.ItemClasses.Magazine)

-- TODO: discard GripPoint system. no longer nessecary.
-- TODO: pack in data about animations, grip limitations, hierarchy, etc

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
			Handle         = GripPoint:new(nil, CFrame.new(0, 0, 0)),
			--Magazine       = GripPoint:new(nil, CFrame.Angles(0, math.rad(180), 0)),
			ChargingHandle = GripPoint:new(nil), 
		},
		class = Skorpion,
	},
	["Tec9"] = {
		name = "Tec9",
		grip_type = "GripPoint",
		class = Tec9,
		grip_data = {
			Handle = GripPoint:new(nil, CFrame.new(0, 0, 0)*CFrame.Angles(0, -math.rad(90), -math.rad(90))),
			--Magazine = GripPoint:new(nil, CFrame.new(0, 0, 0)),
			ChargingHandle = GripPoint:new(nil, CFrame.new(0, 0, 0)),
		},
	},
	["Glock17"] = {
		name = "Glock17",
		grip_type = "GripPoint",
		grip_data = {
			Handle = GripPoint:new(nil, CFrame.new(0, 0, 0)),
			MagRelease = GripPoint:new(nil, CFrame.new(0, 0, 0)),
			Slide = GripSurface:new(nil, CFrame.new(0, 0, 0)),
		},
		class = Glock17,
	},
	["Vector"] = {
		Name = "Vector",
		grip_data = {
			Handle = GripPoint:new(nil, CFrame.Angles(math.rad(89), 0, 0)),
			Magazine = GripPoint:new(nil, CFrame.new(0, 0, 0)),
			Slide = GripPoint:new(nil, CFrame.new(0, 0, 0)),
		},
		class = Vector
	},
	["Glock18"] = {
		name = "Glock18",
		grip_type = "GripPoint",
		grip_data = {
			Handle = GripPoint:new(nil, CFrame.new(0, 0, 0)),
			Magazine = GripPoint:new(nil, CFrame.new(0, 0, 0)),
			Slide = GripPoint:new(nil, CFrame.new(0, 0, 0)),
		},
		class = Glock18,
	},
	["Saiga"] = {
		name = "Saiga",
		grip_type = "GripPoint",
		grip_data = {
			Handle = GripPoint:new(nil, CFrame.Angles(0, math.rad(0), 0)),-- * CFrame.Angles(0, -math.rad(180), 0)),
			BarrelGrip = GripPoint:new(nil, CFrame.new(0, 0, 0)),-- * CFrame.Angles(0, 0, -math.rad(180))),
			Magazine = GripPoint:new(nil, CFrame.new(0, 0, 0)),
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
			Magazine = GripPoint:new(nil, CFrame.new(0, 0, 0)),
		},
	},
	---------------------------------------------------------------------
	-- @section Guns mags --
	["SkorpionMagazine"] = {
		name = "Magazine",
		grip_type = "Anywhere",
		grip_data = {
			Magazine = GripPoint:new(nil, CFrame.new(0, 0, 0))
		},
		class = Magazine,
	},
	["GlockMag"] = {
		name = "GlockMag",
		class = Magazine,
	},
	["Tec9Mag"] = {
		name = "Tec9Mag",
		class = Magazine,
	},
	
	---------------------------------------------------------------------
	-- @section Not Guns --
	["LightSaber"] = {
		name = "LightSaber",
		grip_type = "GripPoint",
		grip_data = {
			MeshPart = GripPoint:new(nil, CFrame.new(0, 0, 0))
		}
	},
}

return ItemMetadata