-- Forward and Backward Reaching Inverse Kinematics
-- https://youtu.be/anQRPoNGVgc
local armik = {}


local elbow_power
local temp_centroid, centroid_pos

local function SolveBackward(end_effector_vec)
    temp_centroid = centroid_pos

    temp_hand = end_effector_vec


    local handtolower = (lower_pos - temp_hand).unit * lower_to_hand_dist
end


local function SolveForward(root_vec)

end
