_G.using("Lovecraft.BaseClass")

local SoftWeld = BaseClass:subclass("SoftWeld")

---
-- @name ctor Softweld:new
--
--
--
function SoftWeld:__ctor(master_part, follower_part, props, visible)
    props = props or {}
    local pos_is_rigid = props.pos_is_rigid or false
    local pos_is_reactive = props.pos_is_reactive or false
    local pos_responsiveness = props.pos_responsiveness or 200
    local pos_max_force = props.pos_max_force or 30000
    local pos_max_velocity = props.pos_max_velocity or math.huge
    local rot_is_rigid = props.rot_is_rigid or false
    local rot_is_reactive = props.rot_is_reactive or false
    local rot_responsiveness = props.rot_responsiveness or 25
    local rot_max_angular_vel = props.rot_max_angular_vel or math.huge
    local rot_max_torque = props.rot_max_torque or 10000
    local rot_primary_axis_only = props.rot_primary_axis_only or false
    local visible = props.visible or false

    local cframe_offset = props.cframe_offset

    local master_att = Instance.new("Attachment")
    master_att.Parent = master_part
    master_att.Name = "SoftWeldMasterAttachment"

    local follower_att = Instance.new("Attachment")
    follower_att.Parent = follower_part
    follower_att.Name = "SoftWeldFollowerAttachment"

    if cframe_offset then
        master_att.CFrame = cframe_offset
    end


    local pos_constraint = Instance.new("AlignPosition") do
        pos_constraint.Name = "SoftWeldPositionConstraint"
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

---

function SoftWeld:Destroy()
    print("DIE!")
    self.master_attachment:Destroy()
    self.follower_attachment:Destroy()
    self.position_constraint:Destroy()
    self.rotation_constraint:Destroy()
end


return SoftWeld