--[[
    Controls creation and collection

]]
local gib = Instance.new("Part") do
    gib.Color = Color3.new(0, 1, 0)
    gib.Anchored = false
    gib.CanCollide = false
    gib.Size = Vector3.new(0.1, 0.1, 0.1)
    gib.Transparency = 0.25
end

local function brainsplat(pos, direction)

    local p = gib:Clone()
end

return {
    BrainSplat = brainsplat
}