_G.using "RBX.ReplicatedStorage"
_G.using "RBX.ReplicatedFirst"
_G.using "RBX.Workspace"
_G.using "RBX.VRService"
_G.using "RBX.HapticService"
_G.using "RBX.PhysicsService"
_G.using "Lovecraft.SoftWeld"
_G.using "Lovecraft.Lib.RotatedRegion3"
_G.using "Lovecraft.Networking"
_G.using "Game.Data.ItemMetadata"

--- VR Hand Base class. 
local VRHand = _G.newclass("VRHand")
---
-- @name VRHand:new()
function VRHand:__ctor(player, vr_head, handedness, hand_model)

	self.Haptics = {} -- list of detected rumble motors
	self.IsGripped = true
	self.IndexFingerPressure = 0
	self.GripPressure = 0
	self.Anims = {} -- anim list? (make static anim list?)
    self.CurrentAnim = nil
	self.IsRunning = false
	self.HandPosition = Vector3.new(0, 0, 0)
	self.LastHandPosition = Vector3.new(0, 0, 0)
	self.OriginRelativeControllerPosition = CFrame.new(0, 0, 0) -- WTF is this name??

	self.Head = vr_head
	self.Player = player
	self.Handedness = handedness

	-- does VR controller support vibration?
	local has_vibration = HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1)

	-- grab haptic enums (ID's for motors)
	if has_vibration then
		if self.Handedness == "Left" then
			self.Haptics = {
				Enum.VibrationMotor.LeftTrigger,
				Enum.VibrationMotor.LeftHand
			}
		else
			self.Haptics = {
				Enum.VibrationMotor.RightTrigger,
				Enum.VibrationMotor.RightHand
			}
		end
	end

	-- detect correct hand enum for later use 
	-- make an enum?
	if     self.Handedness == "Left" then
		self.UserCFrame = Enum.UserCFrame.LeftHand
	elseif self.Handedness == "Right" then
		self.UserCFrame = Enum.UserCFrame.RightHand
	end
	self.HandModel = hand_model

	-- visualization of where VRService is reporting the hand to be
	local virtual_hand = Instance.new("Part") do 
		-- part props...
		-- kinda ugly?
		virtual_hand.Size = Vector3.new(0.2,0.2,0.2)
		virtual_hand.Anchored = true
		virtual_hand.CanCollide = false
		virtual_hand.Transparency = 0.5
		virtual_hand.Color = Color3.new(0.5, 0.5, 1)
		virtual_hand.Name = "VirtualHand"
		virtual_hand.Parent = game.Workspace
	end

	self.VirtualHand = virtual_hand

	-- glue weld that binds hand to correct position and orientation,
	-- while still respecting physical limits
	self._HandModelSoftWeld = SoftWeld:new(self.VirtualHand, self.HandModel.PrimaryPart, {
		pos_responsiveness = 75,
		rot_responsiveness = 40,
		pos_max_force = 5000,
		rot_max_torque = 5000,
		pos_max_velocity = 50000,
	})

	-- used later
	self._GrabbedObjectWeld = nil -- hand->held object glue
	self.HoldingObject = nil -- if grabbed something
	self.GripPoint = nil -- which point on an object did we grab?
	
	-- confirm replication of Animator (or else animations will not replicate back to server)
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

-- since models are physical, it's a good idea to teleport them along with the player
-- lest the get stuck in walls
function VRHand:Teleport(coord)
	self.HandModel:SetPrimaryPartCFrame(coord)
end


-- Haptic motor rumbling
function VRHand:SetRumble(rumble_scale)
	-- we access haptics table
	-- (can't know which motors to run ahead of time)
	-- could run all instead?
	for _, motor in pairs(self.Haptics) do
		HapticService:SetMotor(Enum.UserInputType.Gamepad1, motor, rumble_scale)
	end
end

----------------------------------------
-- Various animation controls
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
------------------------------------------------------------------------------

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

---

local function object_pickup_criteria(part)
	-- grip point will be false if our/another player isn't holding
	if part:FindFirstChild("GripPoint") and part.GripPoint.Value == false then
		return true
	end
	return false
end

local function find_object_can_pickup(region)
	local list = region:FindPartsInRegion3WithWhiteList(Workspace.physics:GetDescendants())

	for _, v in pairs(list) do
		local matches_criteria = object_pickup_criteria(v)
		if matches_criteria then
			return v.Parent, v
		end
	end
end

-- when item is grabbed
-- stick to hand at the position of grip
local function glue(hand_part, grip_point, glue_config)
	return SoftWeld:new(hand_part, grip_point, glue_config)
end

---
local function set_model_collision_group(model, group)
	for _, obj in pairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(obj, group)
		end
	end
end

---
function VRHand:Grab()
	--- find something to pick up within our palm region
	-- TODO: make this the palm area of real hand

	local reported_pos = self.VirtualHand.CFrame
	
	local palm_radius = 0.25
	local region = RotatedRegion3.new(
		reported_pos,
		Vector3.new(palm_radius,palm_radius,palm_radius)
	)
	
	-- compare objects in list against critera
	-- matched object or nil
	local item_pickup, part = find_object_can_pickup(region)
	
	-- no need to check part == nil
	if item_pickup == nil then return end
	-- if you make it here, then we found our item

	-- tell server what we're up to (picking something up)
	local notify_server_grab = Networking.GetNetHook("ClientGrab")
	notify_server_grab:FireServer(item_pickup, part)

	part.GripPoint.Value = true
	-- assign some members. (what are these used for?)
	self.HoldingObject = item_pickup
	self.GripPoint = part

	set_model_collision_group(item_pickup, "Grabbed"..self.Handedness)
	
	-- 
	local grip_config = {
		cframe_offset = self.HandModel.PrimaryPart.CFrame:inverse() * part.CFrame
	}

	-- object's Model.Name is used to search.
	-- metadata key must match to return...
	-- using metadata to configure how hand welds to model
	local obj_meta = GetItemMetadataByName(item_pickup.Name)

	-- found no metadata
	-- assume default properties
	-- (most likely non-functional prop or scenery)
	-- (needs no custom anim or grip style)
	if obj_meta then

		-- grip_data table contains def 
		if obj_meta.grip_data then

			-- class is optional value
			-- defines item functionality
			if obj_meta.class then
				-- onGrab(hand, item, grip_point)
				obj_meta.class:OnGrab(self, item_pickup, part)
			end
			-- hand animation state?
			if obj_meta.animation then

			end
			-- TODO: rig object to hand virtual position
			if obj_meta.hand_override then

			end

			-- if grip data is missing for this
			-- piece, assume "Anywhere" grip style
			if obj_meta.grip_data[part.Name] then
				local grip_data = obj_meta.grip_data[part.Name]

				grip_config = grip_data:ToWeldConfiguration()
			end
		end
	end

	-- firstly, disable hand->handmodel softweld.
	--self._HandModelSoftWeld:Disable()

	local hand_origin = self.HandModel.PrimaryPart
	-- finally, glue object to handmodel
	self._GrabbedObjectWeld = glue(hand_origin, part, grip_config)
	-- glue object to hand's real position?
	--self._HandWeld = glue()
end

--- old special case for "Skorpion" that I made during debugging, which
-- soon bloated
-- may incorporate some of the functionality back in
--[[
if object_meta.name == "Skorpion" then
			
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
]]

local function CollisionGroupReset(model)
	for _, obj in pairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			--PhysicsService:SetPartCollisionGroup(obj, "Interactives")
		end
	end
end

--- fired when hand grip goes below certain threshold
function VRHand:Release() 

	--- drop any object currently in the hand
	-- must check if holding an item
	if self.HoldingObject == nil then return end


	-- we are no longer holding
	self.GripPoint.GripPoint.Value = false

	local obj = self.HoldingObject
	local object_meta = ItemMetadata[obj.Name]

	-- if class definition exists
	-- run OnRelease callback
	if object_meta and object_meta.class then
		object_meta.class:OnRelease(self, obj, self.GripPoint)
	end

	-- async wait .25 seconds
	-- must delay so hand and object's collisions don't 
	-- immediately get the two stuck inside each other
	-- then reset the collision mask on the held object
	delay(0.25, function() 
		CollisionGroupReset(obj) 
	end)

	-- TODO: check for special condition where virtualhand takes priority
--[[	if object_meta and object_meta.name == "Skorpion" then
		self._HandModelSoftWeld:Enable()
		self._HandWeld:Destroy()
		self._HandWeld = nil
	end]]

	-- if we created a weld (we most likely did)
	if self._GrabbedObjectWeld then
		self._GrabbedObjectWeld:Destroy()
		self._GrabbedObjectWeld = nil
	end

	-- inform server of our actions
	local crelease = Networking.GetNetHook("ClientRelease")
	crelease:FireServer(self.HoldingObject, self.GripPoint)

	-- reset our fields
	--
	self.HoldingObject = nil
	self.GripPoint = nil
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

	local reported_cframe = self.Head.VirtualHead.CFrame * self.OriginRelativeControllerPosition
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
	self.OriginRelativeControllerPosition = VRService:GetUserCFrame(self.UserCFrame)
end

return VRHand