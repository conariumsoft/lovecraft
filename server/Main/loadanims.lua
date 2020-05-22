_G.using "RBX.ReplicatedStorage"

--- Hand Animation loading
-- load on server initially to permit client replication

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

return function()
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

    -- load sets
    for _, data in pairs(left_hand_animation_defs) do
        LoadAnimation(lf, data[1], data[2])
    end

    for _, data in pairs(right_hand_animation_defs) do
        LoadAnimation(rf, data[1], data[2])
    end
end