_G.using "Lovecraft.BaseClass"
_G.using "Lovecraft.SoftWeld"
_G.using "RBX.Workspace"
_G.using "RBX.VRService"

local VRHead = BaseClass:subclass("VRHead")

local player = game.Players.LocalPlayer
local char = player.CharacterAdded:Wait()
local vr_base = char:WaitForChild("HumanoidRootPart")

local local_camera = game.Workspace.CurrentCamera

function VRHead:__ctor(player)

    -- TODO: make character model control the positioning
    -- of VR components

    self.Camera = local_camera
    self.Player = player
    self.VRHeadsetCFrame = CFrame.new(0,0,0)

    --[[local base_station = Instance.new("Part") do
        base_station.CFrame = vr_base.CFrame
        base_station.Size = Vector3.new(0.2, 0.2, 0.2)
        base_station.Anchored = true
        base_station.CanCollide = false
        base_station.Transparency = 1
        base_station.Color = Color3.new(0.5, 0.5, 1)
        base_station.Name = "BaseStation"
        base_station.Parent = Workspace
    end]]
    -- :?????
    self.BaseStation = vr_base

    local virtual_head = Instance.new("Part") do 
		-- reference position for VRHand reported position
		virtual_head.Size = Vector3.new(0.2,0.2,0.2)
		virtual_head.Anchored = true
		virtual_head.CanCollide = false
		virtual_head.Transparency = 1
		virtual_head.Color = Color3.new(0.5, 0.5, 1)
		virtual_head.Name = "VirtualHead"
		virtual_head.Parent = Workspace
    end

    -- requested position...
    self.VirtualHead = virtual_head
    
    local phys_head = Instance.new("Part") do
        -- reference position for VRHand reported position
		phys_head.Size = Vector3.new(1,1,1)
		phys_head.Anchored = false
		phys_head.CanCollide = false
		phys_head.Transparency = 1
		phys_head.Color = Color3.new(0.5, 0.5, 1)
		phys_head.Name = "PhysicalHead"
		phys_head.Parent = Workspace
    end
    -- align camera to this object
    self.PhysicalHead = phys_head

    self._HeadAlignmentWeld = SoftWeld:new(self.VirtualHead, self.PhysicalHead, {
        rot_responsiveness = 125,
        pos_max_force = 120000,
        rot_max_angular_velocity = 120000,
    })
end

--[[

]]

local eye_level_above_center = 1.5
local eye_forward_pos = 0.5
function VRHead:Update(delta)
    if _G.VR_DEBUG == false then
        self.VRHeadsetCFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)
    end

    self.VirtualHead.CFrame = (CFrame.new(self.BaseStation.Parent.Head.CFrame.p)
        * self.VRHeadsetCFrame)
        * CFrame.new(0, eye_level_above_center, -eye_forward_pos) 

    local rx, ry, rz = self.VRHeadsetCFrame:ToEulerAnglesXYZ()

    self.BaseStation.CFrame = CFrame.new(self.BaseStation.CFrame.p) * CFrame.Angles(0, rz, 0)

    Workspace.CurrentCamera.CFrame = self.VirtualHead.CFrame 
end

function VRHead:Teleport(coord)
    self.VirtualHead.CFrame = coord
    self.PhysicalHead.CFrame = coord
end


return VRHead