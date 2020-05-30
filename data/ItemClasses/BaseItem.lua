local BaseInteractive = _G.newclass("InteractiveObject")

function BaseInteractive:__ctor(model)
    self.Model = model
    self.Grips = {}
    self.PrimaryControl = false
end

function BaseInteractive:OnGrab(hand, grip_point)
    self.Grips[grip_point] = hand
end

function BaseInteractive:OnRelease(hand, grip_point)
    self.Grips[grip_point] = nil
end

function BaseInteractive:OnSimulationStep(hand, delta, grip_point)

end

function BaseInteractive:OnTriggerState(hand, finger_pressure, grip_point)

end

return BaseInteractive