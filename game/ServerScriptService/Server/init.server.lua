require(game.ReplicatedStorage.Lovecraft.Lovecraft)

_G.log("Initializing server...")

_G.using "Lovecraft.Networking"
_G.using "Lovecraft.CollisionMasking"
_G.using "Lovecraft.Ownership"
_G.using "RBX.ReplicatedStorage"
_G.using "RBX.Workspace"
_G.using "RBX.PhysicsService"


local givehands = require(script.givehands)

-- init physical objects
for _, child in pairs(Workspace.physics:GetDescendants()) do
    if child:IsA("BasePart") then
        child:SetNetworkOwner(nil)
        PhysicsService:SetPartCollisionGroup(child, "Interactives")
    end
end

--- Hand Animation loading
-- load objects on server initially (permits client replication)
-- create folders
local anims_folder = Instance.new("Folder") do
    anims_folder.Name = "Animations"
    anims_folder.Parent = ReplicatedStorage
end
local lf = Instance.new("Folder") do
    lf.Name = "Left"
    lf.Parent = anims_folder
end
local rf = Instance.new("Folder") do
    rf.Name = "Right"
    rf.Parent = anims_folder
end

local function LoadAnimation(folder, name, id)
	local anim = Instance.new("Animation")
    anim.AnimationId = id
    anim.Name = name
	anim.Parent = folder
	return anim
end

-- anim IDs
local left_hand_animation_defs = {
  --{"AnimName",   "AssetIDString"          },
    {"Index",      "rbxassetid://4921338211"},
    {"Grip",       "rbxassetid://4921113867"},

}

local right_hand_animation_defs = {
  --{"AnimName",   "AssetIDString"          },
    {"Index",      "rbxassetid://4921265382"},
    {"Grip",       "rbxassetid://4921074129"},

}

-- load sets
for _, data in pairs(left_hand_animation_defs) do
    LoadAnimation(lf, data[1], data[2])
end

for _, data in pairs(right_hand_animation_defs) do
    LoadAnimation(rf, data[1], data[2])
end


--- Remotes
-- create folder
Networking.CreateHookContainer()
-- client init
local on_client_request_vr_state = Networking.GenerateNetHook("ClientRequestVRState")

local on_client_grip_state = Networking.GenerateAsyncNetHook("ClientGripState")
local on_client_pointer_state = Networking.GenerateAsyncNetHook("ClientPointerState")
local on_client_grab_object = Networking.GenerateAsyncNetHook("ClientGrab")
local on_client_release_object = Networking.GenerateAsyncNetHook("ClientRelease")
local on_client_trigger_down = Networking.GenerateAsyncNetHook("ClientTriggerDown")
local on_client_trigger_up = Networking.GenerateAsyncNetHook("ClientTriggerUp")



local function OnClientGrabObject(player, object, grabbed)

    if grabbed:FindFirstChild("GripPoint") then

        if grabbed.GripPoint.Value == false then

            if grabbed.Anchored == false then

                Ownership.SetModelNetworkOwner(object, player)
                grabbed.GripPoint.Value = true
            end
        end
    end
end

local function OnClientReleaseObject(player, object, grabbed)

    if grabbed:FindFirstChild("GripPoint") then
        if grabbed.GripPoint.Value == true then
            if grabbed.Anchored == false then

                grabbed.GripPoint.Value = false

                local obj_ref = object
                local grabbed_ref = grabbed
                delay(2, function()
                    if grabbed_ref.GripPoint.Value == false then
                       -- Ownership.SetModelNetworkOwner(obj_ref, nil)
                    end
                end)
            end
        end
    end
end

PhysicsService:CreateCollisionGroup("AuxParts")

PhysicsService:CollisionGroupSetCollidable("AuxParts", "Default", false)
PhysicsService:CollisionGroupSetCollidable("AuxParts", "LeftHand", false)
PhysicsService:CollisionGroupSetCollidable("AuxParts", "RightHand", false)
PhysicsService:CollisionGroupSetCollidable("AuxParts", "GrabbedLeft", false)
PhysicsService:CollisionGroupSetCollidable("AuxParts", "GrabbedRight", false)


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
    local hands = givehands(player)
    return true
end

on_client_grab_object.OnServerEvent:Connect(OnClientGrabObject)
on_client_release_object.OnServerEvent:Connect(OnClientReleaseObject)
on_client_request_vr_state.OnServerInvoke = OnClientRequestVRState