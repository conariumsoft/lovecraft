local BaseFirearm = require(script.Parent.BaseFirearm)

local Tec9 = BaseFirearm:subclass("Tec9")

--[[
    
]]

Tec9.TriggerStiffness = 0.5
Tec9.RateOfFire = 1500
Tec9.Recoil = {
    XMoveMax = 0.06,
    XMoveMin = -0.01,
    YMoveMin = 0,
    YMoveMax = 0,
    ZMoveMin = -0.02,
    ZMoveMax = 0.02,
    XTiltMin = 0,
    XTiltMax = 8,
    YTiltMin = -3,
    YTiltMax = 3,
    ZTiltMin = -2.5,
    ZTiltMax = 2.5,
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
Tec9.MagazineSize = 50

return Tec9