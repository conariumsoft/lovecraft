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
_G.using "Lovecraft.DebugBoard"
_G.using "Lovecraft.Networking"

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

local local_player = game.Players.LocalPlayer
local character = local_player.CharacterAdded:Wait()
local vr_state = Networking.GetNetHook("ClientRequestVRState")
vr_state:InvokeServer()
local left_hand_model  = character:WaitForChild("LHand")
local right_hand_model = character:WaitForChild("RHand")
local my_camera_head = VRHead:new(local_player)
local my_left_hand   = VRHand:new(local_player, my_camera_head, "Left", left_hand_model)
local my_right_hand  = VRHand:new(local_player, my_camera_head, "Right", right_hand_model)
local joystick_left  = Vector2.new(0, 0)
local joystick_right = Vector2.new(0, 0)
local r_grip_sensor = Enum.KeyCode.ButtonR1
local r_indx_sensor = Enum.KeyCode.ButtonR2
local l_grip_sensor = Enum.KeyCode.ButtonL1
local l_indx_sensor = Enum.KeyCode.ButtonL2
local l_joystick_flick = false
local r_joystick_flick = false

local_player.CameraMode = Enum.CameraMode.LockFirstPerson
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
Workspace.CurrentCamera.CameraSubject = nil
Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

if _G.VR_DEBUG then
	DebugBoard.CorrectHandPositions(my_left_hand, my_right_hand)
end

RunService.RenderStepped:Connect(function(delta)
	my_camera_head:Update(delta)
	my_left_hand:Update(delta)
	my_right_hand:Update(delta)

	my_camera_head.BaseStation.CFrame = my_camera_head.BaseStation.CFrame * CFrame.new(joystick_left.X, 0, joystick_left.Y)

	if _G.VR_DEBUG then
		DebugBoard.RenderStep(my_camera_head, my_left_hand, my_right_hand)
	end
end)


UserInputService.InputChanged:Connect(function(inp, _)
	if inp.UserInputType == Enum.UserInputType.Gamepad1 then
		if inp.KeyCode == Enum.KeyCode.Thumbstick1 then -- left joystick
			-- TODO: implement body of some sort
			joystick_left = inp.Position
		end
		if inp.KeyCode == Enum.KeyCode.Thumbstick2 then -- right joystick
			joystick_right = inp.Position
			if math.floor(joystick_right.X*10)/10 == 0 then -- rounding trick. if between -0.1 and 0.1...
				local base = my_camera_head.BaseStation
				if l_joystick_flick then
					l_joystick_flick = false
					base.CFrame = base.CFrame * CFrame.Angles(0, -math.rad(90), 0)
				end
				if r_joystick_flick then
					r_joystick_flick = false
					base.CFrame = base.CFrame * CFrame.Angles(0, math.rad(90), 0)
				end
			end
			if joystick_right.X > 0.9 then r_joystick_flick = true end
			if joystick_right.X < -0.9 then l_joystick_flick = true end
		end
	end

	-- palm grip
	if inp.KeyCode == r_grip_sensor then 
		my_right_hand:SetGripCurl(inp.Position.Z)

		if inp.Position.Z < 0.95 then
			my_right_hand:Release()
		end
	end	
	if inp.KeyCode == l_grip_sensor then 
		my_left_hand:SetGripCurl(inp.Position.Z) 

		if inp.Position.Z < 0.95 then
			my_left_hand:Release()
		end
	end
	
	-- index 
	if inp.KeyCode == r_indx_sensor then 
		my_right_hand:SetIndexFingerCurl(inp.Position.Z) 
	end
	if inp.KeyCode == l_indx_sensor then 
		my_left_hand:SetIndexFingerCurl(inp.Position.Z) 
	end

	
end)

UserInputService.InputEnded:Connect(function(inp, _)
	if _G.VR_DEBUG then
		DebugBoard.InputEnded(inp, my_left_hand, my_right_hand)
	end
end)

UserInputService.InputBegan:Connect(function(inp, _)

	if _G.VR_DEBUG then
		DebugBoard.InputBegan(inp, my_left_hand, my_right_hand)
	end

	if inp.KeyCode == Enum.KeyCode.ButtonL1 then
		my_left_hand:Grab()
	end
	if inp.KeyCode == Enum.KeyCode.ButtonR1 then
		my_right_hand:Grab()
	end
end)