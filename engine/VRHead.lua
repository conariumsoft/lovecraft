using "Lovecraft.BaseClass"
using "RBX.VRService"

local VRHead = BaseClass:subclass("VRHead")

local vr_base = game.Workspace.cameraPos

local local_camera = game.Workspace.CurrentCamera do
	local_camera.CameraSubject = vr_base
	local_camera.CameraType = Enum.CameraType.Scriptable
	local_camera.CFrame = CFrame.new(vr_base.Position)
end

function VRHead:__ctor(player)

    self.Camera = local_camera
    self.CFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)

    self.Player = player
end

function VRHead:Update(delta)
    self.CFrame = VRService:GetUserCFrame(Enum.UserCFrame.Head)
end


return VRHead