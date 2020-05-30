local BaseFirearm = require(script.Parent.BaseFirearm)

local Glock17 = BaseFirearm:subclass("Glock17")

--[[
    GLOCK 17 Semiauto pistol
    https://en.wikipedia.org/wiki/Glock

    Mass = 
    Cartridge = 9mm Para
    Rate of Fire = N/A (Gonna go with 1000)
]]

Glock17.TriggerStiffness = 0.5
Glock17.RateOfFire = 1000
Glock17.Recoil = {
    XMoveMax = 0.04,
    XMoveMin = -0.04,
    YMoveMin = 0.4,
    YMoveMax = 1.0,
    ZMoveMin = 0.025,
    ZMoveMax = 0.075,
    XTiltMin = 30,
    XTiltMax = 45,
    YTiltMin = -3,
    YTiltMax = 3,
    ZTiltMin = -3,
    ZTiltMax = 3,
    CamRattle = 4,
    CamJolt = 3,
    MinKick = 0,
    MaxKick = 0.25,
}
Glock17.Cartridge = "9mm Parabellum"
Glock17.RecoilRecoverySpeed = 6
Glock17.BarrelComponent = "Rifling"
Glock17.MagazineComponent = "Magazine"
Glock17.BoltComponent = "Slide"
Glock17.MagazineType = "GlockMag"
Glock17.Automatic = false
Glock17.MagazineCFrame = CFrame.new(0.162 , 0, -0.05) * CFrame.Angles(math.rad(90), 0, 0)


function Glock17:BoltCycle()
    local prism = self.Model[self.BoltComponent].PrismaticConstraint

    prism.TargetPosition = 0.5

    if self.RoundInChamber == false then
        prism.TargetPosition = 0.35

    else
        delay(0.1, function()
            prism.TargetPosition = 0.2
        end)
    end
end

function Glock17:ChargingHandleOnRelease(hand)
    local prism = self.Model[self.BoltComponent].PrismaticConstraint

    if self.MagazineInserted and self.RoundInChamber == false then
        self.RoundInChamber = true
        self.MagazineRoundCount = self.MagazineRoundCount - 1

        prism.TargetPosition = 0
    end
end

return Glock17