_G.ForceDirection = {
    FORWARD = 1,
    BACKWARD = 2,
    REACTIVE = 3,
}

local SoftWeld = _G.newclass("SoftWeld")
---
-- @name ctor Softweld:new
function SoftWeld:__ctor(master_part, follower_part, props)
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
    
    local visible = true

    local master_offset = props.master_offset
    local follower_offset = props.follower_offset

    local master_att = Instance.new("Attachment")
    master_att.Parent = master_part
    master_att.Name = "SoftWeldMasterAttachment"

    local follower_att = Instance.new("Attachment")
    follower_att.Parent = follower_part
    follower_att.Name = "SoftWeldFollowerAttachment"

    if master_offset then
        master_att.CFrame = master_offset
    end

    if follower_offset then
        follower_att.CFrame = follower_offset
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

        pos_constraint.Attachment0 = follower_att
		pos_constraint.Attachment1 = master_att
		
		pos_constraint.Parent = master_part
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

        rot_constraint.Attachment0 = follower_att
		rot_constraint.Attachment1 = master_att
		
		rot_constraint.Parent = master_part
    end

    self.master_part = master_part
    self.follower_part = follower_part
    self.master_attachment = master_att
    self.follower_attachment = follower_att
    self.position_constraint = pos_constraint
    self.rotation_constraint = rot_constraint
end

function SoftWeld:Enable()
    self.position_constraint.Enabled = true
    self.rotation_constraint.Enabled = true
end


function SoftWeld:Disable()
    self.position_constraint.Enabled = false
    self.rotation_constraint.Enabled = false
end

function SoftWeld:Destroy()
    self.master_attachment:Destroy()
    self.follower_attachment:Destroy()
    self.position_constraint:Destroy()
    self.rotation_constraint:Destroy()
end


return SoftWeld