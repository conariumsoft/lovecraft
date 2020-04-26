-- Services
------------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local VRService        = game:GetService("VRService")
local StarterGui       = game:GetService("StarterGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
------------------------------------------------------
-- Modules
local VRHand  = require(ReplicatedStorage.VRHand_class)
------------------------------------------------------
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

-- starting point object & camera focus
local vr_base = game.Workspace.cameraPos


local local_camera = game.Workspace.CurrentCamera do
	local_camera.CameraSubject = vr_base
	local_camera.CameraType = Enum.CameraType.Scriptable
end

-- container for vr hand models
local local_world_folder = Instance.new("Folder") do
	local_world_folder.Name = "LocalVRModels"
	local_world_folder.Parent = game.workspace
end

local LeftHand = VRHand:subclass("LeftHand")
-- TODO: check if can define class properties... (may not correctly inherit?)
--LeftHand.handModel = left_hand_model

function LeftHand:__ctor(player)
	-- TODO: make self.super:__ctor() work?
	-- it may already work, I can't remember
	VRHand.__ctor(self, player)
	self.userCFrame = Enum.UserCFrame.LeftHand
	self.handedness = "Left"
	self.handModel = left_hand_model:Clone()
	self.handModel.Parent = local_world_folder
	
	self:initializeAnimations()
	self:connectModels()
end

local RightHand = VRHand:subclass("RightHand")

function RightHand:__ctor(player)
	VRHand.__ctor(self, player)
	self.handedness = "Right"
	self.userCFrame = Enum.UserCFrame.RightHand
	self.handModel = right_hand_model:Clone()
	self.handModel.Parent = local_world_folder
	
	self:initializeAnimations()
	self:connectModels()
end

local_camera.CFrame = CFrame.new(vr_base.Position)

local my_left_hand = LeftHand:new(local_player)
local my_right_hand = RightHand:new(local_player)

--------

local InteractiveObjectMetadata = require(game.ReplicatedStorage.ItemData)

	
RunService.RenderStepped:Connect(function(delta)
	
	-- TODO: align relative to Enum.UserCFrame.Head?
	local_camera.CFrame = CFrame.new(vr_base.Position)
	
	my_left_hand:update(delta)
	my_right_hand:update(delta)
	
	local base_cf = local_camera.CFrame
	
	local left_hand_reported_cframe =  base_cf * VRService:GetUserCFrame(Enum.UserCFrame.LeftHand)
	local right_hand_reported_cframe = base_cf * VRService:GetUserCFrame(Enum.UserCFrame.RightHand)
	
end)

local sensor_grip_right  = Enum.KeyCode.ButtonR1
local sensor_index_right = Enum.KeyCode.ButtonR2
local sensor_grip_left   = Enum.KeyCode.ButtonL1
local sensor_index_left  = Enum.KeyCode.ButtonL2

UserInputService.InputChanged:Connect(function(inp, _)
	--print("gripreport:" .. grip_strength)
	-- palm grip
	if inp.KeyCode == sensor_grip_right then 
		my_right_hand:setGripCurl(inp.Position.Z) 
	end	
	if inp.KeyCode == sensor_grip_left then 
		my_left_hand:setGripCurl(inp.Position.Z) 
	end
	
	-- index 
	if inp.KeyCode == sensor_index_right then 
		
		my_right_hand:setIndexFingerCurl(inp.Position.Z) 
	end
	if inp.KeyCode == sensor_index_left then 
		

		my_left_hand:setIndexFingerCurl(inp.Position.Z) 
	end
end)

UserInputService.InputBegan:Connect(function(inp, _)
	if inp.KeyCode == Enum.KeyCode.ButtonL1 then
		my_left_hand:grab()
	end
	if inp.KeyCode == Enum.KeyCode.ButtonR1 then
		my_right_hand:grab()
	end
end)

UserInputService.InputEnded:Connect(function(inp, _)
	if inp.KeyCode == Enum.KeyCode.ButtonL1 then
		my_left_hand:release()
	end
	if inp.KeyCode == Enum.KeyCode.ButtonR1 then
		my_right_hand:release()
	end
end)