local BaseInteractive = require(script.Parent.BaseInteractive)

local BaseFirearm = BaseInteractive:subclass("BaseFirearm")

BaseFirearm.TriggerStiffness = 0.95
BaseFirearm.RateOfFire = 850
BaseFirearm.MuzzleFlipMax = 1500
BaseFirearm.MuzzleFlipMin = 50
BaseFirearm.YShakeMin = -15
BaseFirearm.YShakeMax = 15
BaseFirearm.ZShakeMin = -10
BaseFirearm.ZShakeMax = 10
BaseFirearm.RecoilRecoverySpeed = 2
BaseFirearm.BoltTravelDistance = 0.2
BaseFirearm.BarrelComponent = nil
BaseFirearm.MagazineComponent = nil
BaseFirearm.BoltComponent = nil
BaseFirearm.MagazineType = nil
BaseFirearm.Automatic = false

--[[
BaseFirearm.RoundInChamber = true
BaseFirearm.MagazineInserted = true
BaseFirearm.MagazineRoundCount = 30

BaseFirearm.Timer = 0

BaseFirearm.OpenBolt = false
BaseFirearm.BoltGrabbed = false
]]
-- this blows, but we just need to get guns working for now.

local animation_track = nil

function BaseFirearm:__ctor(...)
    BaseInteractive.__ctor(self, ...)
    self.Timer = 0
    self.RoundInChamber = true
    self.MagazineInserted = true
    self.MagazineRoundCount = 30
    self.BoltGrabbed = false
    self.TriggerPressed = false
end

------------------------------------------------
-- Various Methods
function BaseFirearm:GetCycleTime()
    return self.RateOfFire/60
end
-------------------------------------------------------
-- Handle (Trigger Group) Functionality
function BaseFirearm:HandleOnGrab(hand)
    print("Handle grabbed!")
    if animation_track == nil then

        animation_track = self.Model.AnimationController:LoadAnimation(self.Model.slideBack)
        animation_track.Priority = Enum.AnimationPriority.Core
        print("Initial Anim Load:", animation_track)
    end
    local barrel = self.Model[self.BarrelComponent]
    local magazine = self.Model[self.MagazineComponent]


    --barrel.CFrame = barrel.CFrame * CFrame.Angles(math.rad(5), 0, 0)

    local muzzle_flip = Instance.new("BodyThrust") do
        muzzle_flip.Name = "MuzzleFlip"
        muzzle_flip.Location = Vector3.new(0, 0, 0)
        muzzle_flip.Force = Vector3.new(0, 0, 0)
        muzzle_flip.Parent = barrel
    end
    local recoil_impulse = Instance.new("BodyThrust") do
        recoil_impulse.Name = "RecoilImpulse"
        recoil_impulse.Location = Vector3.new(0, 0, 0)
        recoil_impulse.Parent = barrel
        recoil_impulse.Force = Vector3.new(0, 0, 0)
    end
end

function BaseFirearm:HandleOnRelease(hand)
    print("Handle Released")
    local barrel = self.Model[self.BarrelComponent]
    if barrel:FindFirstChild("MuzzleFlip") then
        barrel.MuzzleFlip:Destroy()
    end

    if barrel:FindFirstChild("RecoilImpulse") then
        barrel.RecoilImpulse:Destroy()
    end
    
end
---------------------------------------------------

function BaseFirearm:MagazineOnGrab(hand)
    print("Magazine Grabbed!")
end

function BaseFirearm:MagazineOnRelease(hand)
    print("Magazine released!")
    self:HandleOnRelease(hand)
    self:HandleOnGrab(hand)
end
------------------------------------------------------
function BaseFirearm:ChargingHandleOnGrab(hand)
    print("ChargingHandle grabbed")
    self.BoltGrabbed = true
end

function BaseFirearm:ChargingHandleOnRelease(hand)
    print("ChargingHandle released")
    if self.MagazineInserted and self.RoundInChamber == false then
        self.RoundInChamber = true
        self.MagazineRoundCount = self.MagazineRoundCount - 1
        animation_track:Play()
        animation_track:AdjustSpeed(1)
        -- TODO: sound fx
        -- TODO: remove charginghandle grip point
    end
end
--------------------------------------------------------------


function BaseFirearm:FireProjectile(hand, grip_point)
    if grip_point.Name == "Handle" then
        local barrel = self.Model[self.BarrelComponent]
        local coach_ray = Ray.new(barrel.CFrame.p, barrel.CFrame.rightVector*200)
        local hit, pos = game.Workspace:FindPartOnRay(coach_ray, self.Model)

        if hit then
            if hit.Parent:FindFirstChild("Humanoid") then
                hit.Parent.Humanoid.Health = hit.Parent.Humanoid.Health - 100
                for _, obj in pairs(hit.Parent:GetDescendants()) do
                        
                    if obj:IsA("WeldConstraint") then obj:Destroy() end
                end
            end
        end

        local bullet_impact = Instance.new("Part") do
            bullet_impact.Color = Color3.new(1, 0, 0)
            bullet_impact.Shape = Enum.PartType.Ball
            bullet_impact.Transparency = 0.25
            bullet_impact.Size = Vector3.new(0.075, 0.075, 0.075)
            bullet_impact.Anchored = true
            bullet_impact.CanCollide = false
            bullet_impact.CFrame = CFrame.new(pos)
            bullet_impact.Parent = game.Workspace
        end
    end
end
--[[
    a groan
    of tedium escapes me
    startling the fearful
    is this a test?
    it has to be
    otherwise I can't go on
    draining patience, claimed vitality
]]
function BaseFirearm:Fire(hand, grip_point)
    local barrel = self.Model[self.BarrelComponent]
    local bolt = self.Model[self.BoltComponent]

    self.Model.fire:Stop()
    self.Model.fire.TimePosition = 0.05
    self.Model.fire:Play()

    -- bolt anim
    animation_track:Stop()
    animation_track:Play()
    animation_track.TimePosition = 0
    animation_track:AdjustSpeed(1)

    if self.RoundInChamber == false then
        animation_track:AdjustSpeed(0)
        animation_track.TimePosition = (animation_track.Length * 0.25)
    end
    --

    self.Model:SetPrimaryPartCFrame(
        self.Model:GetPrimaryPartCFrame() * CFrame.new(0, 0, 2)
    )
   -- self:ApplyRecoilImpulse(hand, grip_point)
    self:FireProjectile(hand, grip_point)

    barrel.BillboardGui.Enabled = true
    barrel.BillboardGui.ImageLabel.Rotation = math.random(0, 360)
    delay(1/20, function()
        barrel.BillboardGui.Enabled = false
    end)
end

function BaseFirearm:ClientFireEffects(hand, grip_point)

end

function BaseFirearm:ApplyRecoilImpulse(hand, grip_point)
    local barrel = self.Model[self.BarrelComponent]
    -- TODO: Backwards recoil!
    local recoil_impulse = barrel.RecoilImpulse

    --muzzle_flip.Force = Vector3.new(0, 0, 50)
    recoil_impulse.Force = Vector3.new(
        -math.max(  self.MuzzleFlipMin, self.MuzzleFlipMax), 
        math.random(self.YShakeMin,     self.YShakeMax    ), 
        math.random(self.ZShakeMin,     self.ZShakeMax    )
    )

    delay(1/self.RecoilRecoverySpeed, function()
        recoil_impulse.Force = Vector3.new(0, 0, 0)
    end)
end

function BaseFirearm:TriggerDown(hand, dt, grip_point)
    
    if self.Automatic ~= true then
        if self.TriggerPressed then return end
        self.Timer = 1/self:GetCycleTime()
    end

    self.Timer = self.Timer + dt
    if self.Timer >= (1/self:GetCycleTime()) and self.RoundInChamber then
        self.Timer = self.Timer - (1/self:GetCycleTime())

        self.MagazineRoundCount = self.MagazineRoundCount - 1

        if self.MagazineRoundCount == 0 then
            self.RoundInChamber = false
        end

        self:Fire(hand, grip_point)
    end
end

function BaseFirearm:OnMagazineInsert(magazine)
     print("Magazine Inserted")
    self.MagazineInserted = true
    self.MagazineRoundCount = 30--magazine.Rounds.Value

    self.Model[self.MagazineComponent].Transparency = 0
    magazine.Parent = nil

    if self.Model[self.MagazineComponent]:FindFirstChild("GripPoint") == nil then
        local mag_gp = Instance.new("BoolValue") do
            mag_gp.Name = "GripPoint"
            mag_gp.Parent = self.Model[self.MagazineComponent]
        end
    end
end

function BaseFirearm:OnMagazineRemove(hand)
    print("Magazine Removed")
    hand:Release()
    self.MagazineInserted = false

    self.Model[self.MagazineComponent].GripPoint:Destroy()
    self.Model[self.MagazineComponent].Transparency = 1
end

---------------------------------
-- External API-Hook methods
function BaseFirearm:OnGrab(hand, grip_point)

    -- delete folder?
    if not self.Model:FindFirstChild("Data") then
        local folder = Instance.new("Folder")
        folder.Name = "Data"
        folder.Parent = self.Model
    end

    local g = grip_point.Name
    if     g == "Handle"         then self:HandleOnGrab(hand)
    elseif g == "Magazine"       then self:MagazineOnGrab(hand)
    elseif g == "ChargingHandle" then self:ChargingHandleOnGrab(hand) 
    end
end

function BaseFirearm:OnRelease(hand, grip_point)
    print("Stinky part 300 and 34")
    local gp = grip_point.Name
    if     gp == "Handle"         then self:HandleOnRelease(hand)
    elseif gp == "Magazine"       then self:MagazineOnRelease(hand)
    elseif gp == "ChargingHandle" then self:ChargingHandleOnRelease(hand)
    end
end

function BaseFirearm:OnSimulationStep(hand, dt, grip_point)
    local magazine = self.Model[self.MagazineComponent]

    local mag_well = self.Model.MagazineCorrect

    for _, part in pairs(mag_well:GetTouchingParts()) do
        if part.Parent.Name == self.MagazineType then
            self:OnMagazineInsert(part.Parent)
        end
    end

    if grip_point.Name == "Handle" then
        if hand.IndexFingerPressure > self.TriggerStiffness then
            self:TriggerDown(hand, dt, grip_point)
            self.TriggerPressed = true
        end

        
        if hand.IndexFingerPressure < 0.25 then
            self.TriggerPressed = false
        end
    end

    if grip_point.Name == "Magazine" then
        if self.MagazineInserted and hand.IndexFingerPressure > 0.95 then
            self:OnMagazineRemove(hand)
        end
    end

    if grip_point.Name == "ChargingHandle" then
       -- print("Holding ChargingHandle!")
    end
end

function BaseFirearm:OnTriggerState(hand, finger_pressure, grip_point)
end

return BaseFirearm