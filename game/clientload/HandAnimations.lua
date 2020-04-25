local anims = script

local HandAnimations = {
	["IndexFingerCurl"] = {
		["Left"]  = script.CloseIndexLeft,
		["Right"] = script.CloseIndexRight,
	},
	["PalmCurl"] = {
		["Left"]  = script.CloseGripLeft,
		["Right"] = script.CloseGripRight,
	},
	--[[["GenericGripPen"] = {
		["Left"]  = script.MarkerRight,
		["Right"] = script.MarkerRight
	},
	["GenericGripPistol"] = {
		["Left"]  = script.GunRight,
		["Right"] = script.GunRight,
	},
	-- just to show that this is accepted...
	["AmbidextriousGrip?"] = script.GunRight,
	--["GenericGripKnife"] = anims.etc, Non-existant.]]
}

return HandAnimations