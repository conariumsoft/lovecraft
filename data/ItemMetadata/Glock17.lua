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
    YMoveMin = -1.5,
    YMoveMax = -1,
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
Glock17.MagazineType = "Glock17Mag"
Glock17.Automatic = false

return Glock17