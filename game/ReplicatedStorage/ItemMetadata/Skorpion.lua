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
Skorpion.RateOfFire = 850
Skorpion.MuzzleFlipMax = 90
Skorpion.MuzzleFlipMin = 70
Skorpion.YShakeMin = -15
Skorpion.YShakeMax = 15
Skorpion.ZShakeMin = -10
Skorpion.ZShakeMax = 10
Skorpion.RecoilRecoverySpeed = 10
Skorpion.BarrelComponentName = "rifling"
Skorpion.Timer = 0

return Skorpion