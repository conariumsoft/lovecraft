_G.using "RBX.PhysicsService"
local Ownership = {}

function Ownership.SetModelNetworkOwner(model, network_owner)
    if model:IsA("BasePart") then
        model:SetNetworkOwner(network_owner)
    end

    for _, child in pairs(model:GetDescendants()) do
        Ownership.SetModelNetworkOwner(child, network_owner)
    end
end

return Ownership