require(game.ReplicatedStorage.Lovecraft.Lovecraft)
-- above must be required once per machine...

using "RBX.UserInputService"
using "RBX.RunService"
using "RBX.VRService"
using "RBX.StarterGui"
using "RBX.ReplicatedStorage"
using "Lovecraft.VRHand"
using "Lovecraft.VRHead"
using "Game.Data.InteractiveObjectMetadata"

-- initialization of local models, camera stuff, blah blah
if (UserInputService.VREnabled == false) then error("This game is VR only dummy!") end
do -- Setup core GUI bull
	StarterGui:SetCore("VRLaserPointerMode", 0)
	StarterGui:SetCore("VREnableControllerModels", false)
end

-- local object references
local local_player = game.Players.LocalPlayer
local character = local_player.CharacterAdded:Wait()

local left_hand_model = game.ReplicatedStorage.LHand
local right_hand_model = game.ReplicatedStorage.RHand

-- container for vr hand models
local local_world_folder = Instance.new("Folder") do
	local_world_folder.Name = "LocalVRModels"
	local_world_folder.Parent = game.workspace
end

-- hello??
-- TODO: replicate hands to server?
local my_camera_head = VRHead:new(local_player)
local my_left_hand = VRHand:new(local_player, my_camera_head, "Left", left_hand_model:Clone())
local my_right_hand = VRHand:new(local_player, my_camera_head, "Right", right_hand_model:Clone())

RunService.RenderStepped:Connect(function(delta)
	my_camera_head:Update(delta)
	my_left_hand:Update(delta)
	my_right_hand:Update(delta)
end)

local sensor_grip_right  = Enum.KeyCode.ButtonR1
local sensor_index_right = Enum.KeyCode.ButtonR2
local sensor_grip_left   = Enum.KeyCode.ButtonL1
local sensor_index_left  = Enum.KeyCode.ButtonL2

UserInputService.InputChanged:Connect(function(inp, _)
	
--[[
	if inp.KeyCode == Enum.KeyCode.ButtonL1 and inp.Position.Z < .95 then
        my_left_hand:Release()
    end
    if inp.KeyCode == Enum.KeyCode.ButtonR1 and inp.Position.Z < .95 then
        my_right_hand:Release()
    end
]]
	-- palm grip
	if inp.KeyCode == sensor_grip_right then 
		my_right_hand:SetGripCurl(inp.Position.Z)

		if inp.Position.Z < 0.95 then
			my_right_hand:Release()
		end
	end	
	if inp.KeyCode == sensor_grip_left then 
		my_left_hand:SetGripCurl(inp.Position.Z) 

		if inp.Position.Z < 0.95 then
			my_left_hand:Release()
		end
	end
	
	-- index 
	if inp.KeyCode == sensor_index_right then 
		my_right_hand:SetIndexFingerCurl(inp.Position.Z) 
	end
	if inp.KeyCode == sensor_index_left then 
		my_left_hand:SetIndexFingerCurl(inp.Position.Z) 
	end
end)

UserInputService.InputBegan:Connect(function(inp, _)
	if inp.KeyCode == Enum.KeyCode.ButtonL1 then
		my_left_hand:Grab()
	end
	if inp.KeyCode == Enum.KeyCode.ButtonR1 then
		my_right_hand:Grab()
	end
end)