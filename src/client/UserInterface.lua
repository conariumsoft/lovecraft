local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local UIModule = {}

function UIModule.SendWelcomeNotification()

end

function UIModule.DisableDefaultRobloxCrap()
    pcall(function()
        StarterGui:SetCore("VRLaserPointerMode", 0)
        StarterGui:SetCore("VREnableControllerModels", false)
        StarterGui:SetCore("TopbarEnabled", false)

        --?
        spawn(function()
            local VRFolder = Workspace.CurrentCamera:WaitForChild("VRCorePanelParts")
            while true do
                pcall(function()
                    VRFolder:WaitForChild("UserGui", math.huge).Parent = nil
                end)
            end
        end)
    end)
end

return UIModule