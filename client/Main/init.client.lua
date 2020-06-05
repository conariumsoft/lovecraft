--[[
	StarterPlayer/StarterPlayerScripts/Main
	Provide description of script.
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

local ui = require(script:WaitForChild("ui"))

-- debugging tools
local DEV_skipintro = true
local DEV_freecam = false
local DEV_vrkeyboard = false   -- josh's keyboard testbed
local DEV_nokinematics = false -- skip IK calculations
local DEV_lockstate = false    -- press 9 in-game to lock hand states
local DEV_override_mouse_lookspeed = 0.125 -- if using vrkeyboard, we need control with mouse...
local DEV_override_mouse = Vector2.new(0, 0)

---------------------------------------------------------------------------------
local is_vr_mode = UserInputService.VREnabled

if is_vr_mode then
	ui.DisableDefaultRobloxCrap()
else
	DEV_vrkeyboard = true
	_G.log("VR is not enabled, assuming Keyboard mode...")
end
--[[
	TODO:
	Items able to communicate data.
	At least a basic nonintrusive anticheat.
	More robust IK & fullbody IK.
	3d Math Utility Module(s) Done
	Allow the 2-point directional grip system. Done
	Attachment (support) system for guns.
	Inventory system (?)
	Gesture system? 
	VRClient class?
]]
---------------------------------------------------------------------------------
-- Local Client objects and data -- 

local freecamcf = CFrame.new(0, 60, -100)
local dead_mode = false
local camera_follow_speed = 0.8
local cl_camera = Workspace.CurrentCamera
local cl_player = game.Players.LocalPlayer
local cl_manual_rotation = 0
local cl_manual_translation = CFrame.new(0,0,0)
local cl_character = cl_player.Character or cl_player.CharacterAdded:wait()




-- idk 
if cl_camera:FindFirstChild("Blur") then
	cl_camera.Blur:Destroy()
	cl_camera.ColorCorrection:Destroy()
end

-- character dies
cl_character:WaitForChild("Humanoid").Died:Connect(function()
	dead_mode = true
	print("FUCK")

	local blur = Instance.new("BlurEffect")
		blur.Size = 15
		blur.Parent = cl_camera
	local color = Instance.new("ColorCorrectionEffect")
		color.Saturation = 1
		color.TintColor = Color3.new(1, 0.5, 0.5)
		color.Parent = cl_camera
end)

-- client is ready to start
-- send request for server-side init
local vr_state_hook = Networking.GetNetHook("ClientDeploy")
vr_state_hook:InvokeServer()

-- wanna be able to notify hands of state changes

---------------------------------------------------------------------------------
--- Camera Configuration
cl_player.CameraMode = Enum.CameraMode.LockFirstPerson
cl_camera.CameraSubject = nil
cl_camera.CameraType    = Enum.CameraType.Scriptable
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
--------------------------------------------------------------
-- BODY PARTS --
local ik = require(script.ik)
local head_model  = cl_character:WaitForChild("HeadJ")
local lhand_model = cl_character:WaitForChild("LHand")
local rhand_model = cl_character:WaitForChild("RHand")
head_model.Transparency = 1
head_model.BillboardGui.Enabled = false

-- VRHand class instances
local lhand = VRHand:new{
	Handedness = "Left",
	VREnum = Enum.UserCFrame.LeftHand,
	HapticMotorList = { Enum.VibrationMotor.LeftTrigger, Enum.VibrationMotor.LeftHand },
	Model = lhand_model
}

local rhand = VRHand:new{
	Handedness = "Right",
	VREnum = Enum.UserCFrame.RightHand,
	HapticMotorList = { Enum.VibrationMotor.RightTrigger, Enum.VibrationMotor.RightHand },
	Model = rhand_model
}

lhand:Teleport(cl_character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)) -- Bring models to player 
rhand:Teleport(cl_character.HumanoidRootPart.CFrame * CFrame.new(0, 0,  2))
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
	hand.GripState = 0.99
end
local function act_hand_drop(hand)
	hand:Release()
	hand.GripState = 0
end

-- controls
local r_grip_sensor = Enum.KeyCode.ButtonR1 -- grabbing anim
local r_indx_sensor = Enum.KeyCode.ButtonR2
local l_grip_sensor = Enum.KeyCode.ButtonL1 -- middle finger anim
local l_indx_sensor = Enum.KeyCode.ButtonL2

local flicked = false

-----------------------------------------------------------------------
-- Keyboard methods --

local function kb_key_pressed(input)

	-- vr controllers that don't pass input.Position
	-- AKA INDEX REEEEEEEEE


	
	if input.KeyCode == r_grip_sensor then act_hand_grab(rhand) end
	if input.KeyCode == l_grip_sensor then act_hand_grab(lhand) end
	if input.KeyCode == r_indx_sensor then rhand.PointerState = 1 end
	if input.KeyCode == l_indx_sensor then lhand.PointerState = 1 end
	
	-- keyboard
	if input.KeyCode == Enum.KeyCode.Zero 		then DEV_freecam = not DEV_freecam end

	if input.KeyCode == Enum.KeyCode.Nine       then act_toggle_grip_lock()  end
	if input.KeyCode == Enum.KeyCode.Space      then act_toggle_mouse_lock() end
	if input.KeyCode == Enum.KeyCode.KeypadFive then act_jump()              end
	if input.KeyCode == Enum.KeyCode.Left       then act_rotate_left()       end
	if input.KeyCode == Enum.KeyCode.Right      then act_rotate_right()      end

	if DEV_lockstate then return end -- Testing Tool : Hand Lock State

	if input.KeyCode == Enum.KeyCode.LeftShift    then act_hand_grab(lhand)   end
	if input.KeyCode == Enum.KeyCode.LeftControl  then lhand.PointerState = 1 end
	if input.KeyCode == Enum.KeyCode.RightShift   then act_hand_grab(rhand)   end
	if input.KeyCode == Enum.KeyCode.RightControl then rhand.PointerState = 1 end
end

local function kb_key_release(input)
	-- vr controllers that don't pass input.Position
	if input.KeyCode == r_grip_sensor then act_hand_drop(rhand) end
	if input.KeyCode == l_grip_sensor then act_hand_drop(lhand) end
	if input.KeyCode == r_indx_sensor then rhand.PointerState = 0 end
	if input.KeyCode == l_indx_sensor then rhand.PointerState = 0 end

	-- keyboard shit
	if input.KeyCode == Enum.KeyCode.LeftShift  then act_hand_drop(lhand) end
	if input.KeyCode == Enum.KeyCode.RightShift then act_hand_drop(rhand) end
	if input.KeyCode == Enum.KeyCode.LeftControl  then lhand.PointerState = 0 end
	if input.KeyCode == Enum.KeyCode.RightControl then rhand.PointerState = 0 end
end

local function kb_hand_controls()

	-- position hands with fake inputs
	lhand.DebugCFrame = lhand.DebugCFrame * DebugBoard.GetLeftHandDeltaCFrame()
	rhand.DebugCFrame = rhand.DebugCFrame * DebugBoard.GetRightHandDeltaCFrame()

	local movement_delta = DebugBoard.GetMovementDeltaVec2()
	cl_character.Humanoid:Move(Vector3.new(movement_delta.Y, 0, movement_delta.X), true)
end

-- whats this doing?
VRService:RecenterUserHeadCFrame()

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

local last_pos = CFrame.new(0, 0, 0)

local function dead_mode_renderstep(delta)

end

------------------------------------------------------------------------------------------------
-- RENDERSTEP --
local function on_renderstep(delta)
	if dead_mode then return end
	-- don't update camera pos if client is dead

	cl_manual_translation = CFrame.new(cl_character.HumanoidRootPart.CFrame.Position)


	local cam_cf = calculate_camera_cframe()

	if DEV_freecam then
		cl_camera.CFrame = freecamcf * 
		CFrame.Angles(0, -DEV_override_mouse.X, 0) *
		CFrame.Angles(-DEV_override_mouse.Y, 0, 0) 
	else
		cl_camera.CFrame = cl_camera.CFrame:Lerp(cam_cf, camera_follow_speed)
	end

	local headset_relative_cf = VRService:GetUserCFrame(Enum.UserCFrame.Head)

	-- set headmodel to coorrect world pos
	local head_world_cf = cam_cf * headset_relative_cf
	head_model.CFrame = head_world_cf

	-- TODO: no longer nessecary
	-- set hand goals to constrained position
	lhand.SolvedGoalCFrame = lhand.GoalCFrame
	rhand.SolvedGoalCFrame = rhand.GoalCFrame


	if not DEV_nokinematics then ik.RenderStep(head_world_cf) end

	DEV_override_mouse = DEV_override_mouse + (
		UserInputService:GetMouseDelta()
		* math.rad(DEV_override_mouse_lookspeed)
	)

	local rcf = (DEV_vrkeyboard) and rhand.DebugCFrame or rhand.RelativeCFrame
	local lcf = (DEV_vrkeyboard) and lhand.DebugCFrame or lhand.RelativeCFrame

	local lobj = lhand.HoldingObject
	local linst = lhand.ItemInstance
	local robj = rhand.HoldingObject
	local rinst = rhand.ItemInstance
	if robj and lobj then
		-- TODO: make hand-agnostic
		-- TODO: code as data so I don't have to hardcode it
		if (robj.Name == "Tec9" and lobj.Name == "Tec9Mag") or 
		   (robj.Name == "Skorpion" and lobj.Name == "SkorpionMagazine") or
		   (robj.Name == "Glock17" and lobj.Name == "GlockMag") or
		   (robj.Name == "Tec9" and lobj.Name == "Tec9" and linst ~= rinst) or 
		   (robj.Name == "Skorpion" and lobj.Name == "Skorpion" and linst ~= rinst)or
		   (robj.Name == "Glock17" and lobj.Name == "Glock17" and linst ~= rinst) then

				rhand.GoalCFrame = cam_cf * CFrame.new(rcf.Position, lcf.Position) * rhand.RecoilCorrectionCFrame
				lhand._HandModelSoftWeld:Disable()
				return
		end
	end	
	
	lhand._HandModelSoftWeld:Enable()

	lhand.GoalCFrame = cam_cf * lcf * lhand.RecoilCorrectionCFrame
	rhand.GoalCFrame = cam_cf * rcf * rhand.RecoilCorrectionCFrame
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
	cl_character.LeftLowerLeg.Velocity = Vector3.new(0, 0, 0)
	cl_character.RightLowerLeg.Velocity = Vector3.new(0, 0, 0)
	cl_character.LeftUpperLeg.Velocity = Vector3.new(0, 0, 0)
	cl_character.RightUpperLeg.Velocity = Vector3.new(0, 0, 0)
end

local function on_physicsstep(total, delta)
	stop_parts_floating_away()

	if dead_mode then return end

	if DEV_vrkeyboard then kb_hand_controls() end

	lhand:Update(delta)
	rhand:Update(delta)

	-- TODO: spine IK
	cl_character.TorsoJ.CFrame = cl_character.HeadJ.CFrame * CFrame.new(0, -2, 0)
end


---------------------------------------------------------------------------------------------
-- left joystick movement --
local function left_joystick_state(jstick_vec)
	cl_character.Humanoid:Move(Vector3.new(jstick_vec.X, 0, -jstick_vec.Y), true)
end

-- right joystick rotation --
local function right_joystick_state(jstick_vec)
	local accur_x = jstick_vec.X

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
	
	if input.UserInputType == Enum.UserInputType.MouseWheel and DEV_freecam then
		freecamcf = freecamcf:Lerp(freecamcf + (CFrame.Angles(0, -DEV_override_mouse.X, 0) *
		CFrame.Angles(-DEV_override_mouse.Y, 0, 0)).LookVector * input.Position.Z*4, 0.5)
	end

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
		rhand.GripState = input.Position.Z

		if input.Position.Z < 0.95 then
			rhand:Release()
		end
		if input.Position.Z > 0.75 then

			rhand:Grab()
		end
	end	
	if input.KeyCode == l_grip_sensor then 
		lhand.GripState = input.Position.Z

		if input.Position.Z < 0.95 then
			lhand:Release()
		end
		if input.Position.Z > 0.75 then
			lhand:Grab()
		end
	end
	
	-- index finger
	if input.KeyCode == r_indx_sensor then 
		rhand.PointerState = input.Position.Z
	end
	if input.KeyCode == l_indx_sensor then 
		lhand.PointerState = input.Position.Z
	end

	if DEV_lockstate then return end
end

local function on_input_begin(input)
	if input.KeyCode == Enum.KeyCode.ButtonA then act_jump() end
	kb_key_pressed(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick2 then -- left joystick
		right_joystick_state(input.Position)
	end
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then -- right joystick
		left_joystick_state(input.Position)
	end
end

local function on_input_end(input)
	if DEV_lockstate then return end
	kb_key_release(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick2 then -- left joystick
		right_joystick_state(input.Position)
	end
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then -- right joystick
		left_joystick_state(input.Position)
	end
end

------------------------------------------------------------------------
local GunshotEffect = require(game.ReplicatedStorage.Data.GunshotEffect)

Networking.GetNetHook("ClientShoot").OnClientEvent:Connect(function(player, gun)
	if player ~= cl_player then
		GunshotEffect(gun)
	end
end)

Networking.GetNetHook("ReplicateEntityState").OnClientEvent:Connect(function(player, gun)



end)
-----------------------
RunService.RenderStepped:Connect(        on_renderstep   )
RunService.Stepped:Connect(              on_physicsstep  )
UserInputService.InputChanged:Connect(   on_input_changed)
UserInputService.InputEnded:Connect(     on_input_end    )
UserInputService.InputBegan:Connect(     on_input_begin  )
-----------------------
_G.log("VRClient Setup Complete")