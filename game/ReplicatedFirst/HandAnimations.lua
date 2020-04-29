local function LoadAnimFile(id)
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	anim.Parent = script
	return anim
end

local idx_left   = LoadAnimFile("rbxassetid://4921338211")
local idx_right  = LoadAnimFile("rbxassetid://4921265382")
local grip_left  = LoadAnimFile("rbxassetid://4921113867")
local grip_right = LoadAnimFile("rbxassetid://4921074129")


local HandAnimations = {
	["IndexFingerCurl"] = {
		["Left"]  = idx_left,
		["Right"] = idx_right,
	},
	["PalmCurl"] = {
		["Left"]  = grip_left,
		["Right"] = grip_right,
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