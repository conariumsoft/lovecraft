using "RBX.ReplicatedStorage"
using "RBX.ReplicatedFirst"
using "RBX.Workspace"
using "RBX.VRService"
using "RBX.PhysicsService"
using "Lovecraft.BaseObject"
using "Lovecraft.SoftWeld"
using "Lovecraft.Lib.RotatedRegion3"
using "Lovecraft.ItemManager"
using "Game.Data.ItemMetadata"
using "Game.Data.HandAnimations"

--- VR Hand Base class. 
-- @class VRHand
-- @description G
local VRHand = BaseClass:subclass("VRHand")

---
-- @name VRHand:new()
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
	self.GripPoint = nil
	self._HandModelSoftWeld = SoftWeld:new(self.LockPart, self.HandModel.PrimaryPart)
	self._GrabbedObjectWeld = nil
	
	self:InitializeAnimations()
end

---
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

---
function VRHand:SetIndexFingerCurl(grip_strength)
	self.IndexFingerPressure = grip_strength
	local anim = self:GetAnim("IndexFingerCurl")
	anim.TimePosition = anim.Length * grip_strength
end

---
function VRHand:SetGripCurl(grip_strength)
	self.GripPressure = grip_strength
	local anim = self:GetAnim("PalmCurl")
	anim.TimePosition = anim.Length * grip_strength
end

local DEBUG_SHOW_HAND_CFRAME = true

function VRHand:_HandleObjectPickup(object, grip_point)

	self.HoldingObject = object
	self.GripPoint = grip_point

	local object_meta = InteractiveObjectMetadata[object]

	if object_meta.class then
		object_meta.class:OnHandGrab(self, self.HoldingObject, self.GripPoint)
	end

	for _, obj in pairs(self.HoldingObject:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(obj, "Grabbed")
		end
	end

	grip_point.GripPoint.Value = true
	
	-- master and follower part, respectively
	self.HoldingObject:SetPrimaryPartCFrame(self.Head.CFrame * VRService:GetUserCFrame(self.userCFrame))	
	self._GrabbedObjectWeld = SoftWeld:new(self.HandModel.PrimaryPart, grip_point)
	-- TODO: create sanity checks for indexing metadata list

	if object_meta.grip_type == "Anywhere" then
		-- preserve orientation of hand relative to object at time of grab
	end

	if object_meta.grip_type == "GripPoint" then
		-- apply custom rotation etc
	end
end
---
function VRHand:Grab()

	local reported_pos = self.Head.CFrame * VRService:GetUserCFrame(self.UserCFrame)
	
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
	
	local parts = region:FindPartsInRegion3WithWhiteList(Workspace.physics:GetDescendants())
	local object = nil
	for _, v in pairs(parts) do
		print(v.Name)

		-- a gun's handle for example
		if v:FindFirstChild("GripPoint") then -- we know this object CAN be grabbed
			if v.GripPoint.Value == false then -- item hasn't been grabbed yet, so this hand will grab
				-- this hand is now primary grip
				v.GripPoint.Value = true
				self:_HandleObjectPickup(v.Parent, v)
				return
			end
		end
	end
end
---
function VRHand:Release() 
	-- TODO: play anim?
	if self.HoldingObject ~= nil then
		self.GripPoint.GripPoint.Value = false
		local object_meta = InteractiveObjectMetadata[self.HoldingObject.Name]

		if object_meta.class then
			object_meta.class:OnHandRelease(self, self.HoldingObject, self.GripPoint)
		end

		self._GrabbedObjectWeld:Break()

		for _, obj in pairs(self.HoldingObject:GetDescendants()) do
			if obj:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(obj, "Interactives")
			end
		end
		
		self.HoldingObject = nil
		self.GripPoint = nil
	end
end
---
function VRHand:Update(dt)

	local reported_cframe = self.Head.CFrame * VRService:GetUserCFrame(self.userCFrame)
	
	self.LastHandPosition = self.HandPosition
	self.HandPosition = reported_cframe
	
	self.LockPart.CFrame = reported_cframe
	
	
	-- TODO: optimize
	if (self.LockPart.Position - self.HandModel.PrimaryPart.Position).magnitude > 5 then
		--SetCollisions(self.handModel, false)
	else
		--SetCollisions(self.handModel, true)
	end
	
	if self.HoldingObject ~= nil then
	
		local object_meta = InteractiveObjectMetadata[self.HoldingObject.Name]
		
		if object_meta.class then
			object_meta.class:OnHeldStep(self, self.HoldingObject, dt, self.GripPoint)
		end
	end
end

return VRHand