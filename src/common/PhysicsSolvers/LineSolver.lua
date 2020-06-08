local Solver = require(script.Parent.Solver)

local GripLineSolver = Solver:subclass("GripLineSolver")

function GripLineSolver:__ctor(master_attach, follower_attach, props)
    Solver.__ctor(self, master_attach, follower_attach)
    local line_constraint = Instance.new("PrismaticConstraint") do
        line_constraint.ActuatorType = Enum.ActuactorType.Servo
    end
    self.line_constraint = line_constraint
end

function GripLineSolver:Enable()
    Solver.Enable(self)
    self.line_constraint.Enabled = true
end

function GripLineSolver:Disable()
    Solver.Disable(self)
    self.line_constraint.Enabled = false
end

function GripLineSolver:Destroy()
    Solver.Destroy(self)
    self.line_constraint:Destroy()
end

return GripLineSolver