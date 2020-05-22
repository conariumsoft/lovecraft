local BaseFirearm = require(script.Parent.BaseFirearm)

local Saiga = BaseFirearm:subclass("Saiga")

--[[
    Skorpion vz. 61 Specifications
    https://en.wikipedia.org/wiki/%C5%A0korpion

    Mass: 1.30kg
    Cartridge: .32ACP
    Action: Blowback, Closed bolt,
    RoF: 850 rounds/minute
    Muzzle velocity: 320 m/s (1050 ft/s)

]]

Saiga.TriggerStiffness = 0.95
Saiga.RateOfFire = 850
Saiga.MuzzleFlipMax = 70
Saiga.MuzzleFlipMin = 50
Saiga.YShakeMin = -10
Saiga.YShakeMax = 10
Saiga.ZShakeMin = -10
Saiga.ZShakeMax = 10
Saiga.RecoilRecoverySpeed = 5
Saiga.BarrelComponent = "Rifling"
Saiga.MagazineComponent = "Magazine"
Saiga.BoltComponent = "ChargingHandle"
Saiga.Timer = 0
Saiga.MagazineType = "SkorpionMagazine"

--[[
function Skorpion:HandleOnRelease(hand, model)
    self.super.HandleOnRelease(self, hand, model)

    --- hhave it

end
]]

return Saiga