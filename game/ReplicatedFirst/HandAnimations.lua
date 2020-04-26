local this = script

local HandAnimations = {
	["IndexFingerCurl"] = {
		["Left"]  = this.CloseIndexLeft,
		["Right"] = this.CloseIndexRight,
	},
	["PalmCurl"] = {
		["Left"]  = this.CloseGripLeft,
		["Right"] = this.CloseGripRight,
	},
	--[[["GenericGripPen"] = {
		["Left"]  = this.MarkerRight,
		["Right"] = this.MarkerRight
	},
	["GenericGripPistol"] = {
		["Left"]  = this.GunRight,
		["Right"] = this.GunRight,
	},
	-- just to show that this is accepted...
	["AmbidextriousGrip?"] = this.GunRight,
	--["GenericGripKnife"] = anims.etc, Non-existant.]]
}

return HandAnimations