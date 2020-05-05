_G.using "RBX.ReplicatedStorage"
_G.using "RBX.ReplicatedFirst"
_G.using "RBX.Workspace"
_G.using "RBX.VRService"
_G.using "RBX.HapticService"
_G.using "RBX.PhysicsService"
_G.using "Lovecraft.BaseClass"
_G.using "Lovecraft.SoftWeld"
_G.using "Lovecraft.Lib.RotatedRegion3"
_G.using "Lovecraft.Networking"
_G.using "Game.Data.ItemMetadata"

--- VR Hand Base class. 
local VRHand = BaseClass:subclass("VRHand")
---
-- @name VRHand:new()
function VRHand:__ctor(player, vr_head, handedness, hand_model)

	self.Haptics = {}
	self.IsGripped = true
	self.IndexFingerPressure = 0
	self.GripPressure = 0
	self.Anims = {}
    self.CurrentAnim = nil
	self.IsRunning = false
	self.HandPosition = Vector3.new(0, 0, 0)
	self.LastHandPosition = Vector3.new(0, 0, 0)
	self.VRControllerPosition = CFrame.new(0, 0, 0)

	self.Head = vr_head
	self.Player = player
	self.Handedness = handedness

	local has_vibration = HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)

	if (self.Handedness == "Left") then
		self.UserCFrame = Enum.UserCFrame.LeftHand
		if has_vibration then
			self.Haptics = {
				Enum.VibrationMotor.LeftTrigger,
				Enum.VibrationMotor.LeftHand
			}
		end
	else
		self.UserCFrame = Enum.UserCFrame.RightHand
		if has_vibration then
			self.Haptics = {
				Enum.VibrationMotor.RightTrigger,
				Enum.VibrationMotor.RightHand
			}
		end
	end

	self.HandModel = hand_model
	
	local virtual_hand = Instance.new("Part") do 
		-- reference position for VRHand reported position
		virtual_hand.Size = Vector3.new(0.2,0.2,0.2)
		virtual_hand.Anchored = true
		virtual_hand.CanCollide = false
		virtual_hand.Transparency = 0.5
		virtual_hand.Color = Color3.new(0.5, 0.5, 1)
		virtual_hand.Name = "VirtualHand"
		virtual_hand.Parent = game.Workspace
	end
	self.VirtualHand = virtual_hand

	self.HoldingObject = nil -- if grabbed something
	self.GripPoint = nil
	self._HandModelSoftWeld = SoftWeld:new(self.VirtualHand, self.HandModel.PrimaryPart, {
		pos_responsiveness = 75,
		rot_responsiveness = 40,
		pos_max_force = 5000,
		rot_max_torque = 5000,
		pos_max_velocity = 50000,
	})
	self._GrabbedObjectWeld = nil
	
	self.Animator = self.HandModel.Animator
	self:_LoadAnimationTracks()
end

function VRHand:_LoadAnimationTracks()
	for _, anim in pairs(ReplicatedStorage.Animations[self.Handedness]:GetChildren()) do
		local track = self.Animator:LoadAnimation(anim)
		track:Play()
		track:AdjustSpeed(0)
		self.Anims[anim.Name] = track
	end
end

function VRHand:Teleport(coord)
	self.VirtualHand.CFrame = coord
	self.HandModel:SetPrimaryPartCFrame(coord)
end

function VRHand:SetRumble(rumble_scale)
	for _, motor in pairs(self.Haptics) do
		HapticService:SetMotor(Enum.UserInputType.Gamepad1, motor, rumble_scale)
	end
end

do -- animation methods
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
	function VRHand:PlayAnim(anim_track, fade_time, weight, speed)-->
		local anim = self.Anims[anim_track]
		anim:Play(fade_time, weight, speed)
	end
	function VRHand:GetAnimTimeScale(anim_name)
		local anim = self:GetAnim(anim_name)
		if anim then
			return anim.TimePosition / anim.Length
		end
	end
	function VRHand:SetAnimTimeScale(anim_name, timescale)
		local anim = self:GetAnim(anim_name)
		if anim then
			anim.TimePosition = anim.Length * math.min(timescale, .99) 
			-- dumb hack. if anim ever reaches 1, it decides it's finished playing
		end
	end
end

local function GetItemMetadataByName(itemname)
	return ItemMetadata[itemname]
end

---
function VRHand:SetIndexFingerCurl(grip_strength)
	self.IndexFingerPressure = grip_strength
	self:SetAnimTimeScale("Index", grip_strength)

	if self.HoldingObject then
		local item = self.HoldingObject
		local object_meta = GetItemMetadataByName(item.Name)

		if object_meta and object_meta.class then
			object_meta.class:OnTriggerState(self, self.HoldingObject, grip_strength, self.GripPoint)
		end
	end
end

---
function VRHand:SetGripCurl(grip_strength)
	self.GripPressure = grip_strength
	self:SetAnimTimeScale("Grip", grip_strength)
end

local DEBUG_SHOW_HAND_CFRAME = true

-- Parse Item Metadata
-- Construct "SoftWeld" (Physics-based Alignments)
function VRHand:_HandleObjectPickup(object, grip_point)
	-- Parse item metadata to apply correct offset, grip type, and animations etc.
	self.HoldingObject = object
	self.GripPoint = grip_point

	local object_meta = GetItemMetadataByName(object.Name)

	-- TODO: create sanity checks for indexing metadata list	
	local gprops = {
		rot_is_reactive = true,
		rot_max_force = 15000,
		pos_max_force = 50000,
		pos_responsiveness = 150,
		rot_enabled = true,
		pos_enabled = true,
	}

	local master_part = self.HandModel.PrimaryPart
	local follow_part = grip_point

	local grab_anywhere = false
	
	if object_meta then
		if object_meta.name == "Skorpion" then
--[[
	IDEA 2 try:
		handle has rotation only

		high and even positioning on both
		mag has no rotation torque

	When RigidityEnabled is false, then the force will be determined
	by the AlignPosition.MaxForce, AlignPosition.MaxVelocity, and
	AlignPosition.Responsiveness. MaxForce and MaxVelocity are caps to
	the force and velocities respectively. The actual scale of the force is
	determined by the Responsiveness. The mechanism for responsiveness is a
	little complicated, but put simply the higher the responsiveness, the
	quickerthe constraint will try to reach its goal.
]]
--[[
	HR
		AlignPos
			MaxForce - 100000
			MaxVelocity - 20k
			Responsiveness - 100
		AlignOrientation
			MaxAngularVelocity - 50k
			MaxTorque - 50k
			Responsiveness - 100
	LR
		AlignPos
			MaxForce - 100000
			MaxVelocity - 25k
			Responsiveness - 100
			]]
			
			self._HandModelSoftWeld:Disable()
			local rot_torque = 50000
			local pos_force = 100000
			local rot_max_vel = 50000
			local pos_max_vel = 25000
			local rot_enabled = true

			local p = game.ReplicatedStorage.Props
			if grip_point.Name == "Handle" then
				rot_torque = p.RightHandRotationTorque.Value
				rot_max_vel = p.RightHandMaxAngularVelocity.Value
				pos_force = p.RightHandPositionForce.Value
				pos_max_vel = p.RightHandMaxVelocity.Value
			end

			if grip_point.Name == "Magazine" then
				rot_torque = 0
				rot_enabled = false
				pos_force = p.LeftHandPositionForce.Value
				pos_max_vel = p.LeftHandMaxVelocity.value
			end

			for _, obj in pairs(self.HoldingObject:GetDescendants()) do
				if obj:IsA("BasePart") then
					PhysicsService:SetPartCollisionGroup(obj, "Grabbed"..self.Handedness)
				end
			end
			object_meta.class:OnGrab(self, self.HoldingObject, self.GripPoint)
			self._GrabbedObjectWeld = SoftWeld:new(grip_point, self.HandModel.PrimaryPart, {
				rot_max_torque = 100000,
				pos_max_force = 200000,
				rot_responsiveness = 200,
				pos_responsiveness = 200
			})
			self._HandWeld = SoftWeld:new(self.VirtualHand, grip_point, {
				rot_max_torque = rot_torque,
				pos_max_force = pos_force,
				rot_max_angular_vel = rot_max_vel,
				pos_max_velocity = pos_max_vel,
				rot_enabled = rot_enabled,
			})
			return
		end
		if object_meta.class then
			object_meta.class:OnGrab(self, self.HoldingObject, self.GripPoint)
		end

		if object_meta.grip_type == "Anywhere" then
			grab_anywhere = true
		end
	
		if object_meta.grip_type == "GripPoint" then
			-- object_meta.grip_data should exist

			if not object_meta.grip_data then
				error("Object Metadata must contain a grip_data table if object grip_type is set to 'GripPoint' :" .. object_meta.Name)
			end

			local gripdata = object_meta.grip_data[grip_point.Name]
			if gripdata then

				if gripdata.anywhere then
					grab_anywhere = true
				end

				gprops.cframe_offset = gripdata.offset
				if gripdata.not_rigid then
					gprops.rot_enabled = false
				end
				if gripdata.animation then
					-- play anim
				end
			end
		end
		
	else -- no metadata, assume grab anywhere
		grab_anywhere = true
	end

	if grab_anywhere then
		gprops.cframe_offset = self.HandModel.PrimaryPart.CFrame:inverse() * grip_point.CFrame
	end

	-- if no object meta, assume "Anywhere"
	for _, obj in pairs(self.HoldingObject:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(obj, "Grabbed"..self.Handedness)
		end
	end
	
	if object.Name == "Environment" or grip_point.Anchored == true then
		gprops.pos_is_rigid = true
		gprops.pos_max_force = 1000000
	end

	self._GrabbedObjectWeld = SoftWeld:new(master_part, follow_part, gprops)
end
---
function VRHand:Grab()
	local reported_pos = self.VirtualHand.CFrame
	
	local region = RotatedRegion3.new(
		reported_pos,
		Vector3.new(0.25,0.25,0.25) -- region radius
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

		-- a gun's handle for example
		if v:FindFirstChild("GripPoint") then -- we know this object CAN be grabbed
			if v.GripPoint.Value == false then -- item hasn't been grabbed yet, so this hand will grab
				-- this hand is now primary grip
				local cgrab = Networking.GetNetHook("ClientGrab")
				cgrab:FireServer(v.Parent, v)
				self:_HandleObjectPickup(v.Parent, v)
				v.GripPoint.Value = true
				return
			end
		end
	end
end

local function CollisionGroupReset(model)
	for _, obj in pairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			--PhysicsService:SetPartCollisionGroup(obj, "Interactives")
		end
	end
end

---
function VRHand:Release() 
	-- TODO: play anim?
	if self.HoldingObject ~= nil then
		local obj = self.HoldingObject
		local object_meta = ItemMetadata[obj.Name]

		self.GripPoint.GripPoint.Value = false
		if object_meta and object_meta.class then
			object_meta.class:OnRelease(self, obj, self.GripPoint)
		end

		delay(0.25, function() 
			CollisionGroupReset(obj) 
		end)
		--fgff
		if object_meta.name == "Skorpion" then
			self._HandModelSoftWeld:Enable()
			self._HandWeld:Destroy()
			self._HandWeld = nil
		end
		if self._GrabbedObjectWeld then
			--print("Destroying Weld?", self._GrabbedObjectWeld)
			self._GrabbedObjectWeld:Destroy()
			self._GrabbedObjectWeld = nil
		end

		local crelease = Networking.GetNetHook("ClientRelease")
		--crelease:FireServer(self.HoldingObject, self.GripPoint)
		self.HoldingObject = nil
		self.GripPoint = nil
		
	end
end
---
function VRHand:Update(dt)

	if self.HoldingObject ~= nil then
	
		local object_meta = ItemMetadata[self.HoldingObject.Name]
		if object_meta and object_meta.class then
			object_meta.class:OnSimulationStep(self, self.HoldingObject, dt, self.GripPoint)
		end
	end

	self.LastHandPosition = self.HandPosition

	local reported_cframe = self.Head.PhysicalHead.CFrame * self.VRControllerPosition
	self.HandPosition = reported_cframe	
	self.VirtualHand.CFrame = reported_cframe

	-- TODO: optimize
	local hand_from_virtual_distance = (self.VirtualHand.Position - self.HandModel.PrimaryPart.Position).magnitude
	if hand_from_virtual_distance > 0.25 then
		self:SetRumble(hand_from_virtual_distance/8) -- play with this value.?
		--SetCollisions(self.handModel, false)
	else
		self:SetRumble(0)
		--SetCollisions(self.handModel, true)
	end

	if _G.VR_DEBUG then return end
	self.VRControllerPosition = VRService:GetUserCFrame(self.UserCFrame)
end

return VRHand