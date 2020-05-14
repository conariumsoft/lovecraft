local Solver = require(script.Parent.Solver)

local RotationSolver = Solver:subclass("SoftWeld")

function RotationSolver:__ctor(master_part, follower_part, 
    max_torque, max_angular_vel, responsiveness, rigid, reactive, primary_only)

    Solver.__ctor(self, master_part, follower_part)

   --[[ local rot_is_rigid = props.rot_is_rigid or false
    local rot_is_reactive = props.rot_is_reactive or false
    local rot_responsiveness = props.rot_responsiveness or 200
    local rot_max_angular_vel = props.rot_max_angular_vel or 1000--math.huge
    local rot_max_torque = props.rot_max_torque or 5000
    local rot_primary_axis_only = props.rot_primary_axis_only or false]]

    max_torque = max_torque or 5000
    max_angular_vel = max_angular_vel or 1000
    responsiveness = responsiveness or false
    rigid = rigid or false
    primary_only = primary_only or false

   --local master_offset = props.master_offset
   -- local follower_offset = props.follower_offset

   -- if master_offset then
     --   self.master_attachment.CFrame = master_offset
   -- end

   -- if follower_offset then
   --     self.follower_attachment.CFrame = follower_offset
   -- end
end



return RotationSolver