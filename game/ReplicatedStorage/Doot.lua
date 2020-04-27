using "Lovecraft.BaseClass"

local InteractiveObj = BaseClass:subclass("InteractiveObject")

function InteractiveObj:__ctor(ObjectName, )
    self.GripType = "Hold" 
end

local GripPoint = BaseClass:subclass("GripPoint")

function GripPoint:__ctor(attachment_part, primary_grip_point, allow_multiple_hands)

end

local BaseWeapon = InteractiveObj:subclass("BaseWeapon")

local BaseFirearm = BaseWeapon:subclass("BaseFirearm")

local BasePistol = BaseFirearm:subclass("BasePistol") do
    BasePistol.GripPoints = {
        ["Handle"] = GripPoint:new()
    }
   -- BasePistol.

end


local m1911 = BaseFirearm:new("M1911")

function m1911:OnHandGrabContact(player, hand, skorp_model, grip_point)

end


local skorp = BaseFirearm:new("Skorpion")
skorp.GripPoints = {
    ["Handle"] = GripPoint:new("Handle", true, false),
    ["ChargingHandle"] = GripPoint:new("ChargingHandle", false, false),

}
--[[

    skorp notes:
    - locks open on empty magazine
    - spring loaded bolt


    skorp grip points:
    handle,
    bolt

]]
local can_player_pull_charging_handle

function skorp:PopulateModelWithProperties(skorp_model)
    --[[
        create following instances:
        Properties
            HasMagazine
            MagazineCount
            RoundInChamber
            NeedToDropBolt

    ]]
end

function skorp:OnPlayerGainControl(player, skorp_model)

end

function skorp:DoesPlayerHaveControl(player, skorp_model)

end

function skorp:OnPlayerReleaseControl(player, skorp_model)

end

function skorp:OnHandGrabContact(player, hand, skorp_model, grip_point)
    if grip_point == "handle" then
    end
end

function skorp:OnHandReleaseContact(player, hand, skorp_model, grip_point)

end

function skorp:OnHandContactStep(hand, skorp_model, deltatime)

end

local function fire_or_whatever() end local function run_animations() end

function skorp:OnPrimaryContactStep(player, hand, skorp_model, grip_point, step)
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

function skorp:OnPlayerStep(player, skorp_model, delta)

end

