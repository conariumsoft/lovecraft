local SINGLEPLAYER_MODE = false

print("Lovecraft Client init.")

local UserInputService  = game:GetService("UserInputService")
local RunService 	    = game:GetService("RunService")
local VRService	 	    = game:GetService("VRService")
local StarterGui	    = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace			= game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VRHand        = require(script.VRHand)
local DebugBoard    = require(script.DebugBoard)
local UserInterface = require(script.UserInterface)
local ItemMetadata  = require(ReplicatedStorage.Data.ItemMetadata)

local Networking  = ReplicatedStorage.Networking

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
	UserInterface.DisableDefaultRobloxCrap()
else
	DEV_vrkeyboard = true
	print("VR is not enabled, assuming Keyboard mode...")
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
local vr_state_hook = Networking.Deploy
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
local ik 			= require(script.LocalIK)
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

local handstate = "normal"
local primaryhand = rhand

local function tablecontains(t, val)

	for i, v in pairs(t) do
		if v == val then
			return true
		end
	end
	return false
end

local function tablesmatch(t1, t2)
	if #t1 ~= #t2 then return false end
	for i, v in pairs(t1) do
		if tablecontains(t2, v) == false then
			return false
		end
	end
	return true
end

local function getcontext(metadata, context)
	for criteria, searched in pairs(metadata.grip_contexts) do
		if tablesmatch(criteria, context) then
			return searched
		end
	end
end

local function hand_grab_contextcheck(hand)
	local otherhand = (hand == rhand) and lhand or rhand
	local obj = hand:GetClosestInteractive()
	if not obj then return true end
	local item = obj.Parent
	local obj_meta = ItemMetadata[item.Name]
	if not obj_meta then return true end
	if obj_meta.primary_grip and obj_meta.primary_grip == obj.Name then
		primaryhand = hand
	end
	if obj_meta.contextual_grips ~= true then return true end
	if otherhand.HoldingObject == nil then
		local context = getcontext(obj_meta, {})

		if not context then return true end
		if context.allows then
			if tablecontains(context.allows, obj.Name) then
				return true
			end
		end
		return false
	end

	local context = getcontext(obj_meta, {otherhand.GripPoint.Name})
	if not context then return true end
	if not context.allows then return false end
	if tablecontains(context.allows, obj.Name) then
		for t2, val2 in pairs(obj_meta.grip_contexts) do
			if tablesmatch({otherhand.GripPoint.Name, obj.Name}, t2) then
				return true, val2.stance
			end
		end
		return true
	end
end

local function act_hand_grab(hand)
	local pass, stance = hand_grab_contextcheck(hand)

	if pass then
		if stance then
			handstate = stance
		end
		hand:Grab()
	end
	hand.GripState = 0.99
end

local function hand_release(hand)
	hand.Grabbing = false
	if not hand.HoldingObject then return end
	delay(0.5, function() hand._CollisionMask:Destroy() end) -- delay a bit so physics dont spaz
	if hand.ItemInstance then
		hand.ItemInstance:OnRelease(hand, hand.GripPoint)
		hand.ItemInstance = nil
	end
	if hand._GrabbedObjectWeld then
		hand._GrabbedObjectWeld:Destroy()
		hand._GrabbedObjectWeld = nil
	end
	local crelease = Networking.ClientRelease
	crelease:FireServer(hand.HoldingObject, hand.GripPoint, hand.Handedness)
	hand.HoldingObject = nil
	hand.GripPoint = nil


	handstate = nil
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
	print("Hand Locking "..(DEV_lockstate and "On" or "Off"))
end

local function act_jump()
	cl_character.Humanoid.Jump = true
end


local function act_hand_drop(hand)
	hand_release(hand)
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

	if input.KeyCode == r_grip_sensor then act_hand_grab(rhand)end
	if input.KeyCode == l_grip_sensor then act_hand_grab(lhand)end
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

	if input.KeyCode == Enum.KeyCode.LeftShift    then act_hand_grab(lhand) end
	if input.KeyCode == Enum.KeyCode.LeftControl  then lhand.PointerState = 1 end
	if input.KeyCode == Enum.KeyCode.RightShift   then act_hand_grab(rhand) end
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

	if handstate == "PrimaryPointsToSecondary" then

		-- TODO: investigate CFrame.fromMatrix for rotation
		local secondary = (primaryhand == lhand) and rhand or lhand

		local pcf = (DEV_vrkeyboard) and primaryhand.DebugCFrame or primaryhand.RelativeCFrame
		local scf = (DEV_vrkeyboard) and secondary.DebugCFrame or secondary.RelativeCFrame

		primaryhand.GoalCFrame = cam_cf * CFrame.new(pcf.Position, scf.Position) * primaryhand.RecoilCorrectionCFrame
		secondary._HandModelSoftWeld:Disable()
		primaryhand._HandModelSoftWeld:Enable()
	else	
		lhand._HandModelSoftWeld:Enable()
		rhand._HandModelSoftWeld:Enable()
		lhand.GoalCFrame = cam_cf * lcf * lhand.RecoilCorrectionCFrame
		rhand.GoalCFrame = cam_cf * rcf * rhand.RecoilCorrectionCFrame
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
			hand_release(rhand)
		end
		if input.Position.Z > 0.75 then
			act_hand_grab(rhand)
		end
	end	
	if input.KeyCode == l_grip_sensor then 
		lhand.GripState = input.Position.Z

		if input.Position.Z < 0.95 then
			hand_release(lhand)
		end
		if input.Position.Z > 0.75 then
			act_hand_grab(lhand)
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
local GunshotEffect = require(game.ReplicatedStorage.Common.GunshotEffect)

Networking.ClientShoot.OnClientEvent:Connect(function(player, gun)
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
print("VRClient Setup Complete")