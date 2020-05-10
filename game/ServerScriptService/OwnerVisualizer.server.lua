--[[
local me = game.Workspace:WaitForChild("j9j1")
while true do
    wait(1/5)
    for _, part in pairs(me:GetDescendants()) do
        if part:IsA("BasePart") and part.Anchored == false then
            if part:GetNetworkOwner() ~= nil then
                if part:FindFirstChild("SelectionBox") == nil then
                    local selbox = Instance.new("SelectionBox")
                    selbox.Parent = part
                    selbox.Adornee = part
                    selbox.Color3 = Color3.new(1, 0, 1)
                    selbox.LineThickness = 0.025
                end
            else
                if part:FindFirstChild("SelectionBox") ~= nil then
                    part.SelectionBox:Destroy()
                end
            end
        end
    end
end]]