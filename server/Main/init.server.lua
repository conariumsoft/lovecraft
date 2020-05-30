require(game.ReplicatedStorage.Lovecraft.Lovecraft)

_G.log("Initializing server...")

_G.using "Lovecraft.Networking"
_G.using "Lovecraft.CollisionMasking"
_G.using "Lovecraft.Ownership"
_G.using "RBX.ReplicatedStorage"
_G.using "RBX.Workspace"
_G.using "RBX.PhysicsService"
_G.using "RBX.RunService"
_G.using "RBX.DataStoreService"

local testing_mode = RunService:IsStudio()

Workspace.Gravity = 30-- default 196.2
-------------------------------------------------------------------
-- Create remotes
Networking.Initialize()
local on_client_request_vr_state = Networking.GenerateNetHook     ("ClientRequestVRState")
local on_client_grab_object      = Networking.GenerateAsyncNetHook("ClientGrab")
local on_client_release_object   = Networking.GenerateAsyncNetHook("ClientRelease")


local on_client_request_inst  = Networking.GenerateNetHook     ("ClientRequestNewInst")

local dev_gravity_control        = Networking.GenerateAsyncNetHook("SetServerGravity")

-------------------------------------------------------------------
-- Physically interactive objects are set into appropriate collision group
for _, inst in pairs(Workspace.Physical:GetDescendants()) do
    if inst:IsA("BasePart") then
        if inst.Anchored == false then
            inst:SetNetworkOwner(nil)
        end
        PhysicsService:SetPartCollisionGroup(inst, "Interactives")
    end
end
---------------------------------------------------------------------------
-- load animations for hand models
require(script.loadanims) -- download and setup all animations
require(script.combat) -- combat manager

------------------------------------------------------------
-- server modules
local itemownerlist = require(script.itemownerlist)

-- Session Stats Collection --
-- Please note, this should not be used to store information the player sees or has access to.
-- This is intended for collecting information relevant to the developers to help make the game better.
local session_db
if not testing_mode then
session_db = DataStoreService:GetDataStore("SessionStats", "A")
end


local Defaults = {
    PlayTime = 0,
    TimesJoined = 0,
    TimesDied = 0,
    TimesShot = 0,
    TimesHit = 0,
    TimesGotShot = 0,
    TimesGotShotHead = 0,
    TimesGotShotBody = 0,
    TimesGotShotArm = 0,
}

local PlayerSessionStats = {

}


local function on_player_join(player)
    if not testing_mode then -- don't bother if we're in studio
        local session_stats = {}
        local success, errmsg = pcall(function()
            session_stats = session_db:GetAsync("plr"..player.UserId)
        end)

        for i, v in pairs(Defaults) do
            if session_stats[i] == nil then session_stats[i] = Defaults[i] end
        end
        PlayerSessionStats[player] = session_stats
        PlayerSessionStats[player].TimesJoined = PlayerSessionStats[player].TimesJoined + 1
    end

    player.CharacterAdded:Connect(function(char)
        char.HeadJ.BillboardGui.TextLabel.Text = player.Name
    end)
end

local function on_player_leave(player)
    if not testing_mode then
        session_db:SetAsync("plr"..player.UserId, PlayerSessionStats[player])
    end
end

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

   -- if grabbed.Anchored == true then return end
    if not grabbed:FindFirstChild("GripPoint") then return end
    --if grabbed.GripPoint.Value == true then return end
    -- TODO: Make new hand exclusion system

    local entry = itemownerlist.GetEntry(object, true)

    -- currently owned by nobody...
    if entry.owner == nil then
        itemownerlist.SetEntryOwner(object, player)
    end
    -- we own it :D
    if entry.owner == player then
        itemownerlist.SetEntryState(object, handstr, true)
        Ownership.SetModelNetworkOwner(object, player)
    end
end

local function on_plr_drop_object(player, object_ref, grabbed_part, handstr)
    if grabbed_part.Anchored                        then return end
    if not grabbed_part:FindFirstChild("GripPoint") then return end
   -- if not grabbed_part.GripPoint.Value             then return end

    local entry = itemownerlist.GetEntry(object_ref, false)

    if entry.owner ~= player then return end

    itemownerlist.SetEntryState(object_ref, handstr, false)

    -- we are no longer grabbing anywhere...
    if (entry.Left == false) and (entry.Right == false) then
        itemownerlist.SetEntryOwner(object_ref, nil)
        -- ! oh asynchronous lua
        delay(3, function()
            if entry.owner == nil then
                Ownership.SetModelNetworkOwner(object_ref, nil)
            end
        end)
    end
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

local GIVE_PLAYER_ALL_OWNERSHIP = false

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
        end
    end


    local plr_left = player.Character:WaitForChild("LHand")
    local plr_right = player.character:WaitForChild("RHand")

    plr_left.PrimaryPart.Anchored = false
    plr_right.PrimaryPart.Anchored = false

    -- assign networkownership
    plr_left.PrimaryPart:SetNetworkOwner(player)
    plr_right.PrimaryPart:SetNetworkOwner(player)

    -- create animator 
    local left_a = Instance.new("Animator")
    left_a.Parent = plr_left.Animator

    local right_a = Instance.new("Animator")
    right_a.Parent = plr_right.Animator

    -- set collision groups
    CollisionMasking.SetModelGroup(plr_left, "LeftHand")
    CollisionMasking.SetModelGroup(plr_right, "RightHand")
    return true
end


local function server_update(server_run_time, tick_dt)
    for player, data in pairs(PlayerSessionStats) do
        data.PlayTime = data.PlayTime + tick_dt
    end
end

local function on_gravity_change(player, value)
    Workspace.Gravity = value
end


on_client_grab_object.OnServerEvent:Connect(on_plr_grab_object)
on_client_release_object.OnServerEvent:Connect(on_plr_drop_object)
dev_gravity_control.OnServerEvent:Connect(on_gravity_change)
on_client_request_vr_state.OnServerInvoke = OnClientRequestVRState

RunService.Stepped:Connect(server_update)

game.Players.PlayerAdded:Connect(on_player_join)
game.Players.PlayerRemoving:Connect(on_player_leave)
