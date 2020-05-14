_G.using "RBX.ReplicatedStorage"

_G.using "Lovecraft.Networking"

local set_client_highlight = Networking.GenerateAsyncNetHook("SetClientHighlight")

local Module = {}

local is_highlighted = {}


function Module.SetPartHighlight(player, object, value, color)
    
    if player == nil then
        --set_client_highlight:FireAllClients(object, false)
        return
    end
    assert(object:IsA("BasePart"))
    assert(player:IsA("Player"))
    set_client_highlight:FireClient(player, object, value, color or {1,1,1})
end

function Module.SetModelHightlight(player, object, value, color)
    assert(object:IsA("Model") or object:IsA("Folder"), "")
    for _, part in pairs(object:GetDescendants()) do
        if part:IsA("BasePart") then
            Module.SetPartHighlight(player, part, value, color)
        end
    end
end

return Module