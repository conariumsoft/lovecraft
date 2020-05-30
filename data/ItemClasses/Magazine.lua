local BaseInteractive = require(script.Parent.BaseInteractive)

local Mag = BaseInteractive:subclass("Magazine")

-- TODO: Contain round count within magazine

function Mag:__ctor(...)
    BaseInteractive.__ctor(self, ...)
    self.Latched = false
    self.LatchedGun = nil
    self.BeingGripped = false
end

function Mag:OnGrab(hand)
    self.BeingGripped = true
end

function Mag:OnRelease(hand)
    self.BeingGripped = false
end

function Mag:OnRemove()

end

function Mag:OnInsert(gun)
    print(gun.Cartridge)
    self.LatchedGun = gun
end

function Mag:OnSimulationStep(handinst, dt, grip_pt)

    if handinst.IndexFingerPressure > 0.95 then
        self.LatchedGun:OnMagazineRemove()
        self:OnRemove()
        self.Model.PrimaryPart.MagWeld:Destroy()
    end
end

return Mag