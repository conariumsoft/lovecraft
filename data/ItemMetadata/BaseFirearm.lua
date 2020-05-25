_G.using "Lovecraft.Networking"

local BaseInteractive = require(script.Parent.BaseInteractive)

local BaseFirearm = BaseInteractive:subclass("BaseFirearm") do
    BaseFirearm.TriggerStiffness = 0.95
    BaseFirearm.RateOfFire = 850
    BaseFirearm.RecoilRecoverySpeed = 2
    BaseFirearm.BoltTravelDistance = 0.2
    BaseFirearm.BarrelComponent = nil
    BaseFirearm.MagazineComponent = nil
    BaseFirearm.BoltComponent = nil
    BaseFirearm.MagazineType = nil
    BaseFirearm.Automatic = false
    BaseFirearm.Recoil = {
        XMoveMax = 0.05,
        XMoveMin = -0.05,
        YMoveMin = 0,
        YMoveMax = 0,
        ZMoveMin = 0,
        ZMoveMax = 0,
        XTiltMin = 0,
        XTiltMax = 0,
        YTiltMin = 0,
        YTiltMax = 0,
        ZTiltMin = 0,
        ZTiltMax = 0,
    }
end

-- this blows, but we just need to get guns working for now.

local animation_track = nil

function BaseFirearm:__ctor(...)
    BaseInteractive.__ctor(self, ...)
    self.Timer = 1
    self.RoundInChamber = true
    self.MagazineInserted = true
    self.MagazineRoundCount = 999-- put back to nominal values later
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

function BaseFirearm:MagazineOnGrab(hand) end

function BaseFirearm:MagazineOnRelease(hand) end
------------------------------------------------------
function BaseFirearm:ChargingHandleOnGrab(hand)
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

function BaseFirearm:Fire(hand, grip_point)
    local cf_reflect = Networking.GetNetHook("ClientShoot")
    cf_reflect:FireServer(self.Model)
    local barrel = self.Model[self.BarrelComponent]
    local bolt = self.Model[self.BoltComponent]

    self.Model.Fire:Stop()
    self.Model.Fire.TimePosition = 0.05
    self.Model.Fire:Play()

    barrel.PointLight.Enabled = true

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

    --[[self.Model:SetPrimaryPartCFrame(
        self.Model:GetPrimaryPartCFrame() * CFrame.new(0, 0, 2)
    )]]
    self:ApplyRecoilImpulse(hand, grip_point)
    self:FireProjectile(hand, grip_point)

    barrel.BillboardGui.Enabled = true
    barrel.BillboardGui.ImageLabel.Rotation = math.random(0, 360)
    delay(1/20, function()
        
        barrel.BillboardGui.Enabled = false
    end)
    delay(1/10, function()
        barrel.PointLight.Enabled = false
    end)
end

function BaseFirearm:ClientFireEffects(hand, grip_point)

end

local scale = 1000
function BaseFirearm:ApplyRecoilImpulse(hand, grip_point)
    local recoil = self.Recoil -- recoil profile
    local xmove = math.random(recoil.XMoveMin*scale, recoil.XMoveMax*scale)/scale
    local ymove = math.random(recoil.YMoveMin*scale, recoil.YMoveMax*scale)/scale
    local zmove = math.random(recoil.ZMoveMin*scale, recoil.ZMoveMax*scale)/scale
    local xtilt = math.random(recoil.XTiltMin*scale, recoil.XTiltMax*scale)/scale -- Pitch
    local ytilt = math.random(recoil.YTiltMin*scale, recoil.YTiltMax*scale)/scale -- Yaw
    local ztilt = math.random(recoil.ZTiltMin*scale, recoil.ZTiltMax*scale)/scale -- Roll
    hand.RecoilCorrectionCFrame = hand.RecoilCorrectionCFrame 
     
     * CFrame.new(xmove, ymove, zmove)
     * CFrame.Angles(math.rad(xtilt), math.rad(ytilt), math.rad(ztilt)) 


    local cam_rattle = math.random(recoil.CamRattle*scale, recoil.CamRattle*scale)/scale
    local cam_jolt   = math.random(-recoil.CamJolt*scale, recoil.CamJolt*scale)/scale
    local cam_kick   = math.random(recoil.MinKick*scale, recoil.MaxKick*scale)/scale

    game.Workspace.CurrentCamera.CFrame = game.Workspace.CurrentCamera.CFrame 
     * CFrame.new(cam_kick, 0, 0) 
     * CFrame.Angles(math.rad(cam_jolt), 0, math.rad(cam_rattle))
end

function BaseFirearm:TriggerDown(hand, dt, grip_point)
    print("trigger", dt)

    
    if self.Automatic ~= true then
        if self.TriggerPressed then return end
        --self.Timer = 1/self:GetCycleTime()
    end
    if self.Timer >= (1/self:GetCycleTime()) and self.RoundInChamber then
        --self.Timer = self.Timer - (1/self:GetCycleTime())
        self.Timer = 0

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
    hand:Release(true)
    print("Hand force removed!")
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
        self.Timer = self.Timer + dt
        
        hand.RecoilCorrectionCFrame = hand.RecoilCorrectionCFrame:Lerp(CFrame.new(0, 0, 0), 1/self.RecoilRecoverySpeed)

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
        
    end
end

function BaseFirearm:OnTriggerState(hand, finger_pressure, grip_point)
end

return BaseFirearm