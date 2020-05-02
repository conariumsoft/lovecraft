local BaseFirearm = require(script.Parent.BaseFirearm)

local Skorpion = BaseFirearm:subclass("Skorpion")

local timer = (1/10)

function Skorpion:OnGrab(hand, model, grip_point)
    local translation_recoil = Instance.new("BodyThrust") do
        --muzzle_flip.Force = Vector3.new(0, 100, 0)--model.rifling.CFrame.RightVector*20
        translation_recoil.Location = Vector3.new(0, 0, -2)
        translation_recoil.Force = Vector3.new(0, 0, 0)
        translation_recoil.Parent = model.rifling
    end

    local muzzle_flip = Instance.new("BodyAngularVelocity") do
        muzzle_flip.AngularVelocity = Vector3.new(0, 0, 0)
       -- muzzle_flip.Parent = hand.HandModel.PrimaryPart
        muzzle_flip.MaxTorque = Vector3.new(100000, 100000, 100000)
        muzzle_flip.Parent = model.rifling
    end

end

function Skorpion:OnRelease(hand, model, grip_point)
    model.rifling.BodyThrust:Destroy()
    --hand.HandModel.PrimaryPart.BodyAngularVelocity:Destroy()
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

            
            --local muzzle_flip = hand.HandModel.PrimaryPart.BodyAngularVelocity
           
            
            local translation_recoil = model.rifling.BodyThrust
            
            local muzzle_flip = model.rifling.BodyAngularVelocity
            --translation_recoil.Force = Vector3.new(0, 0, 400)

            muzzle_flip.AngularVelocity = Vector3.new(0, 2, 0) * math.rad(360)

            --Vector3.new(-math.random(200, 400), math.random(-200, 200), 100)
            delay(1/10, function()

                --muzzle_flip.AngularVelocity = Vector3.new(0, 0, 0)
                translation_recoil.Force = Vector3.new(0, 0, 0)
            end)

        end
    end
    
end

function Skorpion:OnTriggerState(hand, model, finger_pressure, grip_point)
    if finger_pressure > 0.95 then
        
    end
end

return Skorpion