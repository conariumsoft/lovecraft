require(game.ReplicatedStorage.Lovecraft.Lovecraft)

_G.log("Initializing server...")

_G.using "Lovecraft.Networking"
_G.using "Lovecraft.CollisionMasking"
_G.using "RBX.ReplicatedStorage"
-- TODO: generate remotes..?

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


local function OnClientGrabObject(player, object)
    print("client grab", object.Name)
    if object:FindFirstChild("GripPoint") then
        if object.GripPoint.Value == false then
            if object.Anchored == false then
                object:SetNetworkOwner(player)
                object.GripPoint.Value = true
            end
        end
    end
end

local function OnClientReleaseObject(player, object)
    print("client release", object.Name)
    if object:FindFirstChild("GripPoint") then
        if object.GripPoint.Value == true then
            if object.Anchored == false then
                object:SetNetworkOwner(nil)
                object.GripPoint.Value = false
            end
        end
    end
end

local function OnClientRequestVRState(player)
    print("Client is ready for VR initialization")

    local plr_left = player.Character.LHand
    local plr_right = player.Character.RHand

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