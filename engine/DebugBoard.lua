-- debug keyboard so josh can test VR lol
_G.using "RBX.UserInputService"

local mouse_rotation_speed = 0.125
local camera_rotation = Vector2.new(0, 0)

local human_move_vec = Vector2.new(0, 0)


local DebugBoard = {}

function DebugBoard.CorrectHandPositions(left_hand, right_hand)
    left_hand.VRControllerPosition = CFrame.new(-1, 0, -2)
	right_hand.VRControllerPosition = CFrame.new(1, 0, -2)
end

function DebugBoard.RenderStep(head, left_hand, right_hand)

    camera_rotation = camera_rotation + (
		UserInputService:GetMouseDelta()
		* math.rad(mouse_rotation_speed)
	)

    -- can move each hand in 3 degrees, and rotate in 3 degrees
    local l_mv_up       = UserInputService:IsKeyDown(Enum.KeyCode.Q)
    local l_mv_down     = UserInputService:IsKeyDown(Enum.KeyCode.A)
    local l_mv_left     = UserInputService:IsKeyDown(Enum.KeyCode.W)
    local l_mv_right    = UserInputService:IsKeyDown(Enum.KeyCode.S)
    local l_mv_back     = UserInputService:IsKeyDown(Enum.KeyCode.E)
    local l_mv_forward  = UserInputService:IsKeyDown(Enum.KeyCode.D)
    local l_roll_left   = UserInputService:IsKeyDown(Enum.KeyCode.R)
    local l_roll_right  = UserInputService:IsKeyDown(Enum.KeyCode.F)
    local l_pitch_left  = UserInputService:IsKeyDown(Enum.KeyCode.Z)
    local l_pitch_right = UserInputService:IsKeyDown(Enum.KeyCode.X)
    local l_yaw_left    = UserInputService:IsKeyDown(Enum.KeyCode.C)
    local l_yaw_right   = UserInputService:IsKeyDown(Enum.KeyCode.V)

    local r_mv_up       = UserInputService:IsKeyDown(Enum.KeyCode.Y)
    local r_mv_left     = UserInputService:IsKeyDown(Enum.KeyCode.H)
    local r_mv_down     = UserInputService:IsKeyDown(Enum.KeyCode.U)
    local r_mv_right    = UserInputService:IsKeyDown(Enum.KeyCode.J)
    local r_mv_forward  = UserInputService:IsKeyDown(Enum.KeyCode.I)
    local r_mv_back     = UserInputService:IsKeyDown(Enum.KeyCode.K)
    local r_roll_left   = UserInputService:IsKeyDown(Enum.KeyCode.O)
    local r_roll_right  = UserInputService:IsKeyDown(Enum.KeyCode.L)
    local r_pitch_left  = UserInputService:IsKeyDown(Enum.KeyCode.N)
    local r_pitch_right = UserInputService:IsKeyDown(Enum.KeyCode.M)
    local r_yaw_left    = UserInputService:IsKeyDown(Enum.KeyCode.Comma)
    local r_yaw_right   = UserInputService:IsKeyDown(Enum.KeyCode.Period)
    -- TODO: implement grabbing

    local dt = 1/80

    local lx = (l_mv_left and dt or 0) - (l_mv_right and dt or 0)
    local ly = (l_mv_up and dt or 0) - (l_mv_down and dt or 0)
    local lz = (l_mv_forward and dt or 0) - (l_mv_back and dt or 0)
    local lp = (l_pitch_left and dt or 0) - (l_pitch_right and dt or 0)
    local lyw= (l_yaw_left and dt or 0) - (l_yaw_right and dt or 0)
    local lr = (l_roll_left and dt or 0) - (l_roll_right and dt or 0)

    local rx = (r_mv_left and dt or 0) - (r_mv_right and dt or 0)
    local ry = (r_mv_up and dt or 0) - (r_mv_down and dt or 0)
    local rz = (r_mv_forward and dt or 0) - (r_mv_back and dt or 0)
    local rp = (r_pitch_left and dt or 0) - (r_pitch_right and dt or 0)
    local ryw= (r_yaw_left and dt or 0) - (r_yaw_right and dt or 0)
    local rr = (r_roll_left and dt or 0) - (r_roll_right and dt or 0)

    left_hand.VRControllerPosition = 
    left_hand.VRControllerPosition 
        * CFrame.new(lx, ly, lz)*CFrame.Angles(lp, lyw, lr)

    right_hand.VRControllerPosition = 
        right_hand.VRControllerPosition 
        * CFrame.new(rx, ry, rz)*CFrame.Angles(rp, ryw, rr)

    head.VRHeadsetCFrame = 
        CFrame.Angles(0, -camera_rotation.X, 0) *
        CFrame.Angles(-camera_rotation.Y, 0, 0)

    local x = 0
    local y = 0

    if UserInputService:IsKeyDown(Enum.KeyCode.KeypadEight) then x = 1  end -- forward
    if UserInputService:IsKeyDown(Enum.KeyCode.KeypadTwo)   then x = -1 end -- backward
    if UserInputService:IsKeyDown(Enum.KeyCode.KeypadFour)  then y = -1  end -- left
    if UserInputService:IsKeyDown(Enum.KeyCode.KeypadSix)   then y = 1 end -- right

    -- GAMER NOTE: make sure humanoid AutoRotate is off, or willn't work.
    head.BaseStation.Parent.Humanoid:Move(Vector3.new(y, 0, x), true)
end
--[[
    -- parabolic curve
    local function eq(x, steep, height, offset)
        return height - ((1/steep) * ( (x-offset)^2) ) )
    end
    local function eq2(x, )
    for x = start, finish, increments do

    end
]]

function DebugBoard.InputBegan(inp, my_left_hand, my_right_hand, head)
    -- manual left flicking
    if inp.KeyCode == Enum.KeyCode.Left then
        -- TODO: flick
        head.BaseStation.CFrame = head.BaseStation.CFrame * CFrame.Angles(0, math.rad(90), 0)
    end
    -- manual right flick
    if inp.KeyCode == Enum.KeyCode.Right then
        -- TODO: flick
        head.BaseStation.CFrame = head.BaseStation.CFrame * CFrame.Angles(0, -math.rad(90), 0)
    end

    if inp.KeyCode == Enum.KeyCode.LeftShift then
        my_left_hand:Grab()
        my_left_hand:SetGripCurl(1)
    end

    if inp.KeyCode == Enum.KeyCode.LeftControl then
        my_left_hand:SetIndexFingerCurl(1)
    end

    if inp.KeyCode == Enum.KeyCode.RightShift then
        my_right_hand:Grab()
        my_right_hand:SetGripCurl(1)
    end

    if inp.KeyCode == Enum.KeyCode.RightControl then
       my_right_hand:SetIndexFingerCurl(1)
    end
    if inp.KeyCode == Enum.KeyCode.Space then
        if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end
end

function DebugBoard.InputEnded(inp, my_left_hand, my_right_hand)

    if inp.KeyCode == Enum.KeyCode.LeftShift then
        my_left_hand:Release()
        my_left_hand:SetGripCurl(0)
    end

    if inp.KeyCode == Enum.KeyCode.LeftControl then
        my_left_hand:SetIndexFingerCurl(0)
    end

    if inp.KeyCode == Enum.KeyCode.RightShift then
        my_right_hand:Release()
        my_right_hand:SetGripCurl(0)
    end

    if inp.KeyCode == Enum.KeyCode.RightControl then
        my_right_hand:SetIndexFingerCurl(0)
    end
end


return DebugBoard