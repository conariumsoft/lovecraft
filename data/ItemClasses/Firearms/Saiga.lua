_G.using "Lovecraft.Networking"
_G.using "RBX.Debris"

local BaseFirearm = require(script.Parent.BaseFirearm)

local Saiga = BaseFirearm:subclass("Saiga")
local Cartridges = require(game.ReplicatedStorage.Data.Cartridges)
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
Saiga.BarrelComponent = "Rifling"
Saiga.MagazineComponent = "Magazine"
Saiga.BoltComponent = "ChargingHandle"
Saiga.Timer = 1
Saiga.Cartridge = "12 Gauge Buckshot"
Saiga.MagazineType = "SkorpionMagazine"
Saiga.Automatic = true

function Saiga:FireProjectile()

    for i = 1, 9 do
        local barrel = self.Model[self.BarrelComponent]
        local coach_ray = Ray.new(barrel.CFrame.p, (barrel.CFrame.rightVector + 
            Vector3.new(math.random(-100, 100)/2000, math.random(-100, 100)/2000, math.random(-100, 100)/2000))
            *200)

        local cartridge = Cartridges[self.Cartridge]

        local hit, pos, surfacenormal, material = game.Workspace:FindPartOnRay(coach_ray, self.Model)
    
        if hit then
        local isPlayer = false
    
        -- gotta hit
        if hit.Parent:FindFirstChild("Humanoid") then
            local resultant_damage = cartridge.Damage
            if hit.Name == "Head" or hit.Name == "HeadJ" then
                print("Headshot!")
                resultant_damage = resultant_damage * cartridge.HeadMul
            end
    
            if hit.Name == "LeftUpperArm" or hit.Name == "LeftLowerArm" or hit.Name == "RightUpperArm" or hit.Name == "RightLowerArm" then
                resultant_damage = resultant_damage * cartridge.ArmMul
            end
    
            for i = 1, resultant_damage/2 do
                self:BloodSplatter(hit)
            end
    
            local hit_reflect = Networking.GetNetHook("ClientHit")
            hit_reflect:FireServer(hit.Parent, resultant_damage)
            hit.Parent.Humanoid:TakeDamage(resultant_damage)
            -- TODO: hitreg?
        end
    
        if hit.Anchored then
            local bullet_impact = Instance.new("Part") do
                bullet_impact.Color = Color3.new(1, 1, 1)
                bullet_impact.Material = Enum.Material.Neon
                bullet_impact.Shape = Enum.PartType.Ball
                bullet_impact.Transparency = 0.25
                local impact_size = cartridge.BoreDiameter/2
                bullet_impact.Size = Vector3.new(impact_size, impact_size, impact_size)
                bullet_impact.Anchored = true
                bullet_impact.CanCollide = false
                bullet_impact.CFrame = CFrame.new(pos)
                bullet_impact.Parent = game.Workspace
    
                Debris:AddItem(bullet_impact, 30)
            end
        end
        end
    end
end

return Saiga