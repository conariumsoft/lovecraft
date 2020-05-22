local Solver = require(script.Parent.Solver)

local PointSolver = Solver:subclass("SoftWeld")
---
-- @name ctor PointSolver:new
function PointSolver:__ctor(master_attach, follower_attach, props)
    Solver.__ctor(self, master_attach, follower_attach)
    props = props or {}
    local pos_enabled = props.pos_enabled or true
    local rot_enabled = (props.rot_enabled~=nil) and props.rot_enabled or true
    local pos_is_rigid = props.pos_is_rigid or false
    local pos_is_reactive = props.pos_is_reactive or false
    local pos_responsiveness = props.pos_responsiveness or 200
    local pos_max_force = props.pos_max_force or 100000
    local pos_max_velocity = props.pos_max_velocity or 100000--math.huge
    local rot_is_rigid = props.rot_is_rigid or false
    local rot_is_reactive = props.rot_is_reactive or false
    local rot_responsiveness = props.rot_responsiveness or 200
    local rot_max_angular_vel = props.rot_max_angular_vel or 1000--math.huge
    local rot_max_torque = props.rot_max_torque or 5000
    local rot_primary_axis_only = props.rot_primary_axis_only or false
    
    -- TODO: phase attachment properties out of Solver classes
    local visible = true

    local master_offset = props.master_offset
    local follower_offset = props.follower_offset

    if master_offset then
        self.master_attachment.CFrame = master_offset
    end

    if follower_offset then
        self.follower_attachment.CFrame = follower_offset
    end

    local pos_constraint = Instance.new("AlignPosition") do
        pos_constraint.Name = "SoftWeldPositionConstraint"
        pos_constraint.Enabled              = pos_enabled
        pos_constraint.Visible = visible
        pos_constraint.RigidityEnabled      = pos_is_rigid
        pos_constraint.ReactionForceEnabled = pos_is_reactive
        pos_constraint.Responsiveness       = pos_responsiveness
        pos_constraint.MaxForce             = pos_max_force
        pos_constraint.MaxVelocity          = pos_max_velocity

        pos_constraint.Attachment0 = self.follower_attachment
		pos_constraint.Attachment1 = self.master_attachment
		
		pos_constraint.Parent = self.master_attachment
    end

    local rot_constraint = Instance.new("AlignOrientation") do

        rot_constraint.Name = "SoftWeldRotationConstraint"
        rot_constraint.Enabled               = rot_enabled
        rot_constraint.Visible = visible
        rot_constraint.MaxAngularVelocity    = rot_max_angular_vel
        rot_constraint.MaxTorque             = rot_max_torque
        rot_constraint.PrimaryAxisOnly       = rot_primary_axis_only
        rot_constraint.ReactionTorqueEnabled = rot_is_reactive
        rot_constraint.Responsiveness        = rot_responsiveness
        rot_constraint.RigidityEnabled       = rot_is_rigid

        rot_constraint.Attachment0 = self.follower_attachment
		rot_constraint.Attachment1 = self.master_attachment
		
		rot_constraint.Parent = self.master_attachment
    end

    self.position_constraint = pos_constraint
    self.rotation_constraint = rot_constraint
end

function PointSolver:Enable()
    Solver.Enable(self)
    self.position_constraint.Enabled = true
    self.rotation_constraint.Enabled = true
end

function PointSolver:Disable()
    Solver.Disable(self)
    self.position_constraint.Enabled = false
    self.rotation_constraint.Enabled = false
end

function PointSolver:Destroy()
    Solver.Destroy(self)
    self.position_constraint:Destroy()
    self.rotation_constraint:Destroy()
end


return PointSolver