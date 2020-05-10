local BaseInteractive = _G.newclass("InteractiveObject")

function BaseInteractive:OnGrab(hand, model, grip_point)

end

function BaseInteractive:OnRelease(hand, model, grip_point)

end

function BaseInteractive:OnSimulationStep(hand, model, delta, grip_point)

end

function BaseInteractive:OnTriggerState(hand, model, finger_pressure, grip_point)

end

return BaseInteractive