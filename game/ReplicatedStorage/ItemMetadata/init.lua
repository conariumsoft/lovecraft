_G.using "RBX.UserInputService"
_G.using "RBX.Workspace"
_G.using "RBX.Debris"

local Skorpion = require(script.Skorpion)

local marker_grip_animation
local skorpion_grip_animation
local default_grip_animation = ...
local R2Down = false
--?
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
		local muzzle_flip = Instance.new("BodyVelocity") do
			muzzle_flip.Velocity = scorpion.rifling.CFrame.UpVector*20
			muzzle_flip.Parent = scorpion.rifling
			Debris:AddItem(muzzle_flip, 1/20)
		end
		--newVelocityModifier:Destroy()
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
local ItemMetadata = {
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
		    local part, hit_position = game.Workspace:FindPartOnRayWithWhitelist(ray,{Workspace.Whiteboard})
	
		    if (part and part.Name == "Whiteboard") then
		        local new_mark = CreateGridMark(model.Tip.Color)
		        new_mark.Position = hit_position
		        new_mark.Parent = Workspace.Grid
		    end
		end ,
	},
	["Eraser"] = {
		name = "Eraser",
		grip_type = "Default", --"Anywhere", "GripPoint", "PrimaryGripPoint"
		grip_anim = "AnimName", 
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
		grip_type = "GripPoint",
		grip_data = {
			Handle = {
				animation = skorpion_grip_animation,
				offset = CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, 0),
				--has_weight = false,
			}
		},
		class = Skorpion,
	}
}


	
return ItemMetadata