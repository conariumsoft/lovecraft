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

local function hand_attachment_part()
	local hgp = Instance.new("Part") do
		hgp.Anchored = true
		hgp.CanCollide = false
		hgp.Transparency = 0.25
		hgp.Color = Color3.new(0, 1, 1)
		hgp.Size = Vector3.new(0.1, 0.1, 0.1)
		hgp.Parent = game.Workspace
		hgp.Name = "HandAttachmentPart"
	end
	
	return hgp
end



--- VR Hand Base class. 
local VRHand = _G.newclass("VRHand")
---
-- @name VRHand:new()
function VRHand:__ctor(data) --player, vr_head, handedness, hand_model)

	self.Haptics        = data.HapticMotorList -- list of detected rumble motors
	self.UserCFrameEnum = data.VREnum
	self.Handedness     = data.Handedness
	self.Player			= data.Player
	self.HandModel		= data.Model

	self.GoalCFrame       = CFrame.new(0,0,0) -- where the hand will be pushed to...
	self.SolvedGoalCFrame = CFrame.new(0, 0, 0)
	self.OriginCFrame     = CFrame.new(0, 0, 0) -- cam origin?
	self.RelativeCFrame   = CFrame.new(0, 0, 0)
	self.DebugCFrame	  = CFrame.new(0, 0, 0)
 
	self.IsGripped = true
	self.IndexFingerPressure = 0
	self.GripPressure = 0
	self.Anims = {} -- anim list? (make static anim list?)
	self.CurrentAnim = nil


	self.RecoilCorrectionCFrame = CFrame.new(0, 0, 0)
	
	self.ItemInstance = nil

	local hgp = hand_attachment_part()
	local hgp_attachment = Instance.new("Attachment")
	hgp_attachment.Parent = hgp

	self.HandGoalPart = hgp
	
	-- glue weld that binds hand to correct position and orientation,
	-- while still respecting physical limits
	self._HandModelSoftWeld = Physics.PointSolver:new(hgp_attachment, self.HandModel.PrimaryPart.Attachment, {
		pos_responsiveness = 100,
		rot_responsiveness = 100,
		pos_max_force      = 5000,
		rot_max_torque     = 3000,
		pos_max_velocity   = 100000,
	})


	self._CollisionMask = nil

	-- used later
	self._GrabbedObjectWeld = nil -- hand->held object glue
	self.HoldingObject = nil -- if grabbed something
	self.GripPoint = nil -- which point on an object did we grab?
	
	-- confirm replication of Animator (or else animations will not replicate back to server)
	self.Animator = self.HandModel.Animator
	self:_LoadAnimationTracks()

	local highlight = Instance.new("Part") do
		highlight.Size = Vector3.new(0.3, 0.3, 0.3)
		highlight.Shape = Enum.PartType.Ball
		highlight.Parent = Workspace
		highlight.Anchored = true
		highlight.CanCollide = false
		highlight.Color = Color3.new(0.25, 0.25, 1)
		highlight.Material = Enum.Material.ForceField
		highlight.Transparency = 0
	end

	self.HighlightPart = highlight
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
	self.GoalCFrame = coord
	self.SolvedGoalCFrame = coord
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
		if key == name then return val end
	end
end
--
function VRHand:GetAnim(name) return self.Anims[name] end
--
function VRHand:PlayAnim(anim_track, fade_time, weight, speed)
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
		anim.TimePosition = anim.Length * math.min(timescale, .99) --! do not let reach 1, it will break
	end
end
------------------------------------------------------------------------------

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

function VRHand:SetGripCurl(grip_strength)
	self.GripPressure = grip_strength
	self:SetAnimTimeScale("Grip", grip_strength)
end


-- TODO: move these to their own helper module
local function is_model_collision_group(model, group)
	for _, obj in pairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			if PhysicsService:CollisionGroupContainsPart(group, obj) == false then
				return false
			end
		end
	end
	return true
end

-- TODO: move these to their own helper module
local function set_model_collision_group(model, group)
	for _, obj in pairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(obj, group)
		end
	end
end

---
function VRHand:Grab()
	local part = self:GetClosestInteractive()

	if part == nil then return end -- exit early if nothing to grab
	local item_model = part.Parent


	-- tell server what we're up to (picking something up)
	local notify_server_grab = Networking.GetNetHook("ClientGrab")
	notify_server_grab:FireServer(item_model, part, self.Handedness)

	part.GripPoint.Grabbed.Value = true

	self.HoldingObject = item_model
	self.GripPoint = part

	local collision_filter  = Instance.new("NoCollisionConstraint")
	collision_filter.Parent = self.HandModel.PrimaryPart
	collision_filter.Part0  = self.HandModel.PrimaryPart
	collision_filter.Part1  = part

	self._CollisionMask = collision_filter
	
	local hold_offset_cf = part.CFrame:inverse() * self.HandModel.PrimaryPart.CFrame

	-- object's Model.Name is used to search.
	-- using metadata to configure how hand welds to model
	local obj_meta = ItemMetadata[item_model.Name]

	-- found no metadata -> assume default properties
	-- (most likely non-functional prop or scenery, needs no custom anim or grip style)
	if obj_meta then
		-- grip_data table contains def 
		if obj_meta.grip_data then
			-- class is optional value
			-- defines item functionality
			if obj_meta.class then
				local inst = ItemInstances.GetClassInstance(item_model)
				if not inst then
					inst = ItemInstances.CreateClassInstance(item_model, obj_meta.class)
				end
				self.ItemInstance = inst
				inst:OnGrab(self, part)
			end
			-- if grip data is missing for this
			-- piece, assume "Anywhere" grip style
			local gripinformation = obj_meta.grip_data[part.Name]

			if gripinformation then
				hold_offset_cf = gripinformation.Offset


				if gripinformation:isA("GripPoint") then
					self.HandModel.PrimaryPart.CFrame = part.CFrame
				end
			end
		end
	end
	-- correct attachment CFrame
	part.GripPoint.CFrame = hold_offset_cf


	-------------------------------------------------
	-- collision group solving?
	local is_not_yet = is_model_collision_group(item_model, "Interactives")

	-- one is already attached
	--[[if is_not_yet then
		print("Grabbed"..self.Handedness)
		set_model_collision_group(item_model, "Grabbed"..self.Handedness)
	else
		print("GrabbedBoth")
		set_model_collision_group(item_model, "GrabbedBoth")
	end]]
	-------------------------------------------------

	-- last step, weld together
	local weld = Instance.new("WeldConstraint") do
		weld.Part1 = part
		weld.Part0 = self.HandModel.PrimaryPart
		weld.Parent = part
	end
	self._GrabbedObjectWeld = weld
end



--- fired when hand grip goes below certain threshold
function VRHand:Release(forced) 

	--- drop any object currently in the hand
	-- must check if holding an item
	if self.HoldingObject == nil then return end
	-- we are no longer holding

	self.GripPoint.GripPoint.Grabbed.Value = false
	local obj = self.HoldingObject
	local object_meta = ItemMetadata[obj.Name]

	-- if class definition exists
	-- run OnRelease callback
	if self.ItemInstance then
		self.ItemInstance:OnRelease(self, self.GripPoint)
		self.ItemInstance = nil
	end

	-- TODO: come up with fix
	-- async wait .25 seconds, must delay so hand and object's collisions don't 
	-- immediately get the two stuck inside each other, then reset the collision mask on the held object
	delay(0.25, function() 

		self._CollisionMask:Destroy()

	-- COLLISION GROUP METHOD: DO NOT LIKE!

	--[[	local is_us = is_model_collision_group(obj, "Grabbed"..self.Handedness)
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
		end]]

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




function VRHand:GetClosestInteractive(min_distance)
	local closest_part = nil
	local closest_dist = math.huge
	min_distance = min_distance or 1

	for _, part in pairs(Workspace.Physical:GetDescendants()) do
		if part:FindFirstChild("GripPoint") then
			local dist = (part.Position - self.HandModel.PrimaryPart.Position).magnitude
			if dist < min_distance and dist < closest_dist then
				closest_part = part
			end
		end
	end
	return closest_part
end

function VRHand:HighlightSphere(part)
	-- reset
	if part == nil then
		self.HighlightPart.CFrame = CFrame.new(0, 9999999, 0)
		return
	end

	self.HighlightPart.CFrame = CFrame.new(part.Position)

	local largest_axis = math.max(part.Size.X, part.Size.Y, part.Size.Z)
	self.HighlightPart.Size = Vector3.new(largest_axis+0.1, largest_axis+0.1, largest_axis+0.1)
end

---
function VRHand:Update(dt)
	local closest = self:GetClosestInteractive()


	-- highlight closest manipulatable object
	self:HighlightSphere(closest)
	--end


	self.RelativeCFrame = VRService:GetUserCFrame(self.UserCFrameEnum)

	if self.ItemInstance then
		self.ItemInstance:OnSimulationStep(self, dt, self.GripPoint)
	end

	self.HandGoalPart.CFrame = self.SolvedGoalCFrame
	local vrhand_goal_cframe = self.SolvedGoalCFrame

	-- TODO: optimize
	local hand_from_virtual_distance = (vrhand_goal_cframe.p - self.HandModel.PrimaryPart.Position).magnitude
	
	if hand_from_virtual_distance > 0.25 then
		self:SetRumble(hand_from_virtual_distance/8)
	else
		self:SetRumble(0)
	end
	
end

return VRHand