--------------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local items = ReplicatedStorage.Common.Items

local Skorpion = require(items.Firearms.Skorpion)
local Glock17  = require(items.Firearms.Glock17)
local Tec9	   = require(items.Firearms.Tec9)
local Glock18  = require(items.Firearms.Glock18)
local Vector   = require(items.Firearms.Vector)
local AK       = require(items.Firearms.AK)
local Magazine = require(items.Magazine)

return {
	["Default"] = {
		grip_type = "surface", -- "surface" || "point" || "etc"
		contextual_grips = false,
		primary_grip = nil,
		class = nil,
		grip_contexts = {

		},
		grips = {
			["X"] = {
				surface_grip = true,
			},
			
		},
	},
	---------------------------------------------------------------------
	-- @section Static Environment Objects --
	["Environment"] = {
		grips = {
			["DoorHandle"] = {}
		}
	},
	---------------------------------------------------------------------
	-- @section Guns --
	["Skorpion"] = {
		contextual_grips = true,
		primary_grip = "Handle",
		grip_contexts = {
			[{}] = { allows = {"Handle"} },
			[{"Handle"}] = { allows = {"Magazine", "ChargingHandle"} },
			[{"Handle", "ChargingHandle"}] = {
				stance = "PrimaryControl"
			},
			[{"Handle", "Magazine"}] = { stance = "PrimaryPointsToSecondary" }
		},
		grips = {
			["Handle"] = {
				animation = ...,
				offset = CFrame.new(0, 0, 0)
			},
			["ChargingHandle"] = {},
			["Magazine"] = {},
		},
		class = Skorpion,
	},
	["Tec9"] = {
		class = Tec9,
		grips = {
			Handle = {
				offset = CFrame.Angles(0, -math.rad(90), -math.rad(90)),
			},
			Magazine = {},
			ChargingHandle = {},
		},
	},
	["Glock17"] = {
		grips = {
			Handle = {},
			MagRelease = {},
			Slide = {},
		},
		class = Glock17,
	},
	["Vector"] = {
		grips = {
			Handle = {
				offset = CFrame.Angles(math.rad(89), 0, 0)
			},
			Magazine = {},
			Slide = {}
		},
		class = Vector
	},
	["Glock18"] = {
		grips = {
			Handle = {},
			Magazine = {},
			Slide = {},
		},
		class = Glock18,
	},
	---------------------------------------------------------------------
	-- @section Guns mags --
	["SkorpionMagazine"] = {
		name = "Magazine",
		grips = {
			Magazine = {},
		},
		class = Magazine,
	},
	["GlockMag"] = {
		class = Magazine,
	},
	["Tec9Mag"] = {
		class = Magazine,
	},
	---------------------------------------------------------------------
	-- @section Not Guns --
	["LightSaber"] = {
		grips = {
			MeshPart = {},
		}
	},
}