local server     = game:GetService("ServerScriptService")
local replicated = game:GetService("ReplicatedStorage")

--- Hand Animation loading
-- load on server initially to permit client replication
local animations = require(script.Parent.Data.Animations)
return function()


    local anims_folder = Instance.new("Folder")
    anims_folder.Name = "Animations"
    anims_folder.Parent = replicated.Content
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
    for _, data in pairs(animations["Left"]) do
        LoadAnimation(lf, data[1], data[2])
    end

    for _, data in pairs(animations["Right"]) do
        LoadAnimation(rf, data[1], data[2])
    end

end