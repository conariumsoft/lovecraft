local BaseInteractive = require(script.Parent.BaseInteractive)

local Mag = BaseInteractive:subclass("Magazine")



function Mag:__ctor(...)
    BaseInteractive.__ctor(self, ...)
    self.Latched = false
end

function Mag:OnGrab()

end

function Mag:OnInsert()

end

function Mag:OnSimulationStep(handinst, dt, grip_pt)
    if handinst.IndexFingerPressure > 0.95 then
        if self.Latched then

            self.Latched = false
            self.Model.MagWeld:Destroy()
        end
    end
end