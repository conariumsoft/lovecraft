-- debug keyboard so josh can test VR lol
local UserInputService = game:GetService("UserInputService")
local DebugBoard = {}

local dt = 1/30 -- hand movement speed

function DebugBoard.GetLeftHandDeltaCFrame()
  -- can move each hand in 3 degrees, and rotate in 3 degrees
	local l_mv_up       = UserInputService:IsKeyDown(Enum.KeyCode.W)
	local l_mv_down     = UserInputService:IsKeyDown(Enum.KeyCode.S)
	local l_mv_left     = UserInputService:IsKeyDown(Enum.KeyCode.A)
	local l_mv_right    = UserInputService:IsKeyDown(Enum.KeyCode.D)
	local l_mv_back     = UserInputService:IsKeyDown(Enum.KeyCode.E)
	local l_mv_forward  = UserInputService:IsKeyDown(Enum.KeyCode.Q) 
	local l_roll_left   = UserInputService:IsKeyDown(Enum.KeyCode.Z)
	local l_roll_right  = UserInputService:IsKeyDown(Enum.KeyCode.X)
	local l_pitch_left  = UserInputService:IsKeyDown(Enum.KeyCode.C)
	local l_pitch_right = UserInputService:IsKeyDown(Enum.KeyCode.V)
	local l_yaw_left    = UserInputService:IsKeyDown(Enum.KeyCode.R)
	local l_yaw_right   = UserInputService:IsKeyDown(Enum.KeyCode.F)


	local lx = (l_mv_left and dt or 0) - (l_mv_right and dt or 0)
    local ly = (l_mv_up and dt or 0) - (l_mv_down and dt or 0)
    local lz = (l_mv_forward and dt or 0) - (l_mv_back and dt or 0)
    local lp = (l_pitch_left and dt or 0) - (l_pitch_right and dt or 0)
    local lyw= (l_yaw_left and dt or 0) - (l_yaw_right and dt or 0)
	local lr = (l_roll_left and dt or 0) - (l_roll_right and dt or 0)
	
	return CFrame.new(lx, ly, lz)*CFrame.Angles(lp, lyw, lr)
end

function DebugBoard.GetRightHandDeltaCFrame()
	local r_mv_up       = UserInputService:IsKeyDown(Enum.KeyCode.I)
    local r_mv_left     = UserInputService:IsKeyDown(Enum.KeyCode.J)
    local r_mv_down     = UserInputService:IsKeyDown(Enum.KeyCode.K)
    local r_mv_right    = UserInputService:IsKeyDown(Enum.KeyCode.L)
    local r_mv_forward  = UserInputService:IsKeyDown(Enum.KeyCode.U)
    local r_mv_back     = UserInputService:IsKeyDown(Enum.KeyCode.P)
    local r_roll_left   = UserInputService:IsKeyDown(Enum.KeyCode.Period)
    local r_roll_right  = UserInputService:IsKeyDown(Enum.KeyCode.Comma)
    local r_pitch_left  = UserInputService:IsKeyDown(Enum.KeyCode.N)
    local r_pitch_right = UserInputService:IsKeyDown(Enum.KeyCode.M)
    local r_yaw_left    = UserInputService:IsKeyDown(Enum.KeyCode.Y)
	local r_yaw_right   = UserInputService:IsKeyDown(Enum.KeyCode.H)
	

	local rx = (r_mv_left and dt or 0) - (r_mv_right and dt or 0)
    local ry = (r_mv_up and dt or 0) - (r_mv_down and dt or 0)
    local rz = (r_mv_forward and dt or 0) - (r_mv_back and dt or 0)
    local rp = (r_pitch_left and dt or 0) - (r_pitch_right and dt or 0)
    local ryw= (r_yaw_left and dt or 0) - (r_yaw_right and dt or 0)
	local rr = (r_roll_left and dt or 0) - (r_roll_right and dt or 0)
	
	return CFrame.new(rx, ry, rz)*CFrame.Angles(rp, ryw, rr)
end


function DebugBoard.GetMovementDeltaVec2()
    
    -- forced movement...
    local x = 0
    local y = 0

    if UserInputService:IsKeyDown(Enum.KeyCode.KeypadEight) then x = -1  end -- forward
    if UserInputService:IsKeyDown(Enum.KeyCode.KeypadTwo)   then x = 1 end -- backward
    if UserInputService:IsKeyDown(Enum.KeyCode.KeypadFour)  then y = -1  end -- left
    if UserInputService:IsKeyDown(Enum.KeyCode.KeypadSix)   then y = 1 end -- right

	return Vector2.new(x, y)
    -- GAMER NOTE: make sure humanoid AutoRotate is off, or willn't work.
    --game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(y, 0, x), true)
end


return DebugBoard