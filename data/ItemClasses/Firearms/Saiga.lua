_G.using "Lovecraft.Networking"
_G.using "RBX.Debris"

local Shotgun = require(script.Parent.Shotgun)

local Saiga = Shotgun:subclass("Saiga")
--[[
    Saiga-12 Automatic Combat Shotgun
    https://en.wikipedia.org/wiki/Saiga-12

    Mass: 3.60kg
    Cartridge: 12-gauge shells
    Action: Gas Operated, Rotating Bolt
    RoF: N/A (We're gonna go with 300?)
    Muzzle velocity: 320 m/s (1050 ft/s)
]]

Saiga.TriggerStiffness = 0.95
Saiga.RateOfFire = 200
Saiga.Recoil = {
    XMoveMax = 0.05,
    XMoveMin = -0.05,
    YMoveMin = 0,
    YMoveMax = 0,
    ZMoveMin = 0.75,
    ZMoveMax = 1.25,
    XTiltMin = -10,
    XTiltMax = 10,
    YTiltMin = -5,
    YTiltMax = 5,
    ZTiltMin = -5,
    ZTiltMax = 5,
    CamRattle = 25,
    CamJolt = 15,
    MinKick = 0.5,
    MaxKick = 1,
}
Saiga.RecoilRecoverySpeed = 8
Saiga.BarrelComponent = "Muzzle"
Saiga.MagazineComponent = "Magazine"
Saiga.BoltComponent = "ChargingHandle"
Saiga.Timer = 1
Saiga.Cartridge = "12 Gauge Buckshot"
Saiga.MagazineType = "SkorpionMagazine"
Saiga.Automatic = true

return Saiga