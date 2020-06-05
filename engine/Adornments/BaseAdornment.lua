
local Adornment = _G.newclass("Adornment")

local adornment_part_parent = Instance.new("Part")
adornment_part_parent.Anchored = true
adornment_part_parent.CanCollide = false
adornment_part_parent.Size = Vector3.new(1,1,1)
adornment_part_parent.Transparency = 1
adornment_part_parent.Parent = game.Workspace
adornment_part_parent.Name = "LocalAdornment"


function Adornment:__ctor(parent, ...)

    parent = parent or adornment_part_parent

end