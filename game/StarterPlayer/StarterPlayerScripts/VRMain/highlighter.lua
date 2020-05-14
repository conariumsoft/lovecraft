_G.using "RBX.ReplicatedStorage"
_G.using "Lovecraft.Networking"

local set_highlight = Networking.GetNetHook("SetClientHighlight")

set_highlight.OnClientEvent:Connect(function(part, value, color)
    if part == nil then return end
    -- add a new object
    if value == true then
        if part:FindFirstChild("DataHighlightBox") then
            part.DataHighlightBox.Color3 = Color3.new(color)
        else
            local obj = Instance.new("SelectionBox") do
                obj.Parent = part
                obj.Adornee = part
                obj.Color3 = color
                obj.LineThickness = 0
            end
            delay(0, function()
                for i = 1, 20 do
                    wait()
                    obj.LineThickness = i/2000
                end
            end)
        end
    end

    if value == false then
        if part:FindFirstChild("DataHighlightBox") then
            delay(0, function()
                for i = 1, 20 do
                    wait()
                    part.DataHighlightBox.LineThickness = i/2000
                end
                part.DataHighlightBox:Destroy()
            end)
        end
    end

end)

return true