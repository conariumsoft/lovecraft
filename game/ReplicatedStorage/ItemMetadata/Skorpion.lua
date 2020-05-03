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
Skorpion.MuzzleFlipMax = 70
Skorpion.MuzzleFlipMin = 50
Skorpion.YShakeMin = -10
Skorpion.YShakeMax = 10
Skorpion.ZShakeMin = -10
Skorpion.ZShakeMax = 10
Skorpion.RecoilRecoverySpeed = 5
Skorpion.BarrelComponent = "Rifling"
Skorpion.MagazineComponent = "Magazine"
Skorpion.BoltComponent = "ChargingHandle"
Skorpion.Timer = 0
Skorpion.MagazineType = "SkorpionMagazine"

--[[
function Skorpion:HandleOnRelease(hand, model)
    self.super.HandleOnRelease(self, hand, model)

    --- hhave it

end
]]

return Skorpion