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

Skorpion.TriggerStiffness = 0.95
Skorpion.RateOfFire = 750

-- Recoil --
Skorpion.Recoil = {
    XMoveMax = 0.1,
    XMoveMin = 0,
    YMoveMin = 0,
    YMoveMax = 0,
    ZMoveMin = 0,
    ZMoveMax = 0,
    XTiltMin = 2,
    XTiltMax = 4,
    YTiltMin = -2,
    YTiltMax = 1,
    ZTiltMin = -5,
    ZTiltMax = 5,
    CamRattle = 4,
    CamJolt = 3,
    MinKick = 0,
    MaxKick = 0.25,
}

Skorpion.RecoilRecoverySpeed = 12
Skorpion.Cartridge = "9mm Parabellum"
Skorpion.BarrelComponent = "Muzzle"
Skorpion.MagazineComponent = "Magazine"
Skorpion.BoltComponent = "ChargingHandle"
Skorpion.MagazineType = "SkorpionMagazine"
Skorpion.Automatic = true
Skorpion.MagazineSize = 30

return Skorpion