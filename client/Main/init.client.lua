--[[
	StarterPlayer/StarterPlayerScripts/Main
	Client game loop.
	Local UI
	Kinematics
	Input
	Profiling
]]--
require(game.ReplicatedStorage.Lovecraft.Lovecraft)

-- Initialize Lovecraft API
-- Grab nessecary components
_G.log("Initializing VR client.")
_G.using "RBX.UserInputService"
_G.using "RBX.RunService"
_G.using "RBX.VRService"
_G.using "RBX.StarterGui"
_G.using "RBX.ReplicatedStorage"
_G.using "Lovecraft.VRHand"
_G.using "Lovecraft.DebugBoard"
_G.using "Lovecraft.Networking"
_G.using "Lovecraft.Kinematics"
_G.using "Game.Data.ItemMetadata"

_G.log("Got all Usings 2")

local ui = require(script.ui)

-- debugging tools
local DEV_skipintro = true
local DEV_vrkeyboard = false   -- josh's keyboard testbed
local DEV_nokinematics = false -- skip IK calculations
local DEV_lockstate = false    -- press 9 in-game to lock hand states
local DEV_override_mouse_lookspeed = 0.125 -- if using vrkeyboard, we need control with mouse...
local DEV_override_mouse = Vector2.new(0, 0)

-- TODO: various hardware support
local headset_list = {
	"WindowsMixedReality",
	"ValveIndex",
	"OculusRift",
	"Vive"
}

---------------------------------------------------------------------------------
local is_vr_mode = UserInputService.VREnabled

-- later on: make non-vr players go into spectator mode for deathmatch
-- if doing game testing, start in keyboard mode
-- when game is live, make so this will error & kick the playe
-- (at least until/if non-VR support is working)
if is_vr_mode then
	ui.DisableDefaultRobloxCrap()
else
	DEV_vrkeyboard = true
	_G.log("VR is not enabled, assuming Keyboard mode...")
end
---------------------------------------------------------------------------------
-- Local Client objects and data -- 
local camera_follow_speed = 0.8
local cl_camera = Workspace.CurrentCamera
local cl_player = game.Players.LocalPlayer
local cl_manual_rotation = 0
local cl_manual_translation = CFrame.new(0,0,0)

local cl_character = cl_player.Character or cl_player.CharacterAdded:wait()

-- client is ready to start
-- send request for server-side init
local vr_state_hook = Networking.GetNetHook("ClientRequestVRState")
vr_state_hook:InvokeServer()

---------------------------------------------------------------------------------
--- Camera Configuration
cl_player.CameraMode = Enum.CameraMode.LockFirstPerson
cl_camera.CameraSubject = nil
cl_camera.CameraType    = Enum.CameraType.Scriptable
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
--------------------------------------------------------------
-- BODY PARTS --
local ch_leftupper  = cl_character.LeftUpperArm
local ch_leftlower  = cl_character.LeftLowerArm
local ch_rightlower = cl_character.RightLowerArm
local ch_rightupper = cl_character.RightUpperArm
local head_model 	   = cl_character:WaitForChild("HeadJ")
local lhand_model  = cl_character:WaitForChild("LHand")
local rhand_model = cl_character:WaitForChild("RHand")
head_model.Transparency = 1
head_model.BillboardGui.Enabled = false

-- VRHand class instances
local lhand = VRHand:new{
	Handedness = "Left",
	VREnum = Enum.UserCFrame.LeftHand,
	HapticMotorList = { Enum.VibrationMotor.LeftTrigger, Enum.VibrationMotor.LeftHand },
	Model = lhand_model,
}

local rhand = VRHand:new{
	Handedness = "Right",
	VREnum = Enum.UserCFrame.RightHand,
	HapticMotorList = { Enum.VibrationMotor.RightTrigger, Enum.VibrationMotor.RightHand },
	Model = rhand_model
}

lhand:Teleport(cl_character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)) -- Bring models to player 
rhand:Teleport(cl_character.HumanoidRootPart.CFrame * CFrame.new(0, 0,  2))

----------------------------------------------------------------------------------------
-- ? BODY KINEMATICS DATA --
local ik_upper_arm_bone_len = 1
local ik_lower_arm_bone_len = 1
local ik_shoulder_width = 1.2
local ik_shoulder_height = 0.7

local ik_leftarm_chain = Kinematics.Chain:new({
	Kinematics.Joint:new(nil, 1),
	Kinematics.Joint:new(nil, ik_lower_arm_bone_len),
	Kinematics.Joint:new(nil, ik_upper_arm_bone_len),
})

local ik_rightarm_chain = Kinematics.Chain:new({
	Kinematics.Joint:new(nil, 1),
	Kinematics.Joint:new(nil, ik_lower_arm_bone_len),
	Kinematics.Joint:new(nil, ik_upper_arm_bone_len),
})

local function line_to_cframe(vec1, vec2)
	local v = (vec2-vec1)
	return CFrame.new(vec1 + (v/2), vec2)
end

local function solve_chain(chain, origin, goal)
	chain.origin = origin
	chain.target = goal
	chain.joints[1].vec = chain.origin.p
	Kinematics.Solver.Solve(chain)
end

local function kinematics(base_cf)
	-- we are solving backwards. from hand to shoulder

	solve_chain(
		ik_leftarm_chain, -- joints
		lhand.HandModel.PrimaryPart.CFrame * CFrame.new(0, 0, 0.6), -- origin 
		(base_cf * CFrame.new(-ik_shoulder_width, -ik_shoulder_height, 0)).Position -- goal
	)

	solve_chain(
		ik_rightarm_chain,
		rhand.HandModel.PrimaryPart.CFrame * CFrame.new(0, 0, 0.6),
		(base_cf * CFrame.new(ik_shoulder_width,  -ik_shoulder_height, 0)).Position
	)

	-- set hand goals to constrained position
	lhand.SolvedGoalCFrame = lhand.GoalCFrame
	rhand.SolvedGoalCFrame = rhand.GoalCFrame
	

	-- BODY PARTS --
	-- TODO: once body is fully connected, this'll change
	ch_leftupper.CFrame = line_to_cframe(ik_leftarm_chain.joints[3].vec, ik_leftarm_chain.joints[2].vec) * CFrame.Angles(math.rad(90), 0, 0)
	ch_leftlower.CFrame = line_to_cframe(ik_leftarm_chain.joints[2].vec, ik_leftarm_chain.joints[1].vec) * CFrame.Angles(math.rad(90), 0, 0)
	ch_rightupper.CFrame = line_to_cframe(ik_rightarm_chain.joints[3].vec, ik_rightarm_chain.joints[2].vec) * CFrame.Angles(math.rad(90), 0, 0)
	ch_rightlower.CFrame = line_to_cframe(ik_rightarm_chain.joints[2].vec, ik_rightarm_chain.joints[1].vec) * CFrame.Angles(math.rad(90), 0, 0)
end
-----------------------------------------------------------
-- Input Actions --
-- Define Actions that can be invoked in various ways

local function act_rotate_left()
	cl_manual_rotation = cl_manual_rotation - 45
end
local function act_rotate_right()
	cl_manual_rotation = cl_manual_rotation + 45
end

local function act_toggle_mouse_lock()
	UserInputService.MouseBehavior = (UserInputService.MouseBehavior == Enum.MouseBehavior.Default) and
		Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
end

local function act_toggle_grip_lock()
	DEV_lockstate = not DEV_lockstate
	_G.log("Hand Locking "..(DEV_lockstate and "On" or "Off"))
end

local function act_jump()
	cl_character.Humanoid.Jump = true
end

local function act_hand_grab(hand)
	hand:Grab()
	hand:SetGripStrength(1)
end
local function act_hand_release(hand)
	hand:Release()
	hand:SetGripStrength(0)
end
-----------------------------------------------------------------------
-- Keyboard methods --

local function kb_key_pressed(input)

	if input.KeyCode == Enum.KeyCode.Nine       then act_toggle_grip_lock()  end
	if input.KeyCode == Enum.KeyCode.Space      then act_toggle_mouse_lock() end
	if input.KeyCode == Enum.KeyCode.KeypadFive then act_jump()              end
	if input.KeyCode == Enum.KeyCode.Left       then act_rotate_left()       end
	if input.KeyCode == Enum.KeyCode.Right      then act_rotate_right()      end

	if DEV_lockstate then return end -- Testing Tool : Hand Lock State

	if input.KeyCode == Enum.KeyCode.LeftShift    then act_hand_grab(lhand)         end
	if input.KeyCode == Enum.KeyCode.LeftControl  then lhand:SetIndexFingerCurl(1)  end
	if input.KeyCode == Enum.KeyCode.RightShift   then act_hand_grab(rhand)         end
	if input.KeyCode == Enum.KeyCode.RightControl then rhand:SetIndexFingerCurl(1)  end
end

local function kb_key_release(input)
	if input.KeyCode == Enum.KeyCode.LeftShift  then act_hand_release(lhand) end
	if input.KeyCode == Enum.KeyCode.RightShift then act_hand_release(rhand) end
	if input.KeyCode == Enum.KeyCode.LeftControl  then lhand:SetIndexFingerCurl(0) end
	if input.KeyCode == Enum.KeyCode.RightControl then rhand:SetIndexFingerCurl(0) end
end

local function kb_hand_controls()

	-- position hands with fake inputs
	lhand.DebugCFrame = lhand.DebugCFrame * 
		DebugBoard.GetLeftHandDeltaCFrame()

	rhand.DebugCFrame = rhand.DebugCFrame *
		DebugBoard.GetRightHandDeltaCFrame()

	local movement_delta = DebugBoard.GetMovementDeltaVec2()
	cl_character.Humanoid:Move(Vector3.new(movement_delta.Y, 0, movement_delta.X), true)
end

---------------------------------------------------------------------------------

VRService:RecenterUserHeadCFrame()

-- CONSIDER: create VRController class?
local jstickleft  = Vector2.new(0, 0) -- vr controller joysticks
local jstickright = Vector2.new(0, 0)
local r_grip_sensor = Enum.KeyCode.ButtonR1 -- grabbing anim
local r_indx_sensor = Enum.KeyCode.ButtonR2
local l_grip_sensor = Enum.KeyCode.ButtonL1 -- middle finger anim
local l_indx_sensor = Enum.KeyCode.ButtonL2
local flicked = false


------------------------------------------------------------------------------------------------
-- HEADS-UP-DISPLAY --
local hud = ReplicatedStorage.HUD:Clone()
hud.Parent = game.Workspace
------------------------------------------------------------------------------------------------
local function calculate_camera_cframe()
	if DEV_vrkeyboard then
		return cl_manual_translation *
			CFrame.Angles(0, math.rad(cl_manual_rotation), 0) *
			CFrame.Angles(0, -DEV_override_mouse.X, 0) *
			CFrame.Angles(-DEV_override_mouse.Y, 0, 0)
	else
		return cl_manual_translation *
			CFrame.Angles(0, math.rad(cl_manual_rotation), 0)
	end
end

------------------------------------------------------------------------------------------------
-- RENDERSTEP --
local function on_renderstep(delta)

	cl_manual_translation = CFrame.new(cl_character.HumanoidRootPart.CFrame.Position)

	local cam_cf = calculate_camera_cframe()

	cl_camera.CFrame = cl_camera.CFrame:Lerp(cam_cf, camera_follow_speed)

	local headset_relative_cf = VRService:GetUserCFrame(Enum.UserCFrame.Head)

	-- set headmodel to coorrect world pos
	local head_world_cf = cam_cf * headset_relative_cf
	head_model.CFrame = head_world_cf

	if not DEV_nokinematics then
		kinematics(head_world_cf)
	end

	if DEV_vrkeyboard then

		-- TODO: hands not exactly lining up in VR mode
		lhand.GoalCFrame  = cam_cf * lhand.RelativeCFrame *  lhand.RecoilCorrectionCFrame * lhand.DebugCFrame
		rhand.GoalCFrame = cam_cf * rhand.RelativeCFrame * rhand.RecoilCorrectionCFrame * rhand.DebugCFrame

		DEV_override_mouse = DEV_override_mouse + (
			UserInputService:GetMouseDelta()
			* math.rad(DEV_override_mouse_lookspeed)
		)
	else
		lhand.GoalCFrame  = cam_cf * lhand.RelativeCFrame * lhand.RecoilCorrectionCFrame
		rhand.GoalCFrame = cam_cf * rhand.RelativeCFrame  *  rhand.RecoilCorrectionCFrame
	end
end

local function stop_parts_floating_away()
	-- even if we have networkownership, physics will still force parts down
	-- this will negate that
	cl_character.HeadJ.Velocity         = Vector3.new(0, 0, 0)
	cl_character.TorsoJ.Velocity        = Vector3.new(0, 0, 0)
	cl_character.LeftLowerArm.Velocity  = Vector3.new(0, 0, 0)
	cl_character.LeftUpperArm.Velocity  = Vector3.new(0, 0, 0)
	cl_character.RightLowerArm.Velocity = Vector3.new(0, 0, 0)
	cl_character.RightUpperArm.Velocity = Vector3.new(0, 0, 0)
end

local function on_physicsstep(total, delta)
	if DEV_vrkeyboard then kb_hand_controls() end

	lhand:Update(delta)
	rhand:Update(delta)

	cl_character.TorsoJ.CFrame = cl_character.HeadJ.CFrame * CFrame.new(0, -2, 0)

	stop_parts_floating_away()
end


---------------------------------------------------------------------------------------------
-- left joystick movement --
local function left_joystick_state(jstick_vec)
	jstickright = jstick_vec

	--- PLAY WITH MOVEMENT
	cl_character.Humanoid:Move(Vector3.new(jstickright.X, 0, -jstickright.Y), true)
end

-- right joystick rotation --
local function right_joystick_state(jstick_vec)
	jstickleft = jstick_vec

	local accur_x = jstickleft.X

	if accur_x > 0.8 and flicked == false then
		act_rotate_right()
		flicked = true
	end
	
	if accur_x < -0.8 and flicked == false then
		act_rotate_left()
		flicked = true
	end

	-- joystick is considered at rest
	if accur_x <= 0.4 and accur_x >= -0.4 then
		flicked = false
	end
end

-------------------------------------------------------

local function on_input_changed(input)
	
	-- Joystick flicking
	if input.UserInputType == Enum.UserInputType.Gamepad1 then
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then -- left joystick
			right_joystick_state(input.Position)
		end
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then -- right joystick
			left_joystick_state(input.Position)
		end
	end

	-- palm grip
	if input.KeyCode == r_grip_sensor then 
		rhand:SetGripStrength(input.Position.Z)

		if input.Position.Z < 0.95 then
			rhand:Release()
		end
		if input.Position.Z > 0.75 then

			rhand:Grab()
		end
	end	
	if input.KeyCode == l_grip_sensor then 
		lhand:SetGripStrength(input.Position.Z) 

		if input.Position.Z < 0.95 then
			lhand:Release()
		end
		if input.Position.Z > 0.75 then
			lhand:Grab()
		end
	end
	
	-- index finger
	if input.KeyCode == r_indx_sensor then 
		rhand:SetIndexFingerCurl(input.Position.Z) 
	end
	if input.KeyCode == l_indx_sensor then 
		lhand:SetIndexFingerCurl(input.Position.Z) 
	end

	if DEV_lockstate then return end
end

local function on_input_begin(input)
	kb_key_pressed(input)
end

local function on_input_end(input)
	if DEV_lockstate then return end
	kb_key_release(input)
end


------------------------------------------------------------------------
local GunshotEffect = require(game.ReplicatedStorage.Data.GunshotEffect)

local client_gunshot = Networking.GetNetHook("ClientShoot")
client_gunshot.OnClientEvent:Connect(function(player, gun)
	if player ~= cl_player then
		GunshotEffect(gun)
	end
end)
-----------------------
RunService.RenderStepped:Connect(        on_renderstep   )
RunService.Stepped:Connect(              on_physicsstep  )
UserInputService.InputChanged:Connect(   on_input_changed)
UserInputService.InputEnded:Connect(     on_input_end    )
UserInputService.InputBegan:Connect(     on_input_begin  )
-----------------------
_G.log("VRClient Setup Complete")