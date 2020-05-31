_G.using "Lovecraft.Networking"
_G.using "RBX.Debris"

local BaseFirearm = require(script.Parent.BaseFirearm)

local Shotgun = BaseFirearm:subclass("Shotgun")

function Shotgun:FireProjectile()
    -- Buckshot shell
    for i = 1, 9 do
        local barrel = self.Model[self.BarrelComponent]
        local ray = Ray.new(barrel.CFrame.p, (barrel.CFrame.rightVector + 
            Vector3.new(math.random(-100, 100)/2000, math.random(-100, 100)/2000, math.random(-100, 100)/2000))
            *200)

        self:HitTest(ray)
    end
end

return Shotgun