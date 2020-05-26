local BaseFirearm = require(script.Parent.BaseFirearm)

local Hecate = BaseFirearm:subclass("Hecate")



Hecate.TriggerStiffness = 0.95
Hecate.RateOfFire = 60
Hecate.Recoil = {
    XMoveMax = 0.1,
    XMoveMin = -0.1,
    YMoveMin = 0,
    YMoveMax = 0,
    ZMoveMin = 1.5,
    ZMoveMax = 1.75,
    XTiltMin = 5,
    XTiltMax = 10,
    YTiltMin = -5,
    YTiltMax = 5,
    ZTiltMin = -5,
    ZTiltMax = 5,
    CamRattle = 25,
    CamJolt = 25,
    MinKick = 1,
    MaxKick = 3,
}
Hecate.RecoilRecoverySpeed = 20 -- smaller values -> slower recoil recovery
Hecate.BarrelComponent = "Barrel"
Hecate.MagazineComponent = "Magazine"
Hecate.BoltComponent = "ChargingHandle"
Hecate.Timer = 30
Hecate.MagazineType = "HecateMagazine"
Hecate.Automatic = false

return Hecate