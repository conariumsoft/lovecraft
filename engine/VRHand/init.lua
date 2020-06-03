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
_G.using "RBX.RunService"


local function hand_attachment_part()
	local hgp = Instance.new("Part") do
		hgp.Anchored = true
		hgp.CanCollide = false
		if RunService:IsStudio() then
			hgp.Transparency = 0.25
		else
			hgp.Transparency = 1
		end
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
	self.GoalCFrame       		= CFrame.new(0,0,0) -- where the hand will be pushed to...
	self.SolvedGoalCFrame 		= CFrame.new(0, 0, 0)
	self.OriginCFrame     		= CFrame.new(0, 0, 0) -- cam origin?
	self.RelativeCFrame   		= CFrame.new(0, 0, 0)
	self.DebugCFrame	 	    = CFrame.new(0, 0, 0)
	self.RecoilCorrectionCFrame = CFrame.new(0, 0, 0)
	self.Anims = {} -- anim list? (make static anim list?)
	self.CurrentAnim        = nil
	self.ItemInstance       = nil
	self._CollisionMask     = nil
	self._GrabbedObjectWeld = nil -- hand->held object glue
	self.HoldingObject      = nil -- if grabbed something
	self.GripPoint          = nil -- which point on an object did we grab?
	self.IsGripped = true
	self.PointerState = 0
	self.GripState = 0
	self.Grabbing = false

	local hgp = hand_attachment_part()
	local hgp_attachment = Instance.new("Attachment")
	hgp_attachment.Parent = hgp

	self.HandGoalPart = hgp
	
	-- glue weld that binds hand to correct position and orientation, while still respecting physical limits
	self._HandModelSoftWeld = Physics.PointSolver:new(hgp_attachment, self.HandModel.PrimaryPart.Attachment, {
		pos_responsiveness = 100,
		rot_responsiveness = 100,
		pos_max_force      = 3000,
		rot_max_torque     = 3000,
		pos_max_velocity   = 5000,
	})

	-- confirm replication of Animator (or else animations will not replicate back to server)
	self.Animator = self.HandModel.Animator
	self:_LoadAnimationTracks()

	local highlight = Instance.new("SelectionSphere") do
		highlight.SurfaceTransparency = 0.75
		highlight.Transparency = 1
		highlight.SurfaceColor3 = Color3.new(1,1,1)
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

function VRHand:Grab()
	self.Grabbing = true
end

--- fired when hand grip goes below certain threshold
function VRHand:Release()
	self.Grabbing = false
	--- drop any object currently in the hand & must check if holding an item
	
	if not self.HoldingObject then return end
	
	delay(0.25, function() self._CollisionMask:Destroy() end) -- delay a bit so physics dont spaz
	-- if class definition exists run OnRelease callback
	if self.ItemInstance then
		self.ItemInstance:OnRelease(self, self.GripPoint)
		self.ItemInstance = nil
	end

	if self._GrabbedObjectWeld then
		self._GrabbedObjectWeld:Destroy()
		self._GrabbedObjectWeld = nil
	end

	-- inform server of our actions
	local crelease = Networking.GetNetHook("ClientRelease")
	crelease:FireServer(self.HoldingObject, self.GripPoint, self.Handedness)
	self.HoldingObject = nil -- reset our fields
	self.GripPoint = nil
end

function VRHand:GetClosestInteractive(min_distance)
	local closest_part = nil
	local closest_dist = math.huge
	min_distance = min_distance or 3

	for _, part in pairs(Workspace.Physical:GetDescendants()) do
		if part:FindFirstChild("GripPoint") then
			
			local dist = (part.Position - self.HandModel.PrimaryPart.Position).magnitude
			if dist < min_distance and dist < closest_dist then
				-- vector must be flipped for right hand
				local flip = (self.Handedness == "Left") and 1 or -1

				local ray = Ray.new(self.HandModel.PrimaryPart.Position, flip*self.HandModel.PrimaryPart.CFrame.rightVector)
				local hit, pos, sfnormal = Workspace:FindPartOnRayWithWhitelist(ray, {part})
				if hit and hit == part then
					closest_part = part
				end
			end
		end
	end
	return closest_part
end

function VRHand:ItemGrab()
	local part = self:GetClosestInteractive()

	if part == nil then return end -- exit early if nothing to grab

	local ray = Ray.new(self.HandModel.PrimaryPart.Position, (part.Position - self.HandModel.PrimaryPart.Position).unit) -- look at part from point of hand

	local hit, pos, sfnormal = Workspace:FindPartOnRayWithWhitelist(ray, {part})
	if hit ~= part then return end

	local item_model = part.Parent

	local notify_server_grab = Networking.GetNetHook("ClientGrab") -- tell server what we're up to (picking something up)
	notify_server_grab:FireServer(item_model, part, self.Handedness)

	part.GripPoint.Grabbed.Value = true

	self.HoldingObject = item_model
	self.GripPoint = part

	local collision_filter  = Instance.new("NoCollisionConstraint")
	collision_filter.Parent = self.HandModel.PrimaryPart
	collision_filter.Part0  = self.HandModel.PrimaryPart
	collision_filter.Part1  = part

	self._CollisionMask = collision_filter
	
	-- object's Model.Name is used to search.
	-- using metadata to configure how hand welds to model
	local obj_meta = ItemMetadata[item_model.Name]

	-- if found no metadata -> assume default properties
	-- (most likely non-functional prop or scenery, needs no custom anim or grip style)
	if obj_meta and  obj_meta.class then 
		local inst = ItemInstances.GetClassInstance(item_model) or
			ItemInstances.CreateClassInstance(item_model, obj_meta.class)

		self.ItemInstance = inst
		inst:OnGrab(self, part)

		-- Special condition for foregrip guns
	end

	self.HandModel.PrimaryPart.CFrame = CFrame.new(pos)*(self.HandModel.PrimaryPart.CFrame - self.HandModel.PrimaryPart.CFrame.Position)

	if obj_meta and obj_meta.grip_data then
		-- look for custom cframe
		local gripinformation = obj_meta.grip_data[part.Name]

		if gripinformation and gripinformation:isA("GripPoint") and gripinformation.Offset then
			self.HandModel.PrimaryPart.CFrame = part.CFrame * gripinformation.Offset
		end
	end
	
	local weld = Instance.new("WeldConstraint") do -- last step, weld together
		weld.Part1 = part
		weld.Part0 = self.HandModel.PrimaryPart
		weld.Parent = part
	end
	self._GrabbedObjectWeld = weld
end

function VRHand:HighlightSphere(part)
	-- reset
	if part == nil then
		self.HighlightPart.Parent = nil
		return
	end

	self.HighlightPart.Adornee = part
	self.HighlightPart.Parent = part
end
---
function VRHand:Update(dt)

	self:SetAnimTimeScale("Grip", self.GripState)
	self:SetAnimTimeScale("Index", self.PointerState)
	-- TODO: thumb

	self:HighlightSphere(self:GetClosestInteractive()) -- highlight closest manipulatable object
	self.RelativeCFrame = VRService:GetUserCFrame(self.UserCFrameEnum)

	if self.ItemInstance then self.ItemInstance:OnSimulationStep(self, dt, self.GripPoint) end

	if self.Grabbing == true and self.HoldingObject == nil then
		self:ItemGrab()
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