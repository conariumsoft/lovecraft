_G.using "RBX.ReplicatedStorage"
_G.using "RBX.ReplicatedFirst"
_G.using "RBX.Workspace"
_G.using "RBX.VRService"
_G.using "RBX.HapticService"
_G.using "RBX.PhysicsService"
_G.using "Lovecraft.Physics"
_G.using "Lovecraft.Lib.RotatedRegion3"
_G.using "Lovecraft.Networking"
_G.using "Game.Data.ItemMetadata"
_G.using "Lovecraft.ItemInstances"

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

	self.ItemInstance = nil

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
	self._HandModelSoftWeld = Physics.CreatePointSolver(self.VirtualHand, self.HandModel.PrimaryPart, {
		pos_responsiveness = 125,
		rot_responsiveness = 40,
		pos_max_force = 10000,
		rot_max_torque = 10000,
		pos_max_velocity = 25000,
	})

	--[[self._HandModelSoftWeld = Physics.CreatePointSolver(self.VirtualHand, self.HandModel.PrimaryPart, {
		pos_responsiveness = 100,
		rot_responsiveness = 40,
		pos_max_force = 0,
		rot_max_torque = 0,
		pos_max_velocity = 0,
		
	})]]
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
		if self.ItemInstance then
			self.ItemInstance:OnTriggerState(self, grip_strength, self.GripPoint)
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
	for _, child in pairs(part:GetChildren()) do
		if child.Name == "GripPoint" and child.Value == false then
			return true
		end

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
	return Physics.CreatePointSolver(hand_part, grip_point, glue_config)
end

local function is_model_collision_group(model, group)
	for _, obj in pairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:CollisionGroupContainsPart(group, obj)
		end
	end
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
	local reported_pos = self.HandModel.PrimaryPart.CFrame
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
	notify_server_grab:FireServer(item_pickup, part, self.Handedness)

	part.GripPoint.Value = true
	-- assign some members. (what are these used for?)
	self.HoldingObject = item_pickup
	self.GripPoint = part

	--! We got the parameters _roughly_ figured out
	-- DO NOT CHANGE: change objects to fit around these from now on
	local grip_config = {
		--master_offset = self.VirtualHand.CFrame:inverse() * part.CFrame,
		follower_offset = part.CFrame:inverse() * self.HandModel.PrimaryPart.CFrame,
		rot_responsiveness = 100,
		rot_max_torque = 250,
		pos_max_force = 8000,
		pos_is_rigid = true,
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
				local inst = ItemInstances.GetClassInstance(item_pickup)
				if not inst then
					inst = ItemInstances.CreateClassInstance(item_pickup, obj_meta.class)
				end
				self.ItemInstance = inst
				inst:OnGrab(self, part)
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

	-- collision group..
	local other = (self.Handedness == "Left") and "Right" or "Left" --! giant weiner
	local is_other = is_model_collision_group(item_pickup, "Grabbed"..other)

	-- one is already attached
	if is_other then
		set_model_collision_group(item_pickup, "GrabbedBoth")
	else
		set_model_collision_group(item_pickup, "Grabbed"..self.Handedness)
	end

	-- firstly, disable hand->handmodel softweld.
	-----------------------------------------------------------------------
	-- ITEM WEIGHT CODE --
	

	-- finally, glue object to handmodel
	self._GrabbedObjectWeld = glue(self.HandModel.PrimaryPart, part, grip_config)
end


--- fired when hand grip goes below certain threshold
function VRHand:Release(forced) 

	--- drop any object currently in the hand
	-- must check if holding an item
	if self.HoldingObject == nil then return end
	-- we are no longer holding

	self.GripPoint.GripPoint.Value = false

	local obj = self.HoldingObject
	local object_meta = ItemMetadata[obj.Name]

	-- if class definition exists
	-- run OnRelease callback
	--if object_meta and object_meta.class then
	if self.ItemInstance then
		self.ItemInstance:OnRelease(self, self.GripPoint)
		self.ItemInstance = nil
	end
	--end


	--TODO: come up with fix
	-- async wait .25 seconds
	-- must delay so hand and object's collisions don't 
	-- immediately get the two stuck inside each other
	-- then reset the collision mask on the held object
	delay(0.25, function() 
		local is_us = is_model_collision_group(obj, "Grabbed"..self.Handedness)
		local is_both  = is_model_collision_group(obj, "GrabbedBoth")

		-- one is already attached
		if is_both then
			
			-- set to other?
			local other = (self.Handedness == "Left") and "Right" or "Left" --! giant weiner
			print("back to "..other)
			set_model_collision_group(obj, "Grabbed"..other)
		elseif is_us then
			print("last grip")
			set_model_collision_group(obj, "Interactives")
		end

	end)
	if self._GrabbedObjectWeld then
		self._GrabbedObjectWeld:Destroy()
		self._GrabbedObjectWeld = nil
	end

	-- inform server of our actions
	local crelease = Networking.GetNetHook("ClientRelease")
	crelease:FireServer(self.HoldingObject, self.GripPoint, self.Handedness)

	-- reset our fields
	self.HoldingObject = nil
	self.GripPoint = nil
end
---
function VRHand:Update(dt)

	if self.HoldingObject ~= nil and self.ItemInstance then
	
		--local object_meta = ItemMetadata[self.HoldingObject.Name]
	--	if object_meta and object_meta.class then
			self.ItemInstance:OnSimulationStep(self, dt, self.GripPoint)
	--	end
	end

	self.LastHandPosition = self.HandPosition

	local reported_cframe = self.Head.VirtualHead.CFrame * self.OriginRelativeControllerPosition
	self.HandPosition = reported_cframe
	self.VirtualHand.CFrame = reported_cframe

	-- TODO: optimize
	local hand_from_virtual_distance = (self.VirtualHand.Position - self.HandModel.PrimaryPart.Position).magnitude
	
	if hand_from_virtual_distance > 0.25 then
		self:SetRumble(hand_from_virtual_distance/8)
	else
		self:SetRumble(0)
	end

	if _G.VR_DEBUG then return end
	self.OriginRelativeControllerPosition = VRService:GetUserCFrame(self.UserCFrame)
end

function VRHand:GetGoalCFrame()
	return self.Head.VirtualHead.CFrame * self.OriginRelativeControllerPosition
end

return VRHand