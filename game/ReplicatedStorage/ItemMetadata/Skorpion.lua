local BaseFirearm = require(script.Parent.BaseFirearm)

local Skorpion = BaseFirearm:subclass("Skorpion")

local timer = (1/10)

function Skorpion:OnGrab(hand, model, grip_point)
    local muzzle_flip = Instance.new("BodyAngularVelocity") do
        muzzle_flip.AngularVelocity = Vector3.new(-200, 0, 0)--model.rifling.CFrame.RightVector*20
        muzzle_flip.Parent = model.rifling
    end
end

function Skorpion:OnRelease(hand, model, grip_point)
    model.rifling.BodyAngularVelocity:Destroy()
end

function Skorpion:OnSimulationStep(hand, model, dt, grip_point)
    -- trigger being pulled
    if hand.IndexFingerPressure > 0.95 then
        timer = timer + dt
        if timer >= (1/10) then
            timer = timer - (1/10)
            
            model.fire:Stop()
            model.fire.TimePosition = 0.05
            model.fire:Play()

            local muzzle_flip = model.rifling.BodyAngularVelocity
            --muzzle_flip.AngularVelocity = (model.rifling.CFrame.UpVector*10) --* Vector3.new(0, math.random(-10, 10), 0)
            muzzle_flip.MaxTorque = Vector3.new(100000, 100000, 100000)
            --model.rifling.BodyVelocity.Velocity = model.rifling.CFrame.UpVector*20 + Vector3.new(0, 0, math.random())
            delay(1/20, function()
                muzzle_flip.MaxTorque = Vector3.new(0, 0, 0)
            end)

        end
    end
    
end

function Skorpion:OnTriggerState(hand, model, finger_pressure, grip_point)
    if finger_pressure > 0.95 then
        
    end
end

return Skorpion