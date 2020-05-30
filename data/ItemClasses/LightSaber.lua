local BaseInteractive = require(script.Parent.BaseInteractive)

local LightSaber = BaseInteractive:subclass("LightSaber")

local timer = (1/10)


function LightSaber:OnGrab(hand, model, grip_point)
     
end

function LightSaber:OnRelease(hand, model, grip_point)
    
end

function LightSaber:OnSimulationStep(hand, model, dt, grip_point)

end

function LightSaber:OnTriggerState(hand, model, finger_pressure, grip_point)
    
end

return LightSaber