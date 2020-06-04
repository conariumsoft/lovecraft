local BaseFirearm = require(script.Parent.BaseFirearm)

local Vector = BaseFirearm:subclass("Vector")

--[[
    
]]
Vector.Cartridge = "9mm Parabellum"
Vector.TriggerStiffness = 0.5
Vector.RateOfFire = 1000
Vector.Recoil = {
    XMoveMax = 0.06,
    XMoveMin = -0.01,
    YMoveMin = 0,
    YMoveMax = 0,
    ZMoveMin = -0.02,
    ZMoveMax = 0.02,
    XTiltMin = 0,
    XTiltMax = 6,
    YTiltMin = -3,
    YTiltMax = 3,
    ZTiltMin = -2.5,
    ZTiltMax = 2.5,
    CamRattle = 2,
    CamJolt = 3,
    MinKick = 0,
    MaxKick = 0.25,
}
Vector.RecoilRecoverySpeed = 10
Vector.BarrelComponent = "Muzzle"
Vector.MagazineComponent = "Magazine"
Vector.BoltComponent = "ChargingHandle"
Vector.MagazineType = "Tec9Mag"
Vector.Automatic = true
Vector.MagazineSize = 50
Vector.MagazineCFrame = CFrame.new(-0.2, 0, -0.1) * CFrame.Angles(0, -math.rad(20), 0)

return Vector