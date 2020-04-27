--[[
	VRHand class
	- last edit josh 4/24/20 7:00pm
]]--
--[[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst   = game:GetService("ReplicatedFirst")
local Workspace			= game:GetService("Workspace")
local VRService         = game:GetService("VRService")
local PhysicsService    = game:GetService("PhysicsService")
--wassgoooddddd
local camera = workspace.CurrentCamera
local BaseObject 				= require(ReplicatedStorage.BaseObject)
local r3handler  				= require(ReplicatedStorage.RotatedRegion3)
local InteractiveObjectMetadata = require(ReplicatedStorage.ItemData)
local HandAnimations			= require(ReplicatedFirst.HandAnimations)
]]

using "RBX.ReplicatedStorage"
using "RBX.ReplicatedFirst"
using "RBX.Workspace"
using "RBX.VRService"
using "RBX.PhysicsService"
using "Lovecraft.BaseObject"
using "Lovecraft.SoftWeld"
using "Lovecraft.Lib.RotatedRegion3"
using "Game.Data.InteractiveObjectMetadata"
using "Game.Data.HandAnimations"

--[[
-- owen, pls define these :)
local dbg_using_default = false

local pos_is_rigid = false
local pos_is_reactive = false
local pos_responsiveness = 200
local pos_max_force = 30000
local pos_max_velocity = math.huge
local rot_is_rigid = false
local rot_is_reactive = false
local rot_responsiveness = 25
local rot_max_angular_vel = math.huge
local rot_max_torque = 10000
local rot_primary_axis_only = false

-- TODO: create a SoftWeld class module
local function CreateSoftWeld(master_part, follower_part)

	local master_attachment = Instance.new("Attachment")
	master_attachment.Parent = master_part
	master_attachment.Name = "MasterAttachment"
	--master_attachment.Visible = true
	
	local follower_attachment = Instance.new("Attachment")
	follower_attachment.Position = follower_part["attachmentOffset"].Value
	follower_attachment.Parent = follower_part
	--follower_attachment.Visible = true
	follower_attachment.Name = "FollowerAttachment"
	
	local pos_constraint = Instance.new("AlignPosition") do	
		pos_constraint.Name = "PositionConstraint"
		pos_constraint.Visible = true
		if (not dbg_using_default) then
			pos_constraint.RigidityEnabled      = pos_is_rigid
			pos_constraint.ReactionForceEnabled = pos_is_reactive
			pos_constraint.Responsiveness       = pos_responsiveness
			pos_constraint.MaxForce             = pos_max_force
			pos_constraint.MaxVelocity          = pos_max_velocity
		end
		pos_constraint.Attachment0 = follower_attachment
		pos_constraint.Attachment1 = master_attachment
		
		pos_constraint.Parent = master_part
	end
	
	local rot_constraint = Instance.new("AlignOrientation") do
		rot_constraint.Name = "RotationConstraint"
		rot_constraint.Visible = true
		if (not dbg_using_default) then
			rot_constraint.MaxAngularVelocity    = rot_max_angular_vel
			rot_constraint.MaxTorque             = rot_max_torque
			rot_constraint.PrimaryAxisOnly       = rot_primary_axis_only
			rot_constraint.ReactionTorqueEnabled = rot_is_reactive
			rot_constraint.Responsiveness        = rot_responsiveness
			rot_constraint.RigidityEnabled       = rot_is_rigid
		end
		
		rot_constraint.Attachment0 = follower_attachment
		rot_constraint.Attachment1 = master_attachment
		
		rot_constraint.Parent = master_part
	end
end

local function BreakSoftWeld(master_part, follower_part)
	master_part.MasterAttachment:Destroy()
	follower_part.FollowerAttachment:Destroy()
	master_part.PositionConstraint:Destroy()
	master_part.RotationConstraint:Destroy()
end

local function CreateHardWeld(master_part, follower_part)
	local weld = Instance.new("WeldConstraint")
	
	weld.Part0 = master_part
	weld.Part1 = follower_part
	weld.Parent = master_part
	weld.Enabled = true
	weld.Name = "GrabConstraint"
end

local function BreakHardWeld(master_part, follower_part)
	master_part.GrabConstraint:Destroy()
end
]]

--- VR Hand Base class. 
-- @class VRHand
-- @description G
local VRHand = BaseClass:subclass("VRHand")

function VRHand:__ctor(player, vr_head, handedness, hand_model)

	self.IndexFingerPressure = 0
	self.GripPressure = 0
	self.Anims = {}
    self.CurrentAnim = nil
	self.IsRunning = false
	self.HandPosition = Vector3.new(0, 0, 0)
	self.LastHandPosition = Vector3.new(0, 0, 0)
	
	

	self.Head = vr_head
	self.Player = player
	self.Handedness = handedness

	if (self.Handedness == "Left") then
		self.UserCFrame = Enum.UserCFrame.LeftHand
	else
		self.UserCFrame = Enum.UserCFrame.RightHand
	end

	

	self.HandModel = hand_model
	self.HandModel.Parent = Workspace.LocalVRModels
	do
		local collision_group = self.Handedness.."HandModels"
		for _, obj in pairs(self.HandModel:GetDescendants()) do 
			if obj:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(obj, collision_group)
			end 
		end
	end
	
	local lock_pt = Instance.new("Part") do 
		-- reference position for VRHand reported position
		lock_pt.Size = Vector3.new(1,1,1)
		lock_pt.Anchored = true
		lock_pt.CanCollide = false
		lock_pt.Transparency = 1
		lock_pt.Name = "HandLockPart"
		lock_pt.Parent = game.Workspace
	end
	self.LockPart = lock_pt

	self.HoldingObject = nil -- if grabbed something
	self.ObjectContactPoint = nil
	self._HandModelSoftWeld = SoftWeld:new(self.LockPart, self.HandModel.PrimaryPart)
	self._GrabbedObjectWeld = nil
	
	self:InitializeAnimations()
end

function VRHand:InitializeAnimations()
	self.Animator = Instance.new("AnimationController")
	self.Animator.Parent = self.HandModel	
	-- assuming object subclass ctor has been called
	-- meaning these properties should be defined

	for name, val in pairs(HandAnimations) do
		assert(val, name.." anim is nil?")
		
		if (type(val) == "userdata" and val:IsA("Animation")) then
			self:AddAnim(name, val)	
		elseif (type(val) == "table") then
			self:AddAnim(name, val[self.Handedness])
		else
			error("test fail condition: animation was unable to load: "..name)
		end
	end
end

do -- animation methods
	function VRHand:AddAnim(name, animation)
		
		local anim_track = self.Animator:LoadAnimation(animation)
		
		anim_track:Play()
		anim_track:AdjustSpeed(0)
		self.Anims[name] = anim_track
	end
	function VRHand:HasAnim(name)
		for key, val in pairs(self.Anims) do
			if key == name then
				return val
			end
		end
	end
	function VRHand:GetAnim(name)
		return self.Anims[name]
	end
	function VRHand:GetCurrentAnim()
		return self.CurrentAnim
	end
	function VRHand:SetCurrentAnim(anim_track)
	    self.CurrentAnim = anim_track
	    
	end
	
	function VRHand:PlayAnim(anim_track, fade_time, weight, speed)
	
		local anim = self.Anims[anim_track]
		anim:Play(fade_time, weight, speed)
	
	end

	function VRHand:GetAnimTimeSeconds()end
	function VRHand:SetAnimTimeScale()      end
	function VRHand:SetAnimPlaybackScale()  end
	function VRHand:SetAnimOverridable()    end
	function VRHand:GetAnimOverridable()   end
	function VRHand:LerpAnimSet() end
end



function VRHand:SetIndexFingerCurl(grip_strength)
	self.IndexFingerPressure = grip_strength
	local anim = self:GetAnim("IndexFingerCurl")
	anim.TimePosition = anim.Length * grip_strength
end

function VRHand:SetGripCurl(grip_strength)
	self.GripPressure = grip_strength
	local anim = self:GetAnim("PalmCurl")
	anim.TimePosition = anim.Length * grip_strength
end

local DEBUG_SHOW_HAND_CFRAME = true

function VRHand:Grab()

	local reported_pos = camera.CFrame * VRService:GetUserCFrame(self.UserCFrame)
	
	local region = RotatedRegion3.new(
		reported_pos,
		Vector3.new(.5,.5,.5) -- region radius
	)
	
	if DEBUG_SHOW_HAND_CFRAME then
		local b = Instance.new("Part") do
			b.Size = Vector3.new(0.05, 0.05, 0.05)
			b.Color = Color3.fromRGB(255, 0, 0)
			b.Anchored = true
			b.CanCollide = false
			b.Transparency = 0.5
			b.CFrame = reported_pos
			b.Parent = game.Workspace
		end
	end
	
	--[[
		OBJECT GRABBING SCENARIOS:
		these are not final decisions on objects, or even objects that'll be in game
		i'm trying to cover the bases of interacting with objects in VR
		
		- marker
			* one handed
			* single grab
			* custom anim
			* special grip
		- .44 Magnum Revolver
			* one or two handed
			* first hand to grab controls trigger
			* grabs at cylinder/cylinder release (swings open)
			* secondary trigger = cock the hammer
		- M1911 pistol
			* grip can be one or two handed
			* secondary trigger = magazine release
			* slide grip point
			* custom anim, special grip
		- vz62 Skorpion
			* magazine grip point
			* secondary trigger = magazine release
			* one hand on handle
		- box
			* grip is held at the point of grabbing (no custom alignment)
			* can grab with inf hands
		- AkM
			* grip points
				charging handle
				barrel
				magazine
				handle (one hand at a time)
			* secondary trigger = magazine release
			* custom anim & grip alignment for primary hand

	]]

	local parts = region:FindPartsInRegion3WithWhiteList(Workspace.physics:GetDescendants())
	local object = nil
	for _, v in pairs(parts) do
		print(v.Name)

		-- a gun's handle for example
		if v:FindFirstChild("PrimaryGripPoint") then
			if v.Value == false then -- item hasn't been grabbed yet, so this hand will grab
				-- this hand is now primary grip



			end
		end

		if v:FindFirstChild("GripPoint") then
			if v.Value == false then -- hasn't been grabbed yet

			end
		end

		if v:FindFirstChild("pickup") then
			object = v.Parent
			print("found obj")
			break
		end
	end
	
	if (object == nil) then return end
	self.HoldingObject = object
	
	for _, obj in pairs(self.HoldingObject:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(obj, "Grabbed")
		end
	end
	
	print("Ho, hosssssss!")
	self.HoldingObject.PrimaryPart.pickup.Value = true
	
	-- master and follower part, respectively
	self.HoldingObject:SetPrimaryPartCFrame(reported_pos)
	
	self.GrabbedObjectWeld = SoftWeld:new(self.HandModel.PrimaryPart, self.HoldingObject.PrimaryPart)

	-- TODO: create sanity checks for indexing metadata list
	local grip_data = InteractiveObjectMetadata[self.HoldingObject.Name]
	
	-- pretend code:
	do
		--local weapon_metadata_inst = blah



	--	if weapon_metadata_inst
	end

	-- possible issue::
	-- this is initial CFrame set, but we also are
	-- setting CFrame inside VRHand:update()
	
	-- does model need custom grip alignment?
	print("Heee,heee!")
	if grip_data.grip_type == "Default" then
						
	elseif grip_data.grip_type == "Custom" then
						
		--self.holdingObject:SetPrimaryPartCFrame(
			--(self.handModel:GetPrimaryPartCFrame()--[[ * CFrame.new(grip_data.grip_orientation.offset)]]) --*
			--grip_data.grip_orientation.rotation

		--)
	end
	
    if grip_data.on_grab_begin then --    
  		grip_data.on_grab_begin(self.Player, self.HandModel, self.HoldingObject)
	end
	
	-- NOTE: maybe control custom anims from inside item...?
	if grip_data.grip_anim then -- Animate
        if self:HasAnim(grip_data.grip_anim) then
            self:SetRunningAnim(self:GetAnim(grip_data.grip_anim), true)
        end
	end
end
function VRHand:Release() 
	-- TODO: play anim?
	if self.HoldingObject ~= nil then
		
		self.GrabbedObjectWeld:Break()

		for _, obj in pairs(self.HoldingObject:GetDescendants()) do
			if obj:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(obj, "Interactives")
			end
		end
		
		self.HoldingObject = nil
	end
end


local function SetCollisions(model, collide)
	for _, p in pairs(model:GetDescendants()) do
		if (p:IsA("BasePart")) then
			p.CanCollide = collide
		end
	end
end

function VRHand:update(dt)

	local reported_cframe = camera.CFrame * VRService:GetUserCFrame(self.userCFrame)
	
	self.LastHandPosition = self.HandPosition
	self.HandPosition = reported_cframe
	
	
	self.LockPart.CFrame = reported_cframe
	
	--self.handModel:SetPrimaryPartCFrame(reported_cframe)
	
	-- TODO: optimize
	if (self.LockPart.Position - self.HandModel.PrimaryPart.Position).magnitude > 5 then
		--SetCollisions(self.handModel, false)
	else
		--SetCollisions(self.handModel, true)
	end
	
	if self.HoldingObject ~= nil then
		
		--print("holding: ".. tostring(self.holdingObject.PrimaryPart.Velocity))
		-- refactored instead of creating a spawn() thread
		-- event-based scripting is much nicer :DD
		--self.holdingObject:SetPrimaryPartCFrame(reported_pos)

		local object_meta = InteractiveObjectMetadata[self.HoldingObject.Name]
		
		object_meta:OnContactPointStep(self, self.HoldingObject, dt)

		if mdata.on_grab_step then
			mdata.on_grab_step(self.player, self.handModel, self.holdingObject, dt)
		end
	end
end

return VRHand