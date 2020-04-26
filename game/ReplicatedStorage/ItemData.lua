local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
-- TODO: put in separate module

local marker_grip_animation
local skorpion_grip_animation
local default_grip_animation = ...
local R2Down = false

UserInputService.InputBegan:Connect(function(inp,gpe)
	if inp.KeyCode == Enum.KeyCode.ButtonR2 and not gpe then
		R2Down = true
	end
end)
UserInputService.InputEnded:Connect(function(inp,gpe)
	if inp.KeyCode == Enum.KeyCode.ButtonR2 and not gpe then
		R2Down = false
	end
end)
--[[
note: I may later on use OOP for interactive item data generation.
1. for defaults
2. for code reuse
3. etc

local interactive = BaseObject:subclass("InteractiveObject")

function interactive:__ctor(obj_name, obj_data)
	
end
  ]]--

-- will move these outta this script later
local wb_grid_size = 0.05 -- not really an actual grid...
local wb_marker_detection_distance = 0.1
local eraser_aggression = 0.05

local function Scorpion(player, hand, scorpion, delta)
		print("Scorpion fired!")
		local newVelocityModifier = Instance.new("BodyVelocity")
		newVelocityModifier.Velocity = hand.Thumb.TE.CFrame.UpVector*75
		newVelocityModifier.Parent = hand.PrimaryPart
		game:GetService("RunService").RenderStepped:Wait()
		newVelocityModifier:Destroy()
end

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

local skorpion_deb = false

-- setup code finished. --
local InteractiveObjectMetadata = {
	["Marker"] = {
		name = "Marker",
		grip_type = "Custom",
		grip_anim = marker_grip_animation,
		grip_orientation = {
			offset = Vector3.new(-0.1, 0.22, 0.2),
			rotation = CFrame.new(0,0,0,-4.37113883e-08,-1,1.74845553e-07,0.0871559754,-1.77989961e-07,-0.996194959,0.996194959,-2.83062302e-08,0.0871559754),
		},
		on_grab_begin = function(player, hand, model)
			
		end ,
		on_grab_release = function(player, hand, model)
			
		end ,
		on_grab_step = function(player, hand, model, step)
			local ray = Ray.new(
	        	model.Tip.Position, 
	        	model.Tip.CFrame.LookVector * wb_marker_detection_distance
		   	 )
		    local part, hit_position = Workspace:FindPartOnRayWithWhitelist(ray,{Workspace.Whiteboard})
	
		    if (part and part.Name == "Whiteboard") then
		        local new_mark = CreateGridMark(model.Tip.Color)
		        new_mark.Position = hit_position
		        new_mark.Parent = Workspace.Grid
		    end
		end ,
	},
	["Eraser"] = {
		name = "Eraser",
		grip_type = "Default",
		grip_anim = "AnimName",--default_grip_animation,
		on_grab_step = function(player, hand, model, step)
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
	},
	["Skorpion"] = {
		name = "Skorpion",
		grip_type = "Custom",
		grip_anim = skorpion_grip_animation,
		on_grab_step = function(player, hand, model, step)
			if R2Down then
				if skorpion_deb == false then
					skorpion_deb = true
					print("Made it here")
					Scorpion(player, hand, model, step)
				end
			else
				skorpion_deb = false
			end
		end
	}
}


	
return InteractiveObjectMetadata