--[[
	StarterPlayer/StarterPlayerScripts/Main
	Client game loop. Handles input and local rendering
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

require(script.highlighter)

local hardware = "oculus"

local no_button_scale = true

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
local camera_follow_speed = 0.9
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
local left_hand_model  = cl_character:WaitForChild("LHand")
local right_hand_model = cl_character:WaitForChild("RHand")
head_model.Transparency = 1
head_model.BillboardGui.Enabled = false

-- VRHand class instances
-- TODO: detect avalible haptic motors
local left_hand = VRHand:new{
	Handedness = "Left",
	VREnum = Enum.UserCFrame.LeftHand,
	HapticMotorList = {
		Enum.VibrationMotor.LeftTrigger, Enum.VibrationMotor.LeftHand
	},
	Model = left_hand_model,
}

local right_hand = VRHand:new{
	Handedness = "Right",
	VREnum = Enum.UserCFrame.RightHand,
	HapticMotorList = {
		Enum.VibrationMotor.RightTrigger, Enum.VibrationMotor.RightHand
	},
	Model = right_hand_model
}

left_hand:Teleport( cl_character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)) -- Bring models to player 
right_hand:Teleport(cl_character.HumanoidRootPart.CFrame * CFrame.new(0, 0,  2))

----------------------------------------------------------------------------------------
-- ? BODY KINEMATICS DATA --
local ik_upper_arm_bone_len = 1
local ik_lower_arm_bone_len = 1
local ik_shoulder_width = 1.2
local ik_shoulder_height = 0.7

local ik_leftarm_chain = Kinematics.Chain:new({
	Kinematics.Joint:new(nil, ik_upper_arm_bone_len),
	Kinematics.Joint:new(nil, ik_lower_arm_bone_len),
	Kinematics.Joint:new(nil, 1)
})

local ik_rightarm_chain = Kinematics.Chain:new({
	Kinematics.Joint:new(nil, ik_upper_arm_bone_len),
	Kinematics.Joint:new(nil, ik_lower_arm_bone_len),
	Kinematics.Joint:new(nil, 1)
})

local function line_to_cframe(vec1, vec2)
	local v = (vec2-vec1)
	return CFrame.new(vec1 + (v/2), vec2)
end

local function kinematics(base_cf)
	-- pass in reported VR hand position

	-- ! hand goal base should most likely be head cframe.
	local lefthand_goal_cf  = left_hand.GoalCFrame--base_cf * left_hand:GetRelativeCFrame()
	local righthand_goal_cf = right_hand.GoalCFrame--base_cf * right_hand:GetRelativeCFrame()

	ik_leftarm_chain.origin   = base_cf * CFrame.new(-ik_shoulder_width, -ik_shoulder_height, 0)
	ik_rightarm_chain.origin  = base_cf * CFrame.new(ik_shoulder_width,  -ik_shoulder_height, 0)

	ik_leftarm_chain.target  = (lefthand_goal_cf  * CFrame.new(0, 0, 0.5)).Position
	ik_rightarm_chain.target = (righthand_goal_cf * CFrame.new(0, 0, 0.5)).Position

	-- this many not be nessecary?
	ik_leftarm_chain.joints[1].vec  = ik_leftarm_chain.origin.p
	ik_rightarm_chain.joints[1].vec = ik_rightarm_chain.origin.p

	Kinematics.Solver.Solve(ik_leftarm_chain)
	Kinematics.Solver.Solve(ik_rightarm_chain)
	-- pull solved position back out.
	local lhand_constrained_goal = (
        CFrame.new(ik_leftarm_chain.joints[3].vec) *
        CFrame.Angles(lefthand_goal_cf:ToEulerAnglesXYZ())
        * CFrame.new(0, 0.1, -0.5)
	)
	
	local rhand_constrained_goal = (
        CFrame.new(ik_rightarm_chain.joints[3].vec) *
        CFrame.Angles(righthand_goal_cf:ToEulerAnglesXYZ()) 
        * CFrame.new(0, 0.1, -0.5)
    ) 

	-- set hand goals to constrained position
	left_hand.SolvedGoalCFrame = lhand_constrained_goal
	right_hand.SolvedGoalCFrame = rhand_constrained_goal

	-- BODY PARTS --
	-- TODO: once body is fully connected, this'll change
	ch_leftupper.CFrame = line_to_cframe(ik_leftarm_chain.joints[1].vec, ik_leftarm_chain.joints[2].vec) * CFrame.Angles(math.rad(90), 0, 0)
	ch_leftlower.CFrame = line_to_cframe(ik_leftarm_chain.joints[2].vec, ik_leftarm_chain.joints[3].vec) * CFrame.Angles(math.rad(90), 0, 0)
	ch_rightupper.CFrame = line_to_cframe(ik_rightarm_chain.joints[1].vec, ik_rightarm_chain.joints[2].vec) * CFrame.Angles(math.rad(90), 0, 0)
	ch_rightlower.CFrame = line_to_cframe(ik_rightarm_chain.joints[2].vec, ik_rightarm_chain.joints[3].vec) * CFrame.Angles(math.rad(90), 0, 0)

end
------------------------

VRService:RecenterUserHeadCFrame()

-- CONSIDER: create VRController class?
local jstickleft  = Vector2.new(0, 0) -- vr controller joysticks
local jstickright = Vector2.new(0, 0)
local r_grip_sensor = Enum.KeyCode.ButtonR1 -- grabbing anim
local r_indx_sensor = Enum.KeyCode.ButtonR2
local l_grip_sensor = Enum.KeyCode.ButtonL1 -- middle finger anim
local l_indx_sensor = Enum.KeyCode.ButtonL2
local flicked = false

-- will be combined with the VRHeadset CFrame to move the humanoid.

------------------------------------------------------------------------------------------------
-- PROFILING --
local prof_renderframes  = 0
local prof_rendertime    = 0

local function profile(delta)
	prof_renderframes = prof_renderframes + 1
	prof_rendertime = prof_rendertime + delta
end

------------------------------------------------------------------------------------------------
-- HEADS-UP-DISPLAY --
local hud = ReplicatedStorage.HUD:Clone()
hud.Parent = game.Workspace
------------------------------------------------------------------------------------------------
-- SPHERE HIGHLIGHT --
-- Add a visual indicator to manipulatable objects that are close to hands.
local highlight_left = Instance.new("Part") do
	highlight_left.Size = Vector3.new(0.5, 0.5, 0.5)
	highlight_left.Shape = Enum.PartType.Ball
	highlight_left.Parent = Workspace
	highlight_left.Anchored = true
	highlight_left.CanCollide = false
	highlight_left.Color = Color3.new(1, 1, 1)
	highlight_left.Transparency = 0.5
end

local highlight_right = highlight_left:Clone() do
	highlight_right.Parent = Workspace
end

local function run_grabbable_highlight(hand, hl)
	for _, part in pairs(Workspace.physics:GetDescendants()) do
		if part:FindFirstChild("GripPoint") then

			local dist = (part.Position - hand.HandModel.PrimaryPart.Position).magnitude

			if dist < 1 then
				hl.CFrame = CFrame.new(part.Position)
			else
				hl.CFrame = CFrame.new(0, 9999999, 0)
			end
		end
	end
end
-----------------------------------------------------------------------
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
	profile(delta)

	run_grabbable_highlight(left_hand, highlight_left)
	run_grabbable_highlight(right_hand, highlight_right)

	cl_manual_translation = CFrame.new(cl_character.HumanoidRootPart.Position)

	local cam_cf = calculate_camera_cframe()

	cl_camera.CFrame = cl_camera.CFrame:Lerp(cam_cf, camera_follow_speed)

	local headset_relative_cf = VRService:GetUserCFrame(Enum.UserCFrame.Head)

	--return 
	-- set headmodel to coorrect world pos
	local head_world_cf = cam_cf * headset_relative_cf
	head_model.CFrame = head_world_cf

	hud.CFrame = cl_camera.CFrame * CFrame.new(0, 0, -1) -- hud offset

	-- TODO: hands not exactly lining up in VR mode
	left_hand.GoalCFrame  = head_world_cf * left_hand.RelativeCFrame * left_hand.DebugCFrame
	right_hand.GoalCFrame = head_world_cf * right_hand.RelativeCFrame * right_hand.DebugCFrame

	if not DEV_nokinematics then
		kinematics(head_world_cf)
	end

	if DEV_vrkeyboard then
		DEV_override_mouse = DEV_override_mouse + (
			UserInputService:GetMouseDelta()
			* math.rad(DEV_override_mouse_lookspeed)
		)
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

local function on_physicsstep(delta)
	if DEV_vrkeyboard then
		-- position hands with fake inputs
		left_hand.DebugCFrame = left_hand.DebugCFrame * 
			DebugBoard.GetLeftHandDeltaCFrame()

		right_hand.DebugCFrame = right_hand.DebugCFrame *
			DebugBoard.GetRightHandDeltaCFrame()

		local movement_delta = DebugBoard.GetMovementDeltaVec2()
		cl_character.Humanoid:Move(Vector3.new(movement_delta.Y, 0, movement_delta.X), true)
	end

	left_hand:Update(delta)
	right_hand:Update(delta)

	cl_character.TorsoJ.CFrame = cl_character.HeadJ.CFrame * CFrame.new(0, -2, 0)

	stop_parts_floating_away()

	
end

local function manual_rotate_left()
	cl_manual_rotation = cl_manual_rotation - 45
end
local function manual_rotate_right()
	cl_manual_rotation = cl_manual_rotation + 45
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
		manual_rotate_left()
		flicked = true
	end
	
	if accur_x < -0.8 and flicked == false then
		manual_rotate_left()
		flicked = true
	end

	-- joystick is considered at rest
	if accur_x <= 0.4 and accur_x >= -0.4 then
		flicked = false
	end
end
-------------------------------------------------------
-- OCULUS HARDWARE INPUT FUNCTIONS --
local function oculus_input_changed(inp)
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
		right_hand:SetGripCurl(inp.Position.Z)

		if inp.Position.Z < 0.95 then
			right_hand:Release()
		end
	end	
	if inp.KeyCode == l_grip_sensor then 
		left_hand:SetGripCurl(inp.Position.Z) 

		if inp.Position.Z < 0.95 then
			left_hand:Release()
		end
	end
	
	-- index finger
	if inp.KeyCode == r_indx_sensor then 
		right_hand:SetIndexFingerCurl(inp.Position.Z) 
	end
	if inp.KeyCode == l_indx_sensor then 
		left_hand:SetIndexFingerCurl(inp.Position.Z) 
	end
end

local function oculus_input_begin(input)

end

local function oculus_input_end(input)

end
------------------------------------------------
-- VALVE INDEX HARDWARE INPUT FUNCS --
local function index_input_begin(input)
	if input.KeyCode == l_grip_sensor then

		left_hand:Grab()
	end
	if input.KeyCode == r_grip_sensor then

		right_hand:Grab()
	end
end

local function index_input_end(input)
	if input.KeyCode == l_grip_sensor then

		left_hand:Release()
	end

	if input.KeyCode == r_grip_sensor then

		right_hand:Release()
	end
end

local function index_input_changed(input)

end
------------------------------------------------------
local function wmr_input_begin(input)

end

local function wmr_input_end(input)


end

local function wmr_input_changed(input)

end
-------------------------------------------------------

local function on_input_changed(input)
	if DEV_lockstate then return end
	--if hardware == "oculus" then
	oculus_input_changed(input)
	--elseif hardware == "index" then
	index_input_changed(input)
	--elseif hardware == "wmr" then
	wmr_input_changed(input)
	--end
end

local function on_input_begin(input)
	if input.KeyCode == Enum.KeyCode.Nine then
		DEV_lockstate = not DEV_lockstate
		print("Hand Locking "..(DEV_lockstate and "On" or "Off"))
	end

	if DEV_lockstate then return end


	if DEV_vrkeyboard then

		if input.KeyCode == Enum.KeyCode.KeypadFive then
			cl_character.Humanoid.Jump = true
		end
	
		if input.KeyCode == Enum.KeyCode.Left  then manual_rotate_left()  end
		if input.KeyCode == Enum.KeyCode.Right then manual_rotate_right() end
	
		if input.KeyCode == Enum.KeyCode.LeftShift then
			left_hand:Grab()
			left_hand:SetGripCurl(1)
		end
	
		if input.KeyCode == Enum.KeyCode.LeftControl then
			left_hand:SetIndexFingerCurl(1)
		end
	
		if input.KeyCode == Enum.KeyCode.RightShift then
			right_hand:Grab()
			right_hand:SetGripCurl(1)
		end
	
		if input.KeyCode == Enum.KeyCode.RightControl then
		   right_hand:SetIndexFingerCurl(1)
		end

		-- mouse locking
		if input.KeyCode == Enum.KeyCode.Space then
			if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			else
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		end
		--DebugBoard.InputBegan(input, left_hand, right_hand, my_camera_head)
	end

--	if hardware == "oculus" then
		oculus_input_begin(input)
--	elseif hardware == "index" then
		index_input_begin(input)
--  elseif hardware == "wmr" then
		wmr_input_begin(input)
--	end
end

local function on_input_end(input)
	if DEV_lockstate then return end
	if DEV_vrkeyboard then
		if input.KeyCode == Enum.KeyCode.LeftShift then
			left_hand:Release()
			left_hand:SetGripCurl(0)
		end
	
		if input.KeyCode == Enum.KeyCode.LeftControl then
			left_hand:SetIndexFingerCurl(0)
		end
	
		if input.KeyCode == Enum.KeyCode.RightShift then
			right_hand:Release()
			right_hand:SetGripCurl(0)
		end
	
		if input.KeyCode == Enum.KeyCode.RightControl then
			right_hand:SetIndexFingerCurl(0)
		end
	end

--	if hardware == "oculus" then
		oculus_input_end(input)
	--elseif hardware == "index" then
		index_input_end(input)
--	elseif hardware == "wmr" then
		wmr_input_end(input)
--	end
end

-----------------------------------------------------------------------
local function on_server_reflect_gunshot_effects(shooter, gun)
	if shooter ~= cl_player then
		-- TODO: shoot gun

		gun.Fire:Stop()
		gun.Fire.TimePosition = 0.05
		gun.Fire:Play()

		gun.Rifling.BillboardGui.Enabled = true
		gun.Rifling.BillboardGui.ImageLabel.Rotation = math.random(0, 360)
		delay(1/20, function()
			gun.Rifling.BillboardGui.Enabled = false
		end)
	end
end
------------------------------------------------------------------------

local client_gunshot = Networking.GetNetHook("ClientShoot")
client_gunshot.OnClientEvent:Connect(on_server_reflect_gunshot_effects)
-----------------------
RunService.RenderStepped:Connect(        on_renderstep   )
RunService.Stepped:Connect(              on_physicsstep  )
UserInputService.InputChanged:Connect(   on_input_changed)
UserInputService.InputEnded:Connect(     on_input_end    )
UserInputService.InputBegan:Connect(     on_input_begin  )
-----------------------
_G.log("VRClient Setup Complete")