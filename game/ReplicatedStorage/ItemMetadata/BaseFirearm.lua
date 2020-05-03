local BaseInteractive = require(script.Parent.BaseInteractive)

local BaseFirearm = BaseInteractive:subclass("BaseFirearm")

BaseFirearm.TriggerStiffness = 0.95
BaseFirearm.RateOfFire = 850

BaseFirearm.MuzzleFlipMax = 150
BaseFirearm.MuzzleFlipMin = 50
BaseFirearm.YShakeMin = -15
BaseFirearm.YShakeMax = 15
BaseFirearm.ZShakeMin = -10
BaseFirearm.ZShakeMax = 10
BaseFirearm.RecoilRecoverySpeed = 5

BaseFirearm.BarrelComponent = nil
BaseFirearm.MagazineComponent = nil
BaseFirearm.BoltComponent = nil
BaseFirearm.BoltTravelDistance = 0.2
BaseFirearm.RoundInChamber = true
BaseFirearm.MagazineInserted = true
BaseFirearm.MagazineRoundCount = 30

BaseFirearm.Timer = 0
BaseFirearm.MagazineType = nil
BaseFirearm.OpenBolt = false
BaseFirearm.BoltGrabbed = false

-- this blows, but we just need to get guns working for now.

local animation_track = nil

------------------------------------------------
-- Various Methods
function BaseFirearm:GetCycleTime()
    return self.RateOfFire/60
end
-------------------------------------------------------
-- Handle (Trigger Group) Functionality
function BaseFirearm:HandleOnGrab(hand, model)
    if animation_track == nil then

        animation_track = model.AnimationController:LoadAnimation(model.slideBack)
        animation_track.Priority = Enum.AnimationPriority.Core
        print("Initial Anim Load:", animation_track)
    end
    local barrel = model[self.BarrelComponent]
    local magazine = model[self.MagazineComponent]

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

function BaseFirearm:HandleOnRelease(hand, model)
    print("Handle Released")
    local barrel = model[self.BarrelComponent]
    if barrel:FindFirstChild("MuzzleFlip") then
        barrel.MuzzleFlip:Destroy()
    end

    if barrel:FindFirstChild("RecoilImpulse") then
        barrel.RecoilImpulse:Destroy()
    end
    
end
---------------------------------------------------

function BaseFirearm:MagazineOnGrab(hand, model)

end

function BaseFirearm:MagazineOnRelease(hand, model)
    --hand:Release()
    --hand:Grab()
    -- AAAAAAAAAAAAAAAAAAAAA
    self:HandleOnRelease(hand, model)
    self:HandleOnGrab(hand, model)
end
------------------------------------------------------
function BaseFirearm:ChargingHandleOnGrab(hand, model)
    self.BoltGrabbed = true
end

function BaseFirearm:ChargingHandleOnRelease(hand, model)
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

function BaseFirearm:OnGrab(hand, model, grip_point)
    local g = grip_point.Name
    if     g == "Handle"         then self:HandleOnGrab(hand, model)
    elseif g == "Magazine"       then self:MagazineOnGrab(hand, model)
    elseif g == "ChargingHandle" then self:ChargingHandleOnGrab(hand, model) 
    end
end

function BaseFirearm:OnRelease(hand, model, grip_point)
    local gp = grip_point.Name
    if     gp == "Handle"         then self:HandleOnRelease(hand, model)
    elseif gp == "Magazine"       then self:MagazineOnRelease(hand, model)
    elseif gp == "ChargingHandle" then self:ChargingHandleOnRelease(hand, model)
    end
end

function BaseFirearm:FireProjectile(hand, model, grip_point)

    if grip_point.Name == "Handle" then
        local barrel = model[self.BarrelComponent]
        local coach_ray = Ray.new(barrel.CFrame.p, barrel.CFrame.rightVector*200)
        local hit, pos = game.Workspace:FindPartOnRay(coach_ray, model)
        local bullet_impact = Instance.new("Part") do
            bullet_impact.Color = Color3.new(0, 0, 0)
            bullet_impact.Shape = Enum.PartType.Ball
            bullet_impact.Transparency = 0.25
            bullet_impact.Size = Vector3.new(0.075, 0.075, 0.075)
            bullet_impact.Anchored = true
            bullet_impact.CFrame = CFrame.new(pos)
            bullet_impact.Parent = game.Workspace
        end
    end
end

function BaseFirearm:Fire(hand, model, grip_point)
	print("WOW!", hand)
    local barrel = model[self.BarrelComponent]
    local bolt = model[self.BoltComponent]

    model.fire:Stop()
    model.fire.TimePosition = 0.05
    model.fire:Play()

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

    self:ApplyRecoilImpulse(hand, model, grip_point)
    self:FireProjectile(hand, model, grip_point)

    barrel.BillboardGui.Enabled = true
    barrel.BillboardGui.ImageLabel.Rotation = math.random(0, 360)
    delay(1/20, function()
        barrel.BillboardGui.Enabled = false
    end)
end

function BaseFirearm:ClientFireEffects(hand, model, grip_point)


end

function BaseFirearm:ApplyRecoilImpulse(hand, model, grip_point)
    local barrel = model[self.BarrelComponent]
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

function BaseFirearm:TriggerDown(hand, model, dt, grip_point)
    
    self.Timer = self.Timer + dt
    if self.Timer >= (1/self:GetCycleTime()) and self.RoundInChamber then
        self.Timer = self.Timer - (1/self:GetCycleTime())

        self.MagazineRoundCount = self.MagazineRoundCount - 1

        if self.MagazineRoundCount == 0 then
            self.RoundInChamber = false
        end

        self:Fire(hand, model, grip_point)
    end
end

function BaseFirearm:OnMagazineInsert(model, magazine)
    self.MagazineInserted = true
    self.MagazineRoundCount = 30--magazine.Rounds.Value

    model[self.MagazineComponent].Transparency = 0
    magazine.Parent = nil

    if model[self.MagazineComponent]:FindFirstChild("GripPoint") == nil then
        local mag_gp = Instance.new("BoolValue") do
            mag_gp.Name = "GripPoint"
            mag_gp.Parent = model[self.MagazineComponent]
        end
    end
end

function BaseFirearm:OnMagazineRemove(hand, model)

    hand:Release()
    self.MagazineInserted = false

    model[self.MagazineComponent].GripPoint:Destroy()
    model[self.MagazineComponent].Transparency = 1
end



function BaseFirearm:OnSimulationStep(hand, model, dt, grip_point)
    local magazine = model[self.MagazineComponent]

    local mag_well = model.MagazineCorrect

    for _, part in pairs(mag_well:GetTouchingParts()) do
        if part.Parent.Name == self.MagazineType then
            self:OnMagazineInsert(model, part.Parent)
        end
    end

    if grip_point.Name == "Handle" then
        if hand.IndexFingerPressure > self.TriggerStiffness then
            self:TriggerDown(hand, model, dt, grip_point)
        end
    end

    if grip_point.Name == "Magazine" and self.MagazineInserted and hand.IndexFingerPressure > 0.95 then
        print("Remove Mag!")
        self:OnMagazineRemove(hand, model)
    end

    if grip_point.Name == "ChargingHandle" then
        
    end
end

function BaseFirearm:OnTriggerState(hand, model, finger_pressure, grip_point)
end

return BaseFirearm