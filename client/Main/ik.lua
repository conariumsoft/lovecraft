_G.using "Lovecraft.Math3D"
_G.using "Lovecraft.Kinematics"
local module = {}


local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:wait()


-- BODY PARTS --
local ch_larm_a = character.LeftUpperArm
local ch_larm_b = character.LeftLowerArm
local ch_rarm_b = character.RightLowerArm
local ch_rarm_a = character.RightUpperArm
local ch_lleg_a = character.LeftUpperLeg
local ch_lleg_b = character.LeftLowerLeg
local ch_rleg_a = character.RightUpperLeg
local ch_rleg_b = character.RightLowerLeg

local lhand = character.LHand
local rhand = character.RHand

----------------------------------------------------------------------------------------
-- ? BODY KINEMATICS DATA --
local ik_upper_arm_bone_len = 1
local ik_lower_arm_bone_len = 1
local ik_upper_leg_bone_len = 1.3
local ik_lower_leg_bone_len = 1.5
local ik_shoulder_width = 0.7
local ik_shoulder_height = 0.8
local ik_hip_level = 2.5
local ik_hip_width = 0.4

-- these are torso-relative offsets...
local left_shoulder_offset  = CFrame.new( -ik_shoulder_width, -ik_shoulder_height, 0)
local right_shoulder_offset =  CFrame.new(ik_shoulder_width,  -ik_shoulder_height, 0)
local left_hip_offset = CFrame.new(-ik_hip_width, -ik_hip_level, -0.2)
local right_hip_offset = CFrame.new(ik_hip_width, -ik_hip_level, -0.2)

local VECTOR3_UP = Vector3.new(0, 1, 0)
local VECTOR3_DOWN = Vector3.new(0, -1, 0)

local goal_lfoot_pos = character.HumanoidRootPart.Position
local goal_rfoot_pos = character.HumanoidRootPart.Position

local intermediate_lfoot = character.HumanoidRootPart.Position
local intermediate_rfoot = character.HumanoidRootPart.Position

local ldist = 0
local rdist = 0
local left = true

local dist = 0

local lastlpos = character.HumanoidRootPart.Position
local lastrpos = character.HumanoidRootPart.Position

local lastrhold =  character.HumanoidRootPart.Position
local lastlhold =  character.HumanoidRootPart.Position

function module.RenderStep(base_cf)
    do
        ----------------------------------------------------------------------------------
        -- Arms --
        -- SolveArm is less robust in it's solving schema, but it returns useful angles for arms and such.
        -- Not truly "constrained", just being applied cleverly though
        local l_shoulder_origin = base_cf * left_shoulder_offset
        local r_shoulder_origin = base_cf * right_shoulder_offset
        local up_vec3 = VECTOR3_UP * ik_upper_arm_bone_len--VECTOR3_UP * ch_larm_a.Size
        local lo_vec3 = VECTOR3_UP * ik_lower_arm_bone_len--VECTOR3_UP * ch_larm_b.Size
        local l_goal = lhand.Palm.Wrist.WorldPosition
        local r_goal = rhand.Palm.Wrist.WorldPosition
        local lplanecf, 
            lshoulder_theta, 
            lelbow_theta = Kinematics.Solver.SolveArm(l_shoulder_origin, l_goal, up_vec3.Y, lo_vec3.Y)

        local rplanecf,
            rshoulder_theta,
            relbow_theta = Kinematics.Solver.SolveArm(r_shoulder_origin, r_goal, up_vec3.Y, lo_vec3.Y)

        local l_shoulder_angle_cf = CFrame.Angles(lshoulder_theta, 0, 0)
        local l_elbow_angle_cf    = CFrame.Angles(lelbow_theta,    0, 0)
        local r_shoulder_angle_cf = CFrame.Angles(rshoulder_theta, 0, 0)
        local r_elbow_angle_cf    = CFrame.Angles(relbow_theta,    0, 0)

        ch_larm_a.CFrame = lplanecf * l_shoulder_angle_cf * CFrame.new(-up_vec3 * 0.5)
        ch_rarm_a.CFrame = rplanecf * r_shoulder_angle_cf * CFrame.new(-up_vec3 * 0.5)
        ch_larm_b.CFrame = ch_larm_a.CFrame *  CFrame.new(-up_vec3 * 0.5) * l_elbow_angle_cf * CFrame.new(-lo_vec3 * 0.5)
        ch_rarm_b.CFrame = ch_rarm_a.CFrame *  CFrame.new(-up_vec3 * 0.5) * r_elbow_angle_cf * CFrame.new(-lo_vec3 * 0.5)
        ----------------------------------------------------------------------------------
    end
    do
        local l_hip_origin = base_cf * left_hip_offset
        local r_hip_origin = base_cf * right_hip_offset


        local lleg_ray = Ray.new(l_hip_origin.Position, Vector3.new(0, -3, 0))
        local rleg_ray = Ray.new(r_hip_origin.Position, Vector3.new(0, -3, 0))

        local lhit, lpos, lsurfacenormal, lmaterial = Workspace:FindPartOnRayWithWhitelist(lleg_ray, {Workspace.Map})
        local rhit, rpos, rsurfacenormal, rmaterial = Workspace:FindPartOnRayWithWhitelist(rleg_ray, {Workspace.Map})

        lpos = lpos or l_hip_origin.Position * Vector3.new(0, -3, 0)
        rpos = rpos or r_hip_origin.Position * Vector3.new(0, -3, 0)

        
        if left then
            dist = dist + (rpos-lastrpos).magnitude
        else
            dist = dist + (lpos-lastlpos).magnitude
        end

        if left then
            intermediate_lfoot = lastlhold:Lerp(lpos, dist/2)
            intermediate_rfoot = lastrhold
        else
            intermediate_rfoot = lastrhold:Lerp(rpos, dist/2)
            intermediate_lfoot = lastlhold
        end

        if dist > 2 then
            if left then
                lastlhold = lpos
            else
                lastrhold = rpos
            end
            left = not left
            dist = 0
        end

        lastlpos = lpos
        lastrpos = rpos

        --intermediate_rfoot = intermediate_rfoot:Lerp(goal_rfoot_pos, 0.2)
        --intermediate_lfoot = intermediate_lfoot:Lerp(goal_lfoot_pos, 0.2)

        local up_vec3 = VECTOR3_UP * ik_upper_leg_bone_len
        local lo_vec3 = VECTOR3_UP * ik_lower_leg_bone_len
        -- TODO: raycast down?
        local l_goal = intermediate_rfoot + Vector3.new(0, math.sin(ldist), 0)
        local r_goal = intermediate_lfoot + Vector3.new(0, math.sin(rdist), 0)
        local lplanecf,
            lhip_theta,
            lknee_theta = Kinematics.Solver.SolveArm(l_hip_origin, l_goal, up_vec3.Y, lo_vec3.Y)
        local rplanecf,
            rhip_theta,
            rknee_theta = Kinematics.Solver.SolveArm(r_hip_origin, r_goal, up_vec3.Y, lo_vec3.Y)
            --rknee_theta = Kinematics.Solver.SolveArm(CFrame.new(r_goal), r_hip_origin.Position, up_vec3.Y, lo_vec3.Y)

        local l_hip_angle_cf = CFrame.Angles(lhip_theta, 0, 0)
        local l_knee_angle_cf = CFrame.Angles(lknee_theta, 0, 0)
        local r_hip_angle_cf = CFrame.Angles(rhip_theta, 0, 0)
        local r_knee_angle_cf = CFrame.Angles(rknee_theta, 0, 0)

        ch_lleg_a.CFrame = lplanecf * l_hip_angle_cf * CFrame.new(-up_vec3 * 0.5)
        ch_rleg_a.CFrame = rplanecf * r_hip_angle_cf * CFrame.new(-up_vec3 * 0.5)
        ch_lleg_b.CFrame = ch_lleg_a.CFrame * CFrame.new(-up_vec3 * 0.5) * l_knee_angle_cf * CFrame.new(-lo_vec3 * 0.5)
        ch_rleg_b.CFrame = ch_rleg_a.CFrame * CFrame.new(-up_vec3 * 0.5) * r_knee_angle_cf * CFrame.new(-lo_vec3 * 0.5)
    end



    -- we are solving backwards. from hand to shoulder

    --[[
    solve_chain(
        ik_leftarm_chain, -- joints
        lhand.PrimaryPart.CFrame * CFrame.new(0, 0, 0.6), -- origin 
        (base_cf * CFrame.new(-ik_shoulder_width, -ik_shoulder_height, 0)).Position -- goal
    )

    solve_chain(
        ik_rightarm_chain,
        rhand.PrimaryPart.CFrame * CFrame.new(0, 0, 0.6),
        (base_cf * CFrame.new(ik_shoulder_width,  -ik_shoulder_height, 0)).Position
    )

    -- BODY PARTS --

    ch_larm_a.CFrame = Math3D.LineToCFrame(ik_leftarm_chain.joints[3].vec, ik_leftarm_chain.joints[2].vec) * CFrame.Angles(math.rad(90), 0, 0)
    ch_larm_b.CFrame = Math3D.LineToCFrame(ik_leftarm_chain.joints[2].vec, ik_leftarm_chain.joints[1].vec) * CFrame.Angles(math.rad(90), 0, 0)
    ch_rarm_a.CFrame = Math3D.LineToCFrame(ik_rightarm_chain.joints[3].vec, ik_rightarm_chain.joints[2].vec) * CFrame.Angles(math.rad(90), 0, 0)
    ch_rarm_b.CFrame = Math3D.LineToCFrame(ik_rightarm_chain.joints[2].vec, ik_rightarm_chain.joints[1].vec) * CFrame.Angles(math.rad(90), 0, 0)]]


end

return module