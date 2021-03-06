local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mod = {}

function mod.GodLoadGun(gun_obj)
    -- perhaps mag type should be implicit. 
    print("GodLoading")
    -- ! this is incredibly retarded please don't leave this
    local module = require(ReplicatedStorage.Common.Items.Firearms[gun_obj.Name])

    local magazine = game.ReplicatedStorage.Content.Magazines[module.MagazineType]:Clone()

    magazine.Parent = game.Workspace.Physical
    table.foreach(magazine:GetChildren(), function(k,v)
        if v:IsA("BasePart") then 
            PhysicsService:SetPartCollisionGroup(v, "Interactives")
        end
    end)
    
    --! Not Final Form. Method signature will change
    -- TODO: use a magwell attachment instead of PrimaryPartCFrame
    --replc:FireAllClients(gun_obj, true) -- God Given Magazine

    magazine:SetPrimaryPartCFrame(gun_obj:GetPrimaryPartCFrame() * module.MagazineCFrame)
    local magweld = Instance.new("WeldConstraint")

    magweld.Name = "MagWeld"
    magweld.Parent = magazine.PrimaryPart
    magweld.Part1 = magazine.PrimaryPart
    magweld.Part0 = gun_obj.PrimaryPart
end

function mod.ii() end


return mod