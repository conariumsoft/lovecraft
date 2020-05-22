local BaseFirearm = require(script.Parent.BaseFirearm)

local Hecate = BaseFirearm:subclass("Hecate")

--[[
    Skorpion vz. 61 Specifications
    https://en.wikipedia.org/wiki/%C5%A0korpion

    Mass: 1.30kg
    Cartridge: .32ACP
    Action: Blowback, Closed bolt,
    RoF: 850 rounds/minute
    Muzzle velocity: 320 m/s (1050 ft/s)
]]

Hecate.TriggerStiffness = 0.95
Hecate.RateOfFire = 30
Hecate.MuzzleFlipMax = 4000
Hecate.MuzzleFlipMin = 500
Hecate.YShakeMin = -10
Hecate.YShakeMax = 10
Hecate.ZShakeMin = -10
Hecate.ZShakeMax = 10
Hecate.RecoilRecoverySpeed = 0.1 -- smaller values -> slower recoil recovery
Hecate.BarrelComponent = "Barrel"
Hecate.MagazineComponent = "Magazine"
Hecate.BoltComponent = "ChargingHandle"
Hecate.Timer = 30
Hecate.MagazineType = "HecateMagazine"
Hecate.Automatic = false

return Hecate