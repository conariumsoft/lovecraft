require(game.ReplicatedStorage.Lovecraft.Lovecraft)

_G.log("Initializing server...")

_G.using "Lovecraft.Networking"
_G.using "Lovecraft.CollisionMasking"
_G.using "Lovecraft.Ownership"
_G.using "RBX.ReplicatedStorage"
_G.using "RBX.Workspace"
_G.using "RBX.PhysicsService"
-- TODO: generate remotes..?

--[[
    Collision Groups:
    
    Default
    Interactives

    y = 2 + (6x)

    X per player
        PlayerBodies
        LeftHand
        RightHand
        HeldLeftHand
        HeldRightHand
        HeldBothHands


]]

-- init physical objects
for _, child in pairs(Workspace.physics:GetDescendants()) do
    if child:IsA("BasePart") then
        child:SetNetworkOwner(nil)
        PhysicsService:SetPartCollisionGroup(child, "Interactives")
    end
end

-- etc
Networking.ServerSetup()

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

LoadAnimation(lf, "Index",  "rbxassetid://4921338211")
LoadAnimation(rf, "Index", "rbxassetid://4921265382")
LoadAnimation(lf, "Grip",   "rbxassetid://4921113867")
LoadAnimation(rf, "Grip",  "rbxassetid://4921074129")

local on_client_request_vr_state = Networking.GenerateNetHook("ClientRequestVRState")

local on_client_grip_state = Networking.GenerateAsyncNetHook("ClientGripState")
local on_client_pointer_state = Networking.GenerateAsyncNetHook("ClientPointerState")
local on_client_grab_object = Networking.GenerateAsyncNetHook("ClientGrab")
local on_client_release_object = Networking.GenerateAsyncNetHook("ClientRelease")
local on_client_trigger_down = Networking.GenerateAsyncNetHook("ClientTriggerDown")
local on_client_trigger_up = Networking.GenerateAsyncNetHook("ClientTriggerUp")

local on_client_request_animation_controller = Networking.GenerateNetHook("ClientRequestAnimationController")
local on_client_request_animation            = Networking.GenerateNetHook("ClientRequestAnimationTrack")
-- TODO: apparently  we have to load the AnimationTrack on the server as well

local left_hand_model = game.ReplicatedStorage.LHand
local right_hand_model = game.ReplicatedStorage.RHand


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

local function OnClientRequestVRState(player)
    print("Client is ready for VR initialization")

   -- local plr_left = player.Character.LHand
  -- local plr_right = player.Character.RHand


    local plr_left = ReplicatedStorage.LHand:Clone()
    plr_left.Parent = player.Character

    local plr_right = ReplicatedStorage.RHand:Clone()
    plr_right.Parent = player.Character

    plr_left.PrimaryPart:SetNetworkOwner(player)
    plr_right.PrimaryPart:SetNetworkOwner(player)
    
    local left_a = Instance.new("Animator")
    left_a.Parent = plr_left.Animator

    local right_a = Instance.new("Animator")
    right_a.Parent = plr_right.Animator


    CollisionMasking.SetModelGroup(plr_left, "LeftHand")
    CollisionMasking.SetModelGroup(plr_right, "RightHand")
    return true
end

on_client_grab_object.OnServerEvent:Connect(OnClientGrabObject)
on_client_release_object.OnServerEvent:Connect(OnClientReleaseObject)
on_client_request_vr_state.OnServerInvoke = OnClientRequestVRState