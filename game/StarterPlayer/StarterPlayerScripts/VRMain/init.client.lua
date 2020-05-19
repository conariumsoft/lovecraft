--- Client game loop. Handles input and local rendering
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
_G.using "Lovecraft.VRHead"
_G.using "Lovecraft.DebugBoard"
_G.using "Lovecraft.Networking"
_G.using "Game.Data.ItemMetadata"


local ui = require(script.ui)

-- debugging tools
local DEV_skipintro = true
local DEV_vrkeyboard = false
local DEV_nokinematics = false
local DEV_lockstate = false

-- TODO: various hardware support
local headset_list = {
	"WindowsMixedReality",
	"ValveIndex",
	"OculusRift",
	"Vive"
}

local vr_enabled = UserInputService.VREnabled

require(script.highlighter)

local hardware = "oculus"

local no_button_scale = true

-- later on: make non-vr players go into spectator mode for deathmatch
-- if doing game testing, start in keyboard mode
-- when game is live, make so this will error & kick the playe
-- (at least until/if non-VR support is working)
if vr_enabled then
	ui.DisableDefaultRobloxCrap()
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
character.HeadJ.Transparency = 1
character.HeadJ.BillboardGui.Enabled = false

-- client is ready to start
-- send request for server-side init
local vr_state = Networking.GetNetHook("ClientRequestVRState")
vr_state:InvokeServer() -- remotefunction yield

--- Camera Setup
local_player.CameraMode = Enum.CameraMode.LockFirstPerson
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
Workspace.CurrentCamera.CameraSubject = nil--game.Workspace.BaseStation
Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

local head_model 	   = character:WaitForChild("HeadJ")
local left_hand_model  = character:WaitForChild("LHand")
local right_hand_model = character:WaitForChild("RHand")

local my_camera_head = VRHead:new(local_player, head_model) -- Head Physics & Camera

-- poll hapticservice for rumble support
local client_haptics_support


-- * VRHand class instances
local my_left_hand   = VRHand:new(local_player, my_camera_head, "Left",  left_hand_model)
local my_right_hand  = VRHand:new(local_player, my_camera_head, "Right", right_hand_model)


my_left_hand:Teleport( character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)) -- Bring models to player 
my_right_hand:Teleport(character.HumanoidRootPart.CFrame * CFrame.new(0, 0,  2))

local body_ik = require(script.localbody)

body_ik.SetLeftArm(character.LeftUpperArm, character.LeftLowerArm, left_hand_model)
body_ik.SetRightArm(character.RightUpperArm, character.RightLowerArm, right_hand_model)

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
local ControllerTranslationPoint = Vector3.new(0, 0, 0)
local ControllerHorizRotation = 0


local dbg_renderframes  = 0
local dbg_rendertime    = 0

_G.log("Client Setup Complete")

------------------------------------------------------------------------------------------------
local function on_renderstep(delta)
	dbg_renderframes = dbg_renderframes + 1
	dbg_rendertime = dbg_rendertime + delta

	if DEV_nokinematics then return end

	body_ik.SetHeadGoal(my_camera_head.PhysicalHead.CFrame)

	-- pass in reported VR hand position
	body_ik.SetLeftHandGoal(my_left_hand:GetPreSolveWorldCFrame())
	body_ik.SetRightHandGoal(my_right_hand:GetPreSolveWorldCFrame())

	-- run IK calc bs
	body_ik.Step()

	-- pull solved position back out.
	my_left_hand:SetPostSolveWorldCFrame(body_ik.GetLeftHandSolved())
	my_right_hand:SetPostSolveWorldCFrame(body_ik.GetRightHandSolved())
end

local function stop_parts_floating_away()
	-- even if we have networkownership, physics will still force parts down
	-- this will negate that
	character.HeadJ.Velocity                     = Vector3.new(0, 0, 0)
	character.TorsoJ.Velocity                    = Vector3.new(0, 0, 0)
	character.LeftLowerArm.Velocity              = Vector3.new(0, 0, 0)
	character.LeftUpperArm.Velocity              = Vector3.new(0, 0, 0)
	character.RightLowerArm.Velocity = Vector3.new(0,0,0)
	character.RightUpperArm.Velocity = Vector3.new(0,0,0)
	my_left_hand.HandModel.PrimaryPart.Velocity  = Vector3.new(0, 0, 0)
	my_right_hand.HandModel.PrimaryPart.Velocity = Vector3.new(0, 0, 0)
end

local function on_physicsstep(delta)
	my_camera_head:Update(delta)
	my_left_hand:Update(delta)
	my_right_hand:Update(delta)

	character.TorsoJ.CFrame = character.HeadJ.CFrame * CFrame.new(0, -2, 0)

	stop_parts_floating_away()

	if _G.VR_DEBUG then
		DebugBoard.RenderStep(my_camera_head, my_left_hand, my_right_hand)
	end
end
---------------------------------------------------------------------------------------------
-- left joystick operation
-- controls quick-flicking (instant 90-degree rotation)
local function left_joystick_state(jstick_vec)
	jstickright = jstick_vec

	--- PLAY WITH MOVEMENT
	character.Humanoid:Move(Vector3.new(jstickright.X, 0, -jstickright.Y), true)
end

-- right joystick operation
-- controls horiz movement
local function right_joystick_state(jstick_vec)
	jstickleft = jstick_vec

	local accur_x = jstickleft.X

	if accur_x > 0.8 and flicked == false then
		my_camera_head.FlickRotation = my_camera_head.FlickRotation - 45
		flicked = true
	end
	
	if accur_x < -0.8 and flicked == false then
		my_camera_head.FlickRotation = my_camera_head.FlickRotation + 45
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
	
	-- index finger
	if inp.KeyCode == r_indx_sensor then 
		my_right_hand:SetIndexFingerCurl(inp.Position.Z) 
	end
	if inp.KeyCode == l_indx_sensor then 
		my_left_hand:SetIndexFingerCurl(inp.Position.Z) 
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

		my_left_hand:Grab()
	end
	if input.KeyCode == r_grip_sensor then

		my_right_hand:Grab()
	end
end

local function index_input_end(input)
	if input.KeyCode == l_grip_sensor then

		my_left_hand:Release()
	end

	if input.KeyCode == r_grip_sensor then

		my_right_hand:Release()
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


	if _G.VR_DEBUG then
		DebugBoard.InputBegan(input, my_left_hand, my_right_hand, my_camera_head)
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
	if _G.VR_DEBUG then
		DebugBoard.InputEnded(input, my_left_hand, my_right_hand)
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
	if shooter ~= local_player then
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