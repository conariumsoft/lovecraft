_G.using "Lovecraft.Kinematics"

local Joint = Kinematics.Joint
local Chain = Kinematics.Chain

local r = math.rad

local shoulder_width = 1
local shoulder_height = 0.7

local upper_arm_bone_length = 1.1
local lower_arm_bone_length = 0.7
local wrist_bone_length = 0.1

-------------------------------------------------------------
-- left arm definitions
local left_arm_joints = {
    -- *                 pos, len, limit, left, right,  up, down
    shoulder = Joint.new(nil, upper_arm_bone_length, true, r(120), r(120), r(120), r(120)),
    elbow    = Joint.new(nil, lower_arm_bone_length, false, r(120), r(120), r(120), r(120)),
    wrist    = Joint.new(nil, wrist_bone_length,     true, r(89), r(89), r(89), r(89)),
}
local left_arm_chain = Chain.new({
    left_arm_joints.shoulder, left_arm_joints.elbow, left_arm_joints.wrist,
}, Vector3.new(0, 0, 0))

local left_arm_parts = {
    upper_arm = nil,
    lower_arm = nil,
    hand = nil
}
------------------------------------------------------------
-- right arm definitions
local right_arm_joints = {
    shoulder = Joint.new(nil, upper_arm_bone_length, true, r(120), r(120), r(120), r(120)),
    elbow    = Joint.new(nil, lower_arm_bone_length, false, r(89), r(89), r(89), r(89)),
    wrist    = Joint.new(nil, wrist_bone_length,     true, r(89), r(89), r(89), r(89)),
}
local right_arm_chain = Chain.new({
    right_arm_joints.shoulder, right_arm_joints.elbow, right_arm_joints.wrist
}, Vector3.new(0, 0, 0))

local right_arm_parts = {
    upper_arm = nil,
    lower_arm = nil,
    hand = nil,
}
------------------------------------------------------------
-- spine definitions
local spine_joints = {
    skull_base = nil,
    neck_base = nil,
    chest = nil,
    torso = nil,
}
local spine_chain = {}

local spine_parts = {
    head = nil,
    neck = nil,
    chest = nil,
    torso = nil,
}

local function ln()
    local part = Instance.new("Part")
    part.Material = Enum.Material.Plastic
    part.Anchored = true
    part.CanCollide = false
    part.Color = Color3.new(0, 0.5, 1)
    part.Parent = game.Workspace
    return part
end

local function drawline(part, vec3_a, vec3_b)
    part.Size = Vector3.new(0.1, 0.1, (vec3_b-vec3_a).magnitude)
    part.CFrame = CFrame.new(vec3_a:lerp(vec3_b, 0.5), vec3_b)
end

local function to_cf(veca, vecb)
    local v = (vecb - veca)
    return CFrame.new(veca + (v/2), vecb)
end
-------------------------------------------------------------
local bodymodule = {}

function bodymodule.SetSpine(body)

end

function bodymodule.SetLeftArm(upper, lower, hand)
    left_arm_parts.upper_arm = upper
    left_arm_parts.lower_arm = lower
    left_arm_parts.hand =      hand
end

function bodymodule.SetRightArm(upper, lower, hand)
    right_arm_parts.upper_arm = upper
    right_arm_parts.lower_arm = lower
    right_arm_parts.hand      = hand
end

local function pt()
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Size = Vector3.new(0.05, 0.05, 0.05)
    part.Color = Color3.new(1, 1, 0)
    part.Parent = game.Workspace
    return part
end

-- debug parts to display IK results
local lj1, lj2, lj3, lj4 = pt(), pt(), pt(), pt()
local ll1, ll2, ll3 = ln(), ln(), ln()

local rj1, rj2, rj3, rj4 = pt(), pt(), pt(), pt()
local rl1, rl2, rl3 = ln(), ln(), ln()


function bodymodule.Step(base_cf, lhand_goal_cf, rhand_goal_cf, torso_goal_cf)
    ------------------------------------------------------------------------------------------
    -- spine
    --spine_chain.origin = spine_origin
    --spine_chain.target = torso_goal_vec3

    --Kinematics.Solver.Solve(spine_chain)

    --spine_parts.abdomen.CFrame = to_cf(spine_joints.base, spine_joints.abdomen)
    --spine_parts.head.CFrame = to_cf(spine_joints.head, spine_joints.skull_base)
    --spine_parts.neck.CFrame = to_cf(spine_joints.skull_base, spine_joints.neck_base)
    --spine_parts.chest.CFrame = to_cf(spine_joints.neck_base, spine_joints.abdomen)
    --spine_parts.torso.CFrame = to_cf(spine_joints.abdomen, torso_goal_vec3)
    
    ------------------------------------------------------------------------------------------
    -- left hand
    left_arm_chain.origin = base_cf * CFrame.new(-shoulder_width, -shoulder_height, 0)

    left_arm_chain.target = (lhand_goal_cf* CFrame.new(0, -0.15, 0.5) ).Position

    left_arm_joints.shoulder.vec = left_arm_chain.origin.p

    Kinematics.Solver.Solve(left_arm_chain)

    lj1.Position = left_arm_chain.joints[1].vec
    lj2.Position = left_arm_chain.joints[2].vec
    lj3.Position = left_arm_chain.joints[3].vec

    drawline(ll1, left_arm_chain.joints[1].vec, left_arm_chain.joints[2].vec)
    drawline(ll2, left_arm_chain.joints[2].vec, left_arm_chain.joints[3].vec)

    --left_arm_parts.upper_arm.CFrame = to_cf(left_arm_joints.shoulder.vec, left_arm_joints.elbow.vec)
    --left_arm_parts.lower_arm.CFrame = to_cf(left_arm_joints.elbow.vec,    left_arm_joints.wrist.vec)
    --left_arm_parts.hand:SetPrimaryPartCFrame( ( CFrame.new(left_arm_joints.wrist.vec)*(lhand_goal_cf-lhand_goal_cf.p)  )  )

    ------------------------------------------------------------------------------------------
    -- right hand
    right_arm_chain.origin = base_cf * CFrame.new(shoulder_width, -shoulder_height, 0)
    right_arm_chain.target = rhand_goal_cf.Position
    right_arm_joints.shoulder.vec = right_arm_chain.origin.p

    Kinematics.Solver.Solve(right_arm_chain)

    rj1.Position = right_arm_chain.joints[1].vec
    rj2.Position = right_arm_chain.joints[2].vec
    rj3.Position = right_arm_chain.joints[3].vec

    drawline(rl1, right_arm_chain.joints[1].vec, right_arm_chain.joints[2].vec)
    drawline(rl2, right_arm_chain.joints[2].vec, right_arm_chain.joints[3].vec)

    --right_arm_parts.upper_arm.CFrame = to_cf(right_arm_joints.shoulder.vec, right_arm_joints.elbow.vec)--to_cf(right_arm_joints.shoulder.vec, right_arm_joints.elbow.vec)
    --right_arm_parts.lower_arm.CFrame = to_cf(right_arm_joints.elbow.vec,   right_arm_joints.wrist.vec)
    right_arm_parts.hand:SetPrimaryPartCFrame( ( CFrame.new(right_arm_joints.wrist.vec)*(rhand_goal_cf-rhand_goal_cf.p)  ) * CFrame.new(0, 0.17, -0.54) )
end



return bodymodule