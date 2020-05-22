local BaseInteractive = _G.newclass("InteractiveObject")

function BaseInteractive:__ctor(model)
    self.Model = model
end

function BaseInteractive:OnGrab(hand, grip_point)

end

function BaseInteractive:OnRelease(hand, grip_point)

end

function BaseInteractive:OnSimulationStep(hand, delta, grip_point)

end

function BaseInteractive:OnTriggerState(hand, finger_pressure, grip_point)

end

return BaseInteractive