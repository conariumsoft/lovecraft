local BaseFirearm = require(script.Parent.BaseFirearm)

local Tec9 = BaseFirearm:subclass("Tec9")

--[[
    GLOCK 17 Semiauto pistol
    https://en.wikipedia.org/wiki/Glock

    Mass = 
    Cartridge = 9mm Para
    Rate of Fire = N/A (Gonna go with 1000)
]]

Tec9.TriggerStiffness = 0.5
Tec9.RateOfFire = 1000
Tec9.Recoil = {
    XMoveMax = 0.04,
    XMoveMin = -0.04,
    YMoveMin = 0,
    YMoveMax = 0,
    ZMoveMin = 0.025,
    ZMoveMax = 0.075,
    XTiltMin = 10,
    XTiltMax = 20,
    YTiltMin = -3,
    YTiltMax = 3,
    ZTiltMin = -3,
    ZTiltMax = 3,
    CamRattle = 4,
    CamJolt = 3,
    MinKick = 0,
    MaxKick = 0.25,
}
Tec9.RecoilRecoverySpeed = 10
Tec9.BarrelComponent = "Muzzle"
Tec9.MagazineComponent = "Magazine"
Tec9.BoltComponent = "ChargingHandle"
Tec9.MagazineType = "Tec9Mag"
Tec9.Automatic = true

return Tec9