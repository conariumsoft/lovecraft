local BaseInteractive = require(script.Parent.BaseInteractive)

local Marker = BaseInteractive:subclass("Marker")

local timer = (1/10)

local wb_grid_size = 0.05 -- not really an actual grid...
local wb_marker_detection_distance = 0.1
local eraser_aggression = 0.05

local function CreateGridMark(MarkColor)
    local p = Instance.new("Part")
	p.Name = "GridMark"
    p.Size = Vector3.new(wb_grid_size, wb_grid_size, wb_grid_size)
    p.Color = MarkColor
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.SmoothPlastic
    p.Anchored = true
    return p
end

function Marker:OnGrab(hand, model, grip_point)
     
end

function Marker:OnRelease(hand, model, grip_point)
    
end

function Marker:OnSimulationStep(hand, model, dt, grip_point)
        local ray = Ray.new(
            model.Tip.Position, 
            model.Tip.CFrame.LookVector * .1
            )
        local part, hit_position = game.Workspace:FindPartOnRayWithWhitelist(ray,{Workspace.Whiteboard})

        if (part and part.Name == "Whiteboard") then
            local new_mark = CreateGridMark(model.Tip.Color)
            new_mark.Position = hit_position
            new_mark.Parent = Workspace.Grid
        end
end

function Marker:OnTriggerState(hand, model, finger_pressure, grip_point)
    
end

return Marker