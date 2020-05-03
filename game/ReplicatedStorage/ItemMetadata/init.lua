_G.using "RBX.UserInputService"
_G.using "RBX.Workspace"
_G.using "RBX.Debris"

local Skorpion = require(script.Skorpion)

local marker_grip_animation
local skorpion_grip_animation
local default_grip_animation = ...
local R2Down = false
--?
--[[UserInputService.InputBegan:Connect(function(inp,gpe)
	if inp.KeyCode == Enum.KeyCode.ButtonR2 and not gpe then
		R2Down = true
	end
end)
UserInputService.InputEnded:Connect(function(inp,gpe)
	if inp.KeyCode == Enum.KeyCode.ButtonR2 and not gpe then
		R2Down = false
	end
end)]]
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
		grip_type = "GripPoint",
		grip_data = {
			MarkerBase = {
				animation = marker_grip_animation,
				offset = CFrame.new(0,0,0) * CFrame.Angles(0,0,0),
			}
		}
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
			Handle = {
				offset = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0),
				animation = skorpion_grip_animation,
			},
			Magazine = {
				offset = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0),
				not_rigid = true,
				
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