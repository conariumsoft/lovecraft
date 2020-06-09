print("Lovecraft Server init.")

local PhysicsService    = game:GetService("PhysicsService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScripts     = game:GetService("ServerScriptService")

local comm = ReplicatedStorage.Common

local Utils            = require(comm.Utils)
local CollisionMasking = require(comm.CollisionMasking)
local Ownership        = require(comm.Ownership)
local Shatter          = require(comm.Shatter)

local StatsProfile  = require(script.StatsProfile)
local LoadAnims     = require(script.LoadAnims) -- download and setup all animations
local Combat        = require(script.Combat) -- combat manager
local contentrepl   = require(script.ContentReplication)
local itemownerlist = require(script.ItemOwnerList)
local Ambience      = require(script.Ambience)
----------------------------------------------------------
-- Find all pre-spawned weapons & initialize them
-- TODO: change this...
LoadAnims()

for _, inst in pairs(Workspace.Physical:GetChildren()) do
    if Utils.Matches(inst.Name, {"Tec9", "Skorpion", "Glock17"}) then
        --contentrepl.GodLoadGun(inst)
    end
end
--

local testing_mode = RunService:IsStudio()

Workspace.Gravity = 30-- default 196.2

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

------------------------------------------------------------
-- server modules



local PlayerSessionStats = {}



local function drop_all_player_objects(player)
    itemownerlist.ClearEntriesOfPlayer(player)
end


local function on_player_join(player)
    local player_stats = StatsProfile:new(player)
    PlayerSessionStats[player] = player_stats

    player_stats:Increment("TimesJoined", 1)
    player.CharacterAdded:Connect(function(char)
        char.HeadJ.BillboardGui.TextLabel.Text = player.Name
        char.Humanoid.Died:Connect(function()
            drop_all_player_objects(player)
        end)
    end)
end

local function on_player_leave(player)
    PlayerSessionStats[player]:Save()
    PlayerSessionStats[player] = nil
end


-- TODO: Deal with grabbing in another script
local function on_plr_grab_object(player, object, grabbed, handstr)
    if not object then  return end
    if not grabbed then return end
    if not handstr then return end

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

-- fired by client (presumably) when ready to start VR game
-- load in hand models and setup animations
local function OnClientRequestVRState(player)
    print("Client Requested VR State")
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

    Ambience.Step(tick_dt)

    for player, statsprofile in pairs(PlayerSessionStats) do
        statsprofile:Increment("PlayTime", tick_dt)
    end
end

local function shatter(client, part, pos)
    if part.Name == "BreakableGlass" then
        spawn(function()
            Shatter(part, pos)
        end)
        
    end
end

local Networking = ReplicatedStorage.Networking

Networking.ClientGrab.OnServerEvent:Connect(on_plr_grab_object)
Networking.ClientRelease.OnServerEvent:Connect(on_plr_drop_object)
Networking.Shatter.OnServerEvent:Connect(shatter)
Networking.Deploy.OnServerInvoke = OnClientRequestVRState

RunService.Stepped:Connect(server_update)

game.Players.PlayerAdded:Connect(on_player_join)
game.Players.PlayerRemoving:Connect(on_player_leave)
