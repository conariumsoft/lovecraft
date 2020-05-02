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
BaseFirearm.BarrelComponentName = nil
BaseFirearm.Timer = 0
BaseFirearm.MagazineType = nil
BaseFirearm.OpenBolt = false

function BaseFirearm:GetCycleTime()
    return self.RateOfFire/60
end

function BaseFirearm:OnGrab(hand, model, grip_point)

    self.BarrelComponent = model[self.BarrelComponentName]

    local muzzle_flip = Instance.new("BodyThrust") do
        muzzle_flip.Name = "MuzzleFlip"
        muzzle_flip.Location = Vector3.new(0, 0, 0)
        muzzle_flip.Force = Vector3.new(0, 0, 0)
        muzzle_flip.Parent = self.BarrelComponent
    end


    local recoil_impulse = Instance.new("BodyThrust") do
        recoil_impulse.Name = "RecoilImpulse"
        recoil_impulse.Location = Vector3.new(0, 0, 0)
        recoil_impulse.Parent = self.BarrelComponent
        recoil_impulse.Force = Vector3.new(0, 0, 0)
    end

end

function BaseFirearm:OnRelease(hand, model, grip_point)
    self.BarrelComponent.MuzzleFlip:Destroy()
    self.BarrelComponent.RecoilImpulse:Destroy()
end

function BaseFirearm:OnSimulationStep(hand, model, dt, grip_point)
    -- trigger being pulled
    if hand.IndexFingerPressure > self.TriggerStiffness then
        self.Timer = self.Timer + dt
        if self.Timer >= (1/self:GetCycleTime()) then
            self.Timer = self.Timer - (1/self:GetCycleTime())
            
            model.fire:Stop()
            model.fire.TimePosition = 0.05
            model.fire:Play()

            -- TODO: Backwards recoil!
            local recoil_impulse = model.rifling.RecoilImpulse

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
    end
end

function BaseFirearm:OnTriggerState(hand, model, finger_pressure, grip_point)
    if finger_pressure > 0.95 then
        
    end
end

return BaseFirearm