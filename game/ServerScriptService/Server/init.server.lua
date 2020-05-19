require(game.ReplicatedStorage.Lovecraft.Lovecraft)

_G.log("Initializing server...")

_G.using "Lovecraft.Networking"
_G.using "Lovecraft.CollisionMasking"
_G.using "Lovecraft.Ownership"
_G.using "RBX.ReplicatedStorage"
_G.using "RBX.Workspace"
_G.using "RBX.PhysicsService"
_G.using "RBX.RunService"

-------------------------------------------------------------------
-- Gameserver setup --

-- create remotes folder first
Networking.CreateHookContainer()

-- drop interactive objects into appropriate collisiongroup
for _, child in pairs(Workspace.physics:GetDescendants()) do
    if child:IsA("BasePart") then
        child:SetNetworkOwner(nil)
        PhysicsService:SetPartCollisionGroup(child, "Interactives")
    end
end

-- load animations for hand models
require(script.loadanims)()


local givehands = require(script.givehands)
local itemownerlist = require(script.itemownerlist)
local data_highlight = require(script.datahighlight)


--- Remotes

-- client init
local on_client_request_vr_state = Networking.GenerateNetHook("ClientRequestVRState")



-- Player Object Control --
local on_client_grab_object = Networking.GenerateAsyncNetHook("ClientGrab")
local on_client_release_object = Networking.GenerateAsyncNetHook("ClientRelease")

local function on_plr_grab_object(player, object, grabbed, handstr)
    if not object then
        _G.log("ignoring grab request: player passed nil object")
        return
    end
    if not grabbed then 
        _G.log("ignoring grab request: player passed nil grabpoint")
        return
    end
    if not handstr then
        _G.log("ignoring grab request: player passed nil handstr")
        return
    end

    if grabbed.Anchored == true then return end
    if not grabbed:FindFirstChild("GripPoint") then return end
    if grabbed.GripPoint.Value == true then return end

    local entry = itemownerlist.GetEntry(object, true)

    -- currently owned by nobody...
    if entry.owner == nil then
        itemownerlist.SetEntryOwner(object, player)
        --set_model_collision_group(object, "Grabbed"..handstr)
    end

    -- we own it :D
    if entry.owner == player then
 
        itemownerlist.SetEntryState(object, handstr, true)

        Ownership.SetModelNetworkOwner(object, player)
        data_highlight(player, object, true)
        grabbed.GripPoint.Value = true
    end
end

local function on_plr_drop_object(player, object_ref, grabbed_part, handstr)
    if grabbed_part.Anchored                        then return end
    if not grabbed_part:FindFirstChild("GripPoint") then return end
    if not grabbed_part.GripPoint.Value             then return end

    local entry = itemownerlist.GetEntry(object_ref, false)

    if entry.owner ~= player then return end

    itemownerlist.SetEntryState(object_ref, handstr, false)

    -- we are no longer grabbing anywhere...
    if (entry.Left == false) and (entry.Right == false) then
        itemownerlist.SetEntryOwner(object_ref, nil)
        -- ! oh asynchronous lua
        delay(3, function()
            if entry.owner == nil then
                data_highlight(player, object_ref, false)
                Ownership.SetModelNetworkOwner(object_ref, nil)
            end
        end)
    end

    grabbed_part.GripPoint.Value = false
    
end
-----------------------------------------------------------------

-- parts of a player's body that we need networkownership of
-- set correct collision groups on as well
local auxiliary_parts = {
    "TorsoJ", "HeadJ", "LeftFoot",
    "LeftLowerArm", "LeftLowerLeg",
    "LeftUpperArm", "LeftUpperLeg",
    "RightFoot", "RightLowerArm",
    "RightLowerLeg", "RightUpperArm",
    "RightUpperLeg", "HumanoidRootPart"
}

-- fired by client (presumably) when ready to start VR game
-- load in hand models and setup animations
local function OnClientRequestVRState(player)
    _G.log("Client Requested VR State")
    for _, name in pairs(auxiliary_parts) do
        local part = player.Character:FindFirstChild(name)
        if part then
            part.Anchored = false
        end
    end
    for _, name in pairs(auxiliary_parts) do
        local part = player.Character:FindFirstChild(name)
        if part then

            PhysicsService:SetPartCollisionGroup(part, "Body")
            part:SetNetworkOwner(player)
            --part.CanCollide = false
            --part.Anchored = true
            --.CanCollide = false
        end
    end

    -- create hand models for player
    -- assign networkownership
    -- set collision groups
    -- create animator 
    givehands(player)
    return true
end


local on_client_shoot = Networking.GenerateAsyncNetHook("ClientShoot")
local on_client_hit = Networking.GenerateAsyncNetHook("ClientHit")


local function client_reflect_gunshot(client, weapon)
    on_client_shoot:FireAllClients(client, weapon)
end

-- ? no hit verification?
-- yes. this is bad. extremely bad.
-- don't worry, hit verification will be implemented before
-- public testing.
local function client_hit_enemy(client, enemy, weapon)

end

on_client_shoot.OnServerEvent:Connect(client_reflect_gunshot)
on_client_hit.OnServerEvent:Connect(client_hit_enemy)


local function server_update(server_run_time, tick_dt)

end

on_client_grab_object.OnServerEvent:Connect(on_plr_grab_object)
on_client_release_object.OnServerEvent:Connect(on_plr_drop_object)
on_client_request_vr_state.OnServerInvoke = OnClientRequestVRState

RunService.Stepped:Connect(server_update)
game.Players.PlayerAdded:Connect(function(plr)
    local c = plr.Character or plr.CharacterAdded:Wait()
    c.HeadJ.BillboardGui.TextLabel.Text = plr.Name
end)