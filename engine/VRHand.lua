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
using "Game.Data.InteractiveObjectMetadata"
using "Game.Data.HandAnimations"



local function FindGrabbableObjectInHandRegion(region)
	-- TODO: collisiongroups instead of a folder?
	
	local parts = region:FindPartsInRegion3WithWhiteList(Workspace.physics:GetDescendants(), 1000)
	
	-- possible optimisation candidate
	-- if we ever start having huge numbers of pickup items
	for _, v in pairs(parts) do
		print(v)
		if v:FindFirstChild("pickup") then
			return v.Parent
		end
	end
	return nil
end

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
local VRHand = BaseObject:subclass("VRHand")

function VRHand:__ctor(player, handedness, hand_model)
	self.Player = player
	
	self.Handedness = handedness

	if (self.Handedness == "Left") then
		self.UserCFrame = Enum.UserCFrame.LeftHand
	else
		self.UserCFrame = Enum.UserCFrame.RightHand
	end

	self.HoldingObject = nil -- if grabbed something
	
	self.HandModel = hand_model
	
	self.anims = {}
    self.currentAnim = nil
    self.isRunning = false

	local lockPart = Instance.new("Part") do 
		-- reference position for VRHand reported position
		lockPart.Size = Vector3.new(1,1,1)
		lockPart.Anchored = true
		lockPart.CanCollide = false
		lockPart.Transparency = 1
		lockPart.Name = "HandLockPart"
		lockPart.Parent = game.Workspace
	end
	
	self.lockPart = lockPart
	
	self.handPosition = nil
	self.lastHandPosition = nil

end

function VRHand:connectModels()
	CreateSoftWeld(self.lockPart, self.handModel.PrimaryPart)
	
	for _, obj in pairs(self.handModel:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(obj, "HandModels")
		end
	end
	
	local reported_pos = camera.CFrame * VRService:GetUserCFrame(self.userCFrame)
	-- DO THIS to get hands in proper region (initially)
	self.handModel:SetPrimaryPartCFrame(reported_pos)
	
end

do -- animation methods
	function VRHand:addAnim(name, animation)
		
		local anim_track = self.animator:LoadAnimation(animation)
		
		anim_track:Play()
		anim_track:AdjustSpeed(0)
		self.anims[name] = anim_track
	end
	function VRHand:hasAnim(name)
		for key, val in pairs(self.anims) do
			if key == name then
				return val
			end
		end
	end
	function VRHand:getAnim(name)
		return self.anims[name]
	end
	function VRHand:getCurrentAnim()
		return self.currentAnim
	end
	function VRHand:setCurrentAnim(anim_track)
	    self.currentAnim = anim_track
	    
	end
	
	function VRHand:playAnim(anim_track, fade_time, weight, speed)
	
		local anim = self.anims[anim_track]
		anim:Play(fade_time, weight, speed)
	
	end

	function VRHand:getAnimTimeSeconds()end
	function VRHand:setAnimTimeScale()      end
	function VRHand:setAnimPlaybackScale()  end
	function VRHand:setAnimOverridable()    end
	function VRHand:getAnimOverridable()   end
	function VRHand:lerpAnimSet() end
end

function VRHand:initializeAnimations()
	self.animator = Instance.new("AnimationController")
	self.animator.Parent = self.handModel	
	-- assuming object subclass ctor has been called
	-- meaning these properties should be defined

	for name, val in pairs(HandAnimations) do
		assert(val, name.." anim is nil?")
		
		if (type(val) == "userdata" and val:IsA("Animation")) then
			self:addAnim(name, val)	
		elseif (type(val) == "table") then
			self:addAnim(name, val[self.handedness])
		else
			error("test fail condition: animation was unable to load: "..name)
		end
	end
end

function VRHand:setIndexFingerCurl(grip_strength)
	local anim = self:getAnim("IndexFingerCurl")
	anim.TimePosition = anim.Length * grip_strength
end

function VRHand:setGripCurl(grip_strength)
	local anim = self:getAnim("PalmCurl")
	anim.TimePosition = anim.Length * grip_strength
end

local DEBUG_SHOW_HAND_CFRAME = true

function VRHand:grab()

	local reported_pos = camera.CFrame * VRService:GetUserCFrame(self.userCFrame)
	
	local region = r3handler.new(
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
	
	local parts = region:FindPartsInRegion3WithWhiteList(workspace.physics:GetDescendants())
	local object = nil
	for _, v in pairs(parts) do
		print(v.Name)
		if v:FindFirstChild("pickup") then
			object = v.Parent
			print("found obj")
			break
		end
	end
	
	if (object == nil) then return end
	self.holdingObject = object
	
	for _, obj in pairs(self.holdingObject:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(obj, "Grabbed")
		end
	end
	
	print("Ho, hosssssss!")
	self.holdingObject.PrimaryPart.pickup.Value = true
	
	-- master and follower part, respectively
	self.holdingObject:SetPrimaryPartCFrame(reported_pos)
	
	CreateSoftWeld(self.handModel.PrimaryPart, self.holdingObject.PrimaryPart)

	-- TODO: create sanity checks for indexing metadata list
	local grip_data = InteractiveObjectMetadata[self.holdingObject.Name]
	
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
  		grip_data.on_grab_begin(self.player, self.handModel, self.holdingObject)
	end
	
	if grip_data.grip_anim then -- Animate
        if self:hasAnim(grip_data.grip_anim) then
            self:setRunningAnim(self:getAnim(grip_data.grip_anim), true)
        end
	end
end
function VRHand:release() 
	-- TODO: play anim?
	if self.holdingObject ~= nil then
		
		BreakSoftWeld(self.handModel.PrimaryPart, self.holdingObject.PrimaryPart)

		
		for _, obj in pairs(self.holdingObject:GetDescendants()) do
			if obj:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(obj, "Interactives")
			end
		end
		
		--[[ trying this?
		self.holdingObject.PrimaryPart.Velocity =]]
		
		self.holdingObject = nil
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
	
	
	self.lastHandPosition = self.handPosition
	self.handPosition = reported_cframe
	
	
	self.lockPart.CFrame = reported_cframe
	
	--self.handModel:SetPrimaryPartCFrame(reported_cframe)
	
	-- TODO: optimize
	if (self.lockPart.Position - self.handModel.PrimaryPart.Position).magnitude > 5 then
		--SetCollisions(self.handModel, false)
	else
		--SetCollisions(self.handModel, true)
	end
	
	if self.holdingObject ~= nil then
		
		--print("holding: ".. tostring(self.holdingObject.PrimaryPart.Velocity))
		-- refactored instead of creating a spawn() thread
		-- event-based scripting is much nicer :DD
		--self.holdingObject:SetPrimaryPartCFrame(reported_pos)

		local mdata = InteractiveObjectMetadata[self.holdingObject.Name]
		
		if mdata.on_grab_step then
			mdata.on_grab_step(self.player, self.handModel, self.holdingObject, dt)
		end
	end
end

return VRHand