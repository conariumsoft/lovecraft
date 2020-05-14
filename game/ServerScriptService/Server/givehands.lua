_G.using "RBX.ReplicatedStorage"
_G.using "Lovecraft.CollisionMasking"

return function(player)
    -- create hand models for player
    local plr_left = ReplicatedStorage.LHand:Clone()
    plr_left.Parent = player.Character

    local plr_right = ReplicatedStorage.RHand:Clone()
    plr_right.Parent = player.Character

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

    return {plr_left, plr_right}
end