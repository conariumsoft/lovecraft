local BaseFirearm = require(script.Parent.BaseFirearm)

local Skorpion = BaseFirearm:subclass("Skorpion")

--[[
    Skorpion vz. 61 Specifications
    https://en.wikipedia.org/wiki/%C5%A0korpion

    Mass: 1.30kg
    Cartridge: .32ACP
    Action: Blowback, Closed bolt,
    RoF: 850 rounds/minute
    Muzzle velocity: 320 m/s (1050 ft/s)

]]

local timer = (1/10)

function Skorpion:OnGrab(hand, model, grip_point)
    self.super:OnGrab(hand, model, grip_point)
    local muzzle_flip = Instance.new("BodyThrust") do
        muzzle_flip.Name = "MuzzleFlip"
        muzzle_flip.Location = Vector3.new(0, 0, 0)
        muzzle_flip.Force = Vector3.new(0, 0, 0)
        muzzle_flip.Parent = model.rifling
    end
    local recoil_impulse = Instance.new("BodyThrust") do
        recoil_impulse.Name = "RecoilImpulse"
        recoil_impulse.Location = Vector3.new(0, 0, 0)
        recoil_impulse.Parent = model.rifling
        recoil_impulse.Force = Vector3.new(0, 0, 0)
    end
end

function Skorpion:OnRelease(hand, model, grip_point)
    self.super:OnRelease(hand, model, grip_point)
    model.rifling.MuzzleFlip:Destroy()
    model.rifling.RecoilImpulse:Destroy()
end

local trigger_stiffness = 0.95
local rate_of_fire = 850 -- rounds per minute

local muzzle_flip_max = 90
local muzzle_flip_min = 70

local y_shake_min = -15
local y_shake_max =  15

local z_shake_min = -10
local z_shake_max = 10

local recoil_recovery_speed = 10

local cycle_time = (rate_of_fire/60)

function Skorpion:OnSimulationStep(hand, model, dt, grip_point)
    -- trigger being pulled
    if hand.IndexFingerPressure > trigger_stiffness then
        timer = timer + dt
        if timer >= (1/cycle_time) then
            timer = timer - (1/cycle_time)
            
            model.fire:Stop()
            model.fire.TimePosition = 0.05
            model.fire:Play()

            -- TODO: Backwards recoil!
            local recoil_impulse = model.rifling.RecoilImpulse

            --muzzle_flip.Force = Vector3.new(0, 0, 50)
            recoil_impulse.Force = Vector3.new(
                -math.max(   muzzle_flip_min, muzzle_flip_max), 
                 math.random(y_shake_min,     y_shake_max    ), 
                 math.random(z_shake_min,     z_shake_max    )
            )

            delay(1/recoil_recovery_speed, function()
                recoil_impulse.Force = Vector3.new(0, 0, 0)
            end)

        end
    end
    
end

function Skorpion:OnTriggerState(hand, model, finger_pressure, grip_point)
    if finger_pressure > 0.95 then
        
    end
end

return Skorpion