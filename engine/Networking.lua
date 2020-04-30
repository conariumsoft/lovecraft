_G.using "RBX.ReplicatedStorage"
_G.using "RBX.RunService"

local Networking = {}

function Networking.ServerSetup()
    local network_hook_folder = Instance.new("Folder") do
        network_hook_folder.Name = "NetworkHooks"
        network_hook_folder.Parent = ReplicatedStorage
    end
end

function Networking.GenerateNetHook(name)
    local sync = Instance.new("RemoteFunction")
    sync.Name = name
    sync.Parent = ReplicatedStorage.NetworkHooks

    return sync
end

function Networking.GenerateAsyncNetHook(name)
    local async = Instance.new("RemoteEvent")
    async.Name = name
    async.Parent = ReplicatedStorage.NetworkHooks
    return async
end

function Networking.GetNetHook(name)
    return ReplicatedStorage.NetworkHooks:FindFirstChild(name)
end

function Networking.GetAsyncNetHook(name)
    -- unused
end


return Networking