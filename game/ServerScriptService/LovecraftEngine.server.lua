require(game.ReplicatedStorage.Lovecraft.Lovecraft)

_G.log("Initializing server...")

_G.using "Lovecraft.Networking"
_G.using "Lovecraft.CollisionMasking"
-- TODO: generate remotes..?

Networking.ServerSetup()

local on_client_request_vr_state = Networking.GenerateNetHook("ClientRequestVRState")
local on_client_grip_state = Networking.GenerateAsyncNetHook("ClientGripState")
local on_client_pointer_state = Networking.GenerateAsyncNetHook("ClientPointerState")
local on_client_grab_object = Networking.GenerateAsyncNetHook("ClientGrab")
local on_client_release_object = Networking.GenerateAsyncNetHook("ClientRelease")
local on_client_trigger_down = Networking.GenerateAsyncNetHook("ClientTriggerDown")
local on_client_trigger_up = Networking.GenerateAsyncNetHook("ClientTriggerUp")

local on_client_request_animation_controller = Networking.GenerateNetHook("ClientRequestAnimationController")

local left_hand_model = game.ReplicatedStorage.LHand
local right_hand_model = game.ReplicatedStorage.RHand


-- when client is ready for init, create nessecary models & replicate

local function get_anim_controller(char, name)
    local anim_controller = Instance.new("AnimationController")
    anim_controller.Parent = char
    anim_controller.Name = name
    return anim_controller
   
end

function on_client_request_vr_state.OnServerInvoke(player)

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

    get_anim_controller(player.Character, "LeftHandAnim")
    get_anim_controller(player.Character, "RightHandAnim")

    return plr_left, plr_right
end