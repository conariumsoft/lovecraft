local BaseInteractive = require(script.Parent.BaseInteractive)

local Eraser = BaseInteractive:subclass("Eraser")

local timer = (1/10)

local wb_grid_size = 0.05 -- not really an actual grid...
local wb_marker_detection_distance = 0.1
local eraser_aggression = 0.05


function Eraser:OnGrab(hand, model, grip_point)
     
end

function Eraser:OnRelease(hand, model, grip_point)
    
end

function Eraser:OnSimulationStep(hand, model, dt, grip_point)
    local possible_objects = model.Base:GetTouchingParts()
			for _, part in pairs(possible_objects) do
				if part.Name == "GridMark" then
					part.Transparency = part.Transparency + eraser_aggression
					if (part.Transparency >= 1) then
						part:Destroy()
					end
				end
			end
end

function Eraser:OnTriggerState(hand, model, finger_pressure, grip_point)
    
end

return Eraser