_G.using "Lovecraft.Math3D"
local module = {}


local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:wait()

-- BODY PARTS --
local ch_larm_a = character.LeftUpperArm
local ch_larm_b = character.LeftLowerArm
local ch_rarm_a = character.RightLowerArm
local ch_rarm_b = character.RightUpperArm
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
local ik_shoulder_width = 1.2
local ik_shoulder_height = 0.7

local ik_leftarm_chain = Kinematics.Chain:new({
	Kinematics.Joint:new(nil, 1),
	Kinematics.Joint:new(nil, ik_lower_arm_bone_len),
	Kinematics.Joint:new(nil, ik_upper_arm_bone_len),
})

local ik_rightarm_chain = Kinematics.Chain:new({
	Kinematics.Joint:new(nil, 1),
	Kinematics.Joint:new(nil, ik_lower_arm_bone_len),
	Kinematics.Joint:new(nil, ik_upper_arm_bone_len),
})

local ik_spine_chain
local ik_lleg_chain
local ik_rleg_chain

local function solve_chain(chain, origin, goal)
	chain.origin = origin
	chain.target = goal
	chain.joints[1].vec = chain.origin.p
	Kinematics.Solver.Solve(chain)
end


function module.RenderStep(base_cf)
    -- we are solving backwards. from hand to shoulder

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
    ch_rarm_b.CFrame = Math3D.LineToCFrame(ik_rightarm_chain.joints[2].vec, ik_rightarm_chain.joints[1].vec) * CFrame.Angles(math.rad(90), 0, 0)
end

return module