_G.using "RBX.ReplicatedStorage"
_G.using "Lovecraft.Networking"

local set_highlight = Networking.GetNetHook("SetClientHighlight")

set_highlight.OnClientEvent:Connect(function(part, value, color)
    if part == nil then return end
    -- add a new object
    if value == true then
        if part:FindFirstChild("DataHighlightBox") then
            part.DataHighlightBox.Color3 = Color3.new(unpack(color))
        else
            local obj = Instance.new("SelectionBox") do
                obj.Parent = part
                obj.Adornee = part
                obj.Color3 = Color3.new(unpack(color))
                obj.LineThickness = 0
                obj.Name = "DataHighlightBox"
            end
            delay(0, function()
                for i = 1, 30 do
                    obj.LineThickness = i/3000
                    wait()
                end
            end)
        end
    end

    if value == false then
        if part:FindFirstChild("DataHighlightBox") then
            delay(0, function()
                for i = 30, 0 do
                    part.DataHighlightBox.LineThickness = i/3000
                    wait()
                end
                part.DataHighlightBox:Destroy()
            end)
        end
    end

end)

return true