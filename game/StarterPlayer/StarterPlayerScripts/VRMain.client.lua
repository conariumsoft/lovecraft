require(game.ReplicatedStorage.Lovecraft.Lovecraft)
-- above must be required once per machine...

_G.log("Initializing VR client.")

_G.using "RBX.UserInputService"
_G.using "RBX.RunService"
_G.using "RBX.VRService"
_G.using "RBX.StarterGui"
_G.using "RBX.ReplicatedStorage"
_G.using "Lovecraft.VRHand"
_G.using "Lovecraft.VRHead"
_G.using "Game.Data.ItemMetadata"

local vr_enabled = UserInputService.VREnabled

if vr_enabled then
	StarterGui:SetCore("VRLaserPointerMode", 0)
	StarterGui:SetCore("VREnableControllerModels", false)

else
	_G.VR_DEBUG = true
	--error("This game is VR only dummy!") 
	_G.log("VR is not enabled, assuming Keyboard mode...")
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

	--bryh
	if _G.VR_DEBUG then
		-- can move each hand in 3 degrees, and rotate in 3 degrees
		local l_mv_up       = UserInputService:IsKeyDown(Enum.KeyCode.Q)
		local l_mv_down     = UserInputService:IsKeyDown(Enum.KeyCode.A)
		local l_mv_left     = UserInputService:IsKeyDown(Enum.KeyCode.W)
		local l_mv_right    = UserInputService:IsKeyDown(Enum.KeyCode.S)
		local l_mv_back     = UserInputService:IsKeyDown(Enum.KeyCode.E)
		local l_mv_forward  = UserInputService:IsKeyDown(Enum.KeyCode.D)
		local l_roll_left   = UserInputService:IsKeyDown(Enum.KeyCode.R)
		local l_roll_right  = UserInputService:IsKeyDown(Enum.KeyCode.F)
		local l_pitch_left  = UserInputService:IsKeyDown(Enum.KeyCode.Z)
		local l_pitch_right = UserInputService:IsKeyDown(Enum.KeyCode.X)
		local l_yaw_left    = UserInputService:IsKeyDown(Enum.KeyCode.C)
		local l_yaw_right   = UserInputService:IsKeyDown(Enum.KeyCode.V)

		local r_mv_up       = UserInputService:IsKeyDown(Enum.KeyCode.Y)
		local r_mv_left     = UserInputService:IsKeyDown(Enum.KeyCode.H)
		local r_mv_down     = UserInputService:IsKeyDown(Enum.KeyCode.U)
		local r_mv_right    = UserInputService:IsKeyDown(Enum.KeyCode.J)
		local r_mv_forward  = UserInputService:IsKeyDown(Enum.KeyCode.I)
		local r_mv_back     = UserInputService:IsKeyDown(Enum.KeyCode.K)
		local r_roll_left   = UserInputService:IsKeyDown(Enum.KeyCode.O)
		local r_roll_right  = UserInputService:IsKeyDown(Enum.KeyCode.L)
		local r_pitch_left  = UserInputService:IsKeyDown(Enum.KeyCode.N)
		local r_pitch_right = UserInputService:IsKeyDown(Enum.KeyCode.M)
		local r_yaw_left    = UserInputService:IsKeyDown(Enum.KeyCode.Comma)
		local r_yaw_right   = UserInputService:IsKeyDown(Enum.KeyCode.Period)

		local dt = 1/60

		local lx = (l_mv_left and dt or 0) - (l_mv_right and dt or 0)
		local ly = (l_mv_up and dt or 0) - (l_mv_down and dt or 0)
		local lz = (l_mv_forward and dt or 0) - (l_mv_back and dt or 0)
		local lp = (l_pitch_left and dt or 0) - (l_pitch_right and dt or 0)
		local lyw= (l_yaw_left and dt or 0) - (l_yaw_right and dt or 0)
		local lr = (l_roll_left and dt or 0) - (l_roll_right and dt or 0)
		
		local rx = (r_mv_left and dt or 0) - (r_mv_right and dt or 0)
		local ry = (r_mv_up and dt or 0) - (r_mv_down and dt or 0)
		local rz = (r_mv_forward and dt or 0) - (r_mv_back and dt or 0)
		local rp = (r_pitch_left and dt or 0) - (r_pitch_right and dt or 0)
		local ryw= (r_yaw_left and dt or 0) - (r_yaw_right and dt or 0)
		local rr = (r_roll_left and dt or 0) - (r_roll_right and dt or 0)

		my_left_hand.LockPart.CFrame = my_left_hand.LockPart.CFrame * CFrame.new(lx, ly, lz, lp, lyw, lr)
		my_right_hand.LockPart.CFrame = my_right_hand.LockPart.CFrame * CFrame.new(rx, ry, rz, rp, ryw, rr)
	
	end
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