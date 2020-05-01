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

-- TODO: developer modefff
-- telekensis
-- work on multiplayer
-- make the mechanicsms of the system more transparent (less guessing about what's going on!)

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
	--self.HandModel.Parent = Workspace.LocalVRModels
	
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
		rot_responsiveness = 50,
	})
	self._GrabbedObjectWeld = nil
	
	self.Animator = self.HandModel.Animator
	self:_LoadAnimationTracks()
end

function VRHand:_LoadAnimationTracks()
	for _, anim in pairs(ReplicatedStorage.Animations[self.Handedness]:GetChildren()) do
		local track = self.Animator:LoadAnimation(anim)
		--track.Parent = self.Animator
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
	local anim = self:GetAnim("Index")
	if anim then
		anim.TimePosition = anim.Length * math.min(grip_strength, .99)
	end
end

---
function VRHand:SetGripCurl(grip_strength)
	self.GripPressure = grip_strength
	local anim = self:GetAnim("Grip")
	if anim then
		anim.TimePosition = anim.Length * math.min(grip_strength, .99)
	end
end

local DEBUG_SHOW_HAND_CFRAME = true

function VRHand:_HandleObjectPickup(object, grip_point)

	-- Parse item metadata to apply correct offset, grip type, and animations etc.

	self.HoldingObject = object
	self.GripPoint = grip_point

	local object_meta = ItemMetadata[object]

	local grip_cf_offset, grip_ps_reactive, grip_ps_force

	if object_meta then
		print("object metadata found!")
		if object_meta.grip_type == "Anywhere" then
			-- preserve orientation of hand relative to object at time of grab
			grip_cf_offset = self.HandModel.PrimaryPart.CFrame:inverse() * grip_point.CFrame
		end
	
		if object_meta.grip_type == "GripPoint" then
			-- object_meta.grip_data should exist

			if not object_meta.grip_data then
				error("Object Metadata must contain a grip_data table if object grip_type is set to 'GripPoint' :" .. object_meta.Name)
			end
			if object_meta.grip_data[grip_point.Name] then
				grip_cf_offset = object_meta.grip_data[grip_point.Name].offset
			end
		end
		if object_meta.class then
			object_meta.class:OnHandGrab(self, self.HoldingObject, self.GripPoint)
		end
	else
		grip_cf_offset = self.HandModel.PrimaryPart.CFrame:inverse() * grip_point.CFrame
	end
	-- if no object meta, assume "Anywhere"

	for _, obj in pairs(self.HoldingObject:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(obj, "Grabbed"..self.Handedness)
		end
	end

	--grip_point.GripPoint.Value = true
	
	if grip_point.Anchored == true then
		grip_ps_reactive = true
		grip_ps_force = 1000000
	end

	if object.Name == "Environment" then
		grip_ps_reactive = true
		grip_ps_force = 1000000
	end

	-- master and follower part, respectively
	--self.HoldingObject:SetPrimaryPartCFrame(self.Head.CFrame * VRService:GetUserCFrame(self.UserCFrame))	
	self._GrabbedObjectWeld = SoftWeld:new(self.HandModel.PrimaryPart, grip_point, {
		-- TODO: custom props?
		cframe_offset = grip_cf_offset,
		pos_is_reactive = grip_ps_reactive,
		pos_max_force = grip_ps_force

	})
	-- TODO: create sanity checks for indexing metadata list	
end
---
function VRHand:Grab()
	local reported_pos = self.VirtualHand.CFrame
	
	local region = RotatedRegion3.new(
		reported_pos,
		Vector3.new(1,1,1) -- region radius
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
			print("hasgrip: "..v.Name)
			if v.GripPoint.Value == false then -- item hasn't been grabbed yet, so this hand will grab
				print("cangrip: "..v.Name)
				-- this hand is now primary grip
				local cgrab = Networking.GetNetHook("ClientGrab")
				cgrab:FireServer(v.Parent, v)
				self:_HandleObjectPickup(v.Parent, v)
				return
			end
		end
	end
end

local function CollisionGroupReset(model)
	for _, obj in pairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(obj, "Interactives")
		end
	end
end

---
function VRHand:Release() 
	-- TODO: play anim?
	if self.HoldingObject ~= nil then
		--self.GripPoint.GripPoint.Value = false
		local object_meta = ItemMetadata[self.HoldingObject.Name]

		if object_meta and object_meta.class then
			object_meta.class:OnHandRelease(self, self.HoldingObject, self.GripPoint)
		end

		local obj = self.HoldingObject
		delay(1, function()
			CollisionGroupReset(obj)
		end)
		self._GrabbedObjectWeld:Destroy()
		self._GrabbedObjectWeld = nil
		self.HoldingObject.PrimaryPart.Velocity = self.HoldingObject.PrimaryPart.Velocity * 2

		local crelease = Networking.GetNetHook("ClientRelease")
		crelease:FireServer(self.HoldingObject, self.GripPoint)
		self.HoldingObject = nil
		self.GripPoint = nil
		
	end
end
---
function VRHand:Update(dt)

	if self.HoldingObject ~= nil then
	
		local object_meta = ItemMetadata[self.HoldingObject.Name]
		if object_meta and object_meta.class then
			object_meta.class:OnHeldStep(self, self.HoldingObject, dt, self.GripPoint)
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