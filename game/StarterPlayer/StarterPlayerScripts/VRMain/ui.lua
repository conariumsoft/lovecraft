_G.using "RBX.StarterGui"

local UIModule = {}

function UIModule.SendWelcomeNotification()

end

function UIModule.DisableDefaultRobloxCrap()

    StarterGui:SetCore("VRLaserPointerMode", 0)
    StarterGui:SetCore("VREnableControllerModels", false)
    
    --?
    spawn(function()
        local VRFolder = game.Workspace.CurrentCamera:WaitForChild("VRCorePanelParts")
        while true do
            pcall(function()
                VRFolder:WaitForChild("UserGui", math.huge).Parent = nil
            end)
        end
    end)
end

return UIModule