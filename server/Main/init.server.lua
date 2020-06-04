require(game.ReplicatedStorage.Lovecraft.Lovecraft)

_G.log("Initializing server...")

_G.using "Lovecraft.Networking"
_G.using "Lovecraft.CollisionMasking"
_G.using "Lovecraft.Ownership"
_G.using "RBX.ReplicatedStorage"
_G.using "RBX.Workspace"
_G.using "RBX.PhysicsService"
_G.using "RBX.RunService"

local skins = {
    ["Glock17"] = {
        ["Default"] = {
            ["FrostCoat700"] = {

            }
        }
    }
}


local GameModeClass = _G.newclass("Gamemode")

function GameModeClass:Start()
    self.LeaderboardConfiguration = {}
end

function GameModeClass:End()

end

local Loadout = _G.newclass("Loadout")

function Loadout:__ctor()
    self.PrimaryWeapon = {}
    self.SecondaryWeapon = {}
    self.PrimarySkin = nil
    self.SecondarySkin = nil
    self.PrimaryAttachments = {}
    self.SecondaryAttachments = {}
end


local testing_mode = RunService:IsStudio()

Workspace.Gravity = 30-- default 196.2
-------------------------------------------------------------------
-- Create remotes
Networking.Initialize()
local on_client_request_vr_state = Networking.GenerateNetHook     ("ClientDeploy")
local on_client_grab_object      = Networking.GenerateAsyncNetHook("ClientGrab")
local on_client_release_object   = Networking.GenerateAsyncNetHook("ClientRelease")
local dev_gravity_control        = Networking.GenerateAsyncNetHook("SetServerGravity")

local contentrepl = require(script.contentreplication)

for _, inst in pairs(Workspace.Physical:GetChildren()) do
    if _G.matches(inst.Name, {"Tec9", "Skorpion", "Glock17"}) then
        contentrepl.GodLoadGun(inst)
    end
end

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


local PlayerSessionStats = {}

local StatsProfile = require(script.StatsProfile)

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
    for player, statsprofile in pairs(PlayerSessionStats) do
        statsprofile:Increment("PlayTime", tick_dt)
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
