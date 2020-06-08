local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Class = require(ReplicatedStorage.Common.Class)

local adornment_part_parent = Instance.new("Part")
adornment_part_parent.Anchored = true
adornment_part_parent.CanCollide = false
adornment_part_parent.Size = Vector3.new(1,1,1)
adornment_part_parent.Transparency = 1
adornment_part_parent.Parent = game.Workspace
adornment_part_parent.Name = "LocalAdornment"

local template_cylinder = Instance.new("CylinderHandleAdornment")
template_cylinder.Radius = 0.005
template_cylinder.AlwaysOnTop = true
template_cylinder.ZIndex = 2
template_cylinder.Height = 0.5
template_cylinder.Transparency = 0.75

local Adornment = Class:subclass("BaseAdornment")

function Adornment:__ctor(parent)

    parent = parent or adornment_part_parent
    self.Parent = parent
end

local AxisAdornment = Adornment:subclass("AxisAdrnment")

function AxisAdornment:__ctor(parent, alwaysontop, height)
    Adornment.__ctor(self, parent)
    self.UpVector = template_cylinder:Clone()
    self.UpVector.Color3 = Color3.new(0, 0, 1)
    self.UpVector.CFrame = CFrame.new(Vector3.new(0, 0.25, 0), Vector3.new(0, 1, 0))
    self.UpVector.Adornee = parent
    self.UpVector.Parent = parent


    self.RightVector = template_cylinder:Clone()
    self.RightVector.Color3 = Color3.new(0, 1, 0)
    self.RightVector.CFrame = CFrame.new(Vector3.new(0, 0, 0.25), Vector3.new(0, 0, 1))
    self.RightVector.Adornee = parent
    self.RightVector.Parent = parent


    self.ForwardVector = template_cylinder:Clone()
    self.ForwardVector.Color3 = Color3.new(1, 0, 0)
    self.ForwardVector.CFrame = CFrame.new(Vector3.new(0.25, 0, 0), Vector3.new(1, 0, 0))
    self.ForwardVector.Adornee = parent
    self.ForwardVector.Parent = parent

    self.Parent = parent
end

function Adornment:SetCFrame(cf)
    self.UpVector.CFrame = CFrame.new(cf.Position, cf.UpVector)
    self.ForwardVector.CFrame = CFrame.new(cf.Position, cf.LookVector)
    self.RightVector.CFrame = CFrame.new(cf.Position, cf.RightVector)
end


local SphereAdornment = Adornment:subclass("SphereAdornment")


local CubeAdornment = Adornment:subclass("CubeAdornment")


return {
    Axis = AxisAdornment,
    Sphere = SphereAdornment,
    Cube = CubeAdornment,
}