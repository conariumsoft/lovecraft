local BaseInteractive = require(script.Parent.BaseInteractive)

local BaseFirearm = BaseInteractive:subclass("BaseFirearm")

function BaseFirearm:OnGrab(hand, model, grip_point)

end

function BaseFirearm:OnRelease(hand, model, grip_point)

end


function BaseFirearm:OnSimulationStep(hand, model, dt, grip_point)

end

function BaseFirearm:OnTriggerState(hand, model, finger_pressure, grip_point)

end

return BaseFirearm