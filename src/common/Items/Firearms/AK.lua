local BaseFirearm = require(script.Parent.BaseFirearm)

local AK = BaseFirearm:subclass("AK")

--[[
    
]]
AK.Cartridge = "7.62mm"
AK.TriggerStiffness = 0.5
AK.RateOfFire = 600
AK.Recoil = {
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
AK.RecoilRecoverySpeed = 10
AK.BarrelComponent = "Muzzle"
AK.MagazineComponent = "Magazine"
AK.BoltComponent = "ChargingHandle"
AK.MagazineType = "AKMag"
AK.Automatic = true
AK.MagazineSize = 50
AK.MagazineCFrame = CFrame.new(-0.2, 0, -0.1) * CFrame.Angles(0, -math.rad(20), 0)

return AK