require(game.ReplicatedStorage.Lovecraft.Lovecraft)

_G.log("Initializing server...")

_G.using "Lovecraft.Networking"
_G.using "Lovecraft.CollisionMasking"
_G.using "RBX.ReplicatedStorage"
-- TODO: generate remotes..?

Networking.ServerSetup()
--co
local anims_folder = Instance.new("Folder")
anims_folder.Name = "Animations"
anims_folder.Parent = ReplicatedStorage

local lf = Instance.new("Folder")
lf.Name = "Left"
lf.Parent = anims_folder

local rf = Instance.new("Folder")
rf.Name = "Right"
rf.Parent = anims_folder

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


-- when client is ready for init, create nessecary models & replicate

local function get_anim_controller(hand)
    local anim_controller = Instance.new("AnimationController")
    anim_controller.Parent = hand
    anim_controller.Name = "Animator"
    return anim_controller
end

function on_client_request_animation.OnServerInvoke(player, animation, put_into)

end

function on_client_request_vr_state.OnServerInvoke(player)
    print("THE REMOTE FIRED! OK")
    --?
    --[[local plr_models_folder = Instance.new("Folder") do
        plr_models_folder.Name = player.Name .."_LocalVR"
        plr_models_folder.Parent = game.Workspace
    end]]

    local plr_left = left_hand_model:Clone()
    plr_left.Parent = player.Character
    plr_left.PrimaryPart:SetNetworkOwner(player)

    
    local plr_right = right_hand_model:Clone()
    plr_right.Parent = player.Character
    plr_right.PrimaryPart:SetNetworkOwner(player)

    -- TODO: if needed, create collision groups for each player @runtime
    CollisionMasking.SetModelGroup(plr_left, "LeftHand")
    CollisionMasking.SetModelGroup(plr_right, "RightHand")

    get_anim_controller(plr_left)
    get_anim_controller(plr_right)

    return plr_left, plr_right
end