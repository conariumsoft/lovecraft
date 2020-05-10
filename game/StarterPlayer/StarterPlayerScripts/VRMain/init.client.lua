--- Client game loop. Handles input and local rendering


require(game.ReplicatedStorage.Lovecraft.Lovecraft)
-- Lovecraft API intializer
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

-- if doing game testing, start in keyboard mode
-- when game is live, make so this will error & kick the playe
-- (at least until/if non-VR support is working)
if vr_enabled then
	StarterGui:SetCore("VRLaserPointerMode", 0)
	StarterGui:SetCore("VREnableControllerModels", false)
else
	_G.VR_DEBUG = true
	--error("This game is VR only dummy!") 
	_G.log("VR is not enabled, assuming Keyboard mode...")
end


local local_player = game.Players.LocalPlayer
local character = local_player.Character or local_player.CharacterAdded:wait()
-- explain
character:WaitForChild("Humanoid")
character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)

-- client is ready to start
-- send request for server-side init
local vr_state = Networking.GetNetHook("ClientRequestVRState")
vr_state:InvokeServer() -- remotefunction yield

--- Camera Setup
local_player.CameraMode = Enum.CameraMode.LockFirstPerson
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
Workspace.CurrentCamera.CameraSubject = nil--game.Workspace.BaseStation
Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

local left_hand_model  = character:WaitForChild("LHand")
local right_hand_model = character:WaitForChild("RHand")

local my_camera_head = VRHead:new(local_player) -- Head Physics & Camera

-- poll hapticservice for rumble support
local client_haptics_support

local my_left_hand   = VRHand:new(local_player, my_camera_head, "Left", left_hand_model)   -- Gripping
my_left_hand:Teleport(character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2))  -- Bring models to player 

local my_right_hand  = VRHand:new(local_player, my_camera_head, "Right", right_hand_model) -- 
my_right_hand:Teleport(character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2))


VRService:RecenterUserHeadCFrame()

-- CONSIDER: create VRController class?
local jstickleft  = Vector2.new(0, 0) -- vr controller joysticks
local jstickright = Vector2.new(0, 0)
local r_grip_sensor = Enum.KeyCode.ButtonR1 -- grabbing anim
local r_indx_sensor = Enum.KeyCode.ButtonR2
local l_grip_sensor = Enum.KeyCode.ButtonL1 -- middle finger anim
local l_indx_sensor = Enum.KeyCode.ButtonL2
local l_joystick_flick = false -- 90 degree rotate for chairbound players
local r_joystick_flick = false

-- will be combined with the VRHeadset CFrame to move the humanoid.
local ControllerTranslationPoint = Vector3.new(0, 0, 0)
local ControllerHorizRotation = 0

print("Client Setup Complete")


local function rig_body_to_vr_coords()

end

-- physics step
RunService.RenderStepped:Connect(function(delta)
    
end)

RunService.Stepped:Connect(function(t, delta)
	my_camera_head:Update(delta)
	my_left_hand:Update(delta)
	my_right_hand:Update(delta)
	
	--character.TorsoJ.CFrame = my_camera_head.TranslatedPosition
	--character.HeadJ.CFrame = my_camera_head.VirtualHead.CFrame
	character.HeadJ.Velocity = Vector3.new(0, 0, 0)
	character.TorsoJ.Velocity = Vector3.new(0, 0, 0)

	if _G.VR_DEBUG then
		DebugBoard.RenderStep(my_camera_head, my_left_hand, my_right_hand)
	end
end)

local function round(number, decimals)
	local power = 10^decimals
    return math.floor(number * power) / power
end

-- left joystick operation
-- controls quick-flicking (instant 90-degree rotation)
local function left_joystick_state(jstick_vec)
	local base = my_camera_head.BaseStation

	jstickleft = jstick_vec

	local accur_x = jstickleft.X
	local approx_x = round(jstickleft.X, 1)

	-- joystick is considered at rest
	if approx_x == 0 then
		-- See also DebugBoard.InputBegan
		-- must rotate left
		if r_joystick_flick then
			r_joystick_flick = false
			my_camera_head.FlickRotation = my_camera_head.FlickRotation + 90
		end
		-- must roatate right
		if l_joystick_flick then
			l_joystick_flick = false
			my_camera_head.FlickRotation = my_camera_head.FlickRotation - 90
		end
	end
	-- joystick has been moved to the right
	if accur_x > 0.8 then
		r_joystick_flick = true
	end
	-- joystick has been moved to the left
	if accur_x < -0.8 then
		l_joystick_flick = true
	end
end

-- right joystick operation
-- controls horiz movement
local function right_joystick_state(jstick_vec)
	jstickright = jstick_vec

	--- PLAY WITH MOVEMENT
	character.Humanoid:Move(Vector3.new(jstickright.X, 0, -jstickright.Y), true)
end

UserInputService.InputChanged:Connect(function(inp, _)
	if inp.UserInputType == Enum.UserInputType.Gamepad1 then
		if inp.KeyCode == Enum.KeyCode.Thumbstick2 then -- left joystick
			right_joystick_state(inp.Position)
		end
		if inp.KeyCode == Enum.KeyCode.Thumbstick1 then -- right joystick
			left_joystick_state(inp.Position)
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
		DebugBoard.InputBegan(inp, my_left_hand, my_right_hand, my_camera_head)
	end

	if inp.KeyCode == Enum.KeyCode.ButtonL1 then
		my_left_hand:Grab()
	end
	if inp.KeyCode == Enum.KeyCode.ButtonR1 then
		my_right_hand:Grab()
	end
end)