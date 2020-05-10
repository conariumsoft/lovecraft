_G.using "Lovecraft.SoftWeld"
_G.using "RBX.Workspace"
_G.using "RBX.VRService"

local VRHead = _G.newclass("VRHead")

local player = game.Players.LocalPlayer
local char = player.CharacterAdded:Wait()
local local_camera = game.Workspace.CurrentCamera
-----------------------------------------------------
-- config?

local camera_smooth = 0.5 -- higher values = faster camera
-----------------------------------------------------

function VRHead:__ctor(player)

    -- TODO: make character model control the positioning
    -- of VR components
    self.FlickRotation = 0
    self.Camera = local_camera
    self.Player = player
    self.VRHeadsetCFrame = CFrame.new(0,0,0)
    self.DebugMouseVec2 = Vector2.new(0, 0)

    -- movement invoked by joysticks, rotation flicking, etc.
    -- combined with VRHeadsetCFrame to achieve final po sition.
    self.TranslatedPosition = CFrame.new(0, 0, 0)
    
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
end

function VRHead:Update(delta)

    -- do nothing else.
    if _G.VR_DEBUG ~= true then
        -- get latest head cframe
        self.VRHeadsetCFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)
    end
    -- we just want the position. rot doesnt matter.
    --self.TranslatedPosition = CFrame.new(char.HumanoidRootPart.CFrame.Position)
    self.TranslatedPosition = char.HumanoidRootPart.CFrame
    -- combine with translated pos to get camera pos.
    local headset_cf = self.VRHeadsetCFrame
    local control_cf = self.TranslatedPosition
    local flick_rt = self.FlickRotation
    local mouse_vec2 = self.DebugMouseVec2

    self.VirtualHead.CFrame = -- humanoidpos
        control_cf * 
        -- flick rotation
        CFrame.Angles(0, math.rad(flick_rt), 0) *
        CFrame.Angles(0, -mouse_vec2.X, 0) *
        CFrame.Angles(-mouse_vec2.Y, 0, 0)

    char.HeadJ.CFrame = headset_cf

    -- TODO: figure out how to do flickrotation without rotating around the HRP
    -- makes it feel weird...
    local ws_cc = Workspace.CurrentCamera

    ws_cc.CFrame = ws_cc.CFrame:Lerp(self.VirtualHead.CFrame, camera_smooth)

end

function VRHead:Teleport(coord)
    --self.VirtualHead.CFrame = coord
   -- self.PhysicalHead.CFrame = coord
end


return VRHead