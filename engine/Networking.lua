_G.using "RBX.ReplicatedStorage"
_G.using "RBX.RunService"

local Networking = {}

function Networking.Initialize()
    if not RunService:IsServer() then error() end
    local network_hook_folder = Instance.new("Folder") do
        network_hook_folder.Name = "NetworkHooks"
        network_hook_folder.Parent = ReplicatedStorage
    end
end

function Networking.GenerateNetHook(name)
    if not RunService:IsServer() then error() end
    local sync = Instance.new("RemoteFunction")
    sync.Name = name
    sync.Parent = ReplicatedStorage.NetworkHooks

    return sync
end

function Networking.GenerateAsyncNetHook(name)
    if not RunService:IsServer() then error() end
    local async = Instance.new("RemoteEvent")
    async.Name = name
    async.Parent = ReplicatedStorage.NetworkHooks
    return async
end

function Networking.GetNetHook(name)
    return ReplicatedStorage.NetworkHooks:FindFirstChild(name)
end



return Networking