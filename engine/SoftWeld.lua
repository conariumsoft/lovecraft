_G.using("Lovecraft.BaseClass")

_G.ForceDirection = {
    FORWARD = 1,
    BACKWARD = 2,
    REACTIVE = 3,
}

--[[
				lhandmaxvel - 600
				lhandposforce - 15000
				rhandmaxangular - 250
				rhandmaxvel - 1000
				rhandposforce - 20000
				rhandrottorque - 250
			]]--

local function default(t, propname, default) -- default
	if t[propname] then
		return t[propname]
	else
		return default
	end
end

local AttachmentSet = BaseClass:subclass("AttachmentSet")

function AttachmentSet:__ctor(alphapart, betapart)
    assert(alphapart:IsA("BasePart"), "")
    assert( betapart:IsA("BasePart"), "")

    local alpha_att = Instance.new("Attachment")
    alpha_att.Parent = alphapart

    local beta_att = Instance.new("Attachment")
    beta_att.Parent = betapart

    self.AlphaPart = alphapart
    self.AlphaAttachment = alpha_att

    self.BetaPart = betapart
    self.BetaAttachment = beta_att

    self.AttachedSolvers = {
        
    }
end

function AttachmentSet:SetVisiblity(visibility)
    self.BetaAttachment.Visible = visibility
    self.AlphaAttachment.Visible = visibility
end

function AttachmentSet:Destroy()
    self.BetaAttachment:Destroy()
    self.AlphaAttachment:Destroy()
end

function AttachmentSet:ConnectSolver(solver)
    solver.Constraint.Attachment0 = x
    solver.Constraint.Attachment1 = y
end

function AttachmentSet:GetSolver()

end

function AttachmentSet:DisconnectSolver(solver)
    
end


-- set:AddSolver(Solver:new(...), _G.PartControlOrder.FORWARD)

-- just wrappers around ROBLOX's physics solvers.
local Solver = BaseClass:subclass("Solver")

function Solver:__ctor(props)
    self.AttachedTo = nil
end
function Solver:Attach(set, force_direction)

    -- determine which part gets force applied
    if force_direction == _G.ForceDirection.FORWARD then
        self.Constraint.Attachment0 = set.AlphaAttachment
        self.Constraint.Attachment1 = set.BetaAttachment
    elseif force_direction == _G.ForceDirection.BACKWARD then
        self.Constraint.Attachment0 = set.BetaAttachment
        self.Constraint.Attachment1 = set.AlphaAttachment
    elseif force_direction == _G.ForceDirection.REACTIVE then
        -- TODO: aaa
    end

    self.AttachedTo = set
end
function Solver:Detach()
    self.Constraint.Attachment0 = nil
    self.Constraint.Attachment1 = nil
    self.AttachedTo = nil
end

local PositionSolver = Solver:subclass("PositionSolver")
function PositionSolver:__ctor(p, ...)
    Solver.__ctor(self, p, ...) -- super
    -- p: table of properties
    -- c: AlignPosition constraint instance
    -- default(table, property, default) = value
    local c = Instance.new("AlignPosition")
    c.ApplyAtCenterOfMass  = default(p, "ApplyAtCenterOfMass",  false)
    c.MaxForce             = default(p, "MaxForce",             30000)
    c.MaxVelocity          = default(p, "MaxVelocity",          1000000)
    c.Responsiveness       = default(p, "Responsiveness",       100)
    c.ReactionForceEnabled = default(p, "ReactionForceEnabled", false)
    c.RigidityEnabled      = default(p, "RigidityEnabled",      false)
    c.Visible              = false

    self.Constraint = c
end


local RotationSolver = Solver:subclass("RotationSolver")


local SoftWeld = BaseClass:subclass("SoftWeld")

---
-- @name ctor Softweld:new
function SoftWeld:__ctor(master_part, follower_part, props)
    props = props or {}
    local pos_enabled = props.pos_enabled or true
    local rot_enabled = (props.rot_enabled~=nil) and props.rot_enabled or true
    local pos_is_rigid = props.pos_is_rigid or false
    local pos_is_reactive = props.pos_is_reactive or false
    local pos_responsiveness = props.pos_responsiveness or 200
    local pos_max_force = props.pos_max_force or 30000
    local pos_max_velocity = props.pos_max_velocity or math.huge
    local rot_is_rigid = props.rot_is_rigid or false
    local rot_is_reactive = props.rot_is_reactive or false
    local rot_responsiveness = props.rot_responsiveness or 200
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