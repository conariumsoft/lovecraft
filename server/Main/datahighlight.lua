_G.using "RBX.ReplicatedStorage"

_G.using "Lovecraft.Networking"

local set_client_highlight = Networking.GenerateAsyncNetHook("SetClientHighlight")


return function(player, object, value, color)
    
    
    assert(player:IsA("Player"))

    set_client_highlight:FireClient(player, object, value, color or {1,1,1})
end
