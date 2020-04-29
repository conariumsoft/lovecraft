local BaseFirearm = require(script.Parent.BaseFirearm)

local Skorpion = BaseFirearm:subclass("Skorpion")


function Skorpion:CanHandGrab(hand, model, grip_point)
    return true
end

function Skorpion:OnHandGrab(hand, model, grip_point)

end

function Skorpion:OnHandRelease(hand, model, grip_point)

end

function Skorpion:OnHeldStep(hand, model, dt, grip_point)

end

function Skorpion:OnStep(player, hand, contact_point)
    if hand.IndexFingerPressure > 0.75 then
        local can_fire = false

        local props = skorp_model.Properties
        if props.HasMagazine.Value == true and props.MagazineCount.Value > 0 then
            props.RoundInChamber = false
            can_fire = true
            props.MagazineCount.Value = props.MagazineCount.Value - 1
        elseif props.RoundInChamber == true then
            can_fire = true
            props.RoundInChamber = false
        end

        fire_or_whatever()
        
        if props.MagazineCount.Value == 0 and props.RoundInChamber.Value == false then
            props.BoltLocked.Value = true
        end

        run_animations()
    end

end

return Skorpion