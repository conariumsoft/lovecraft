local PhysicsService = game:GetService("PhysicsService")

local CollisionMasking = {}

function CollisionMasking.SetModelGroup(model, group)
    for _, obj in pairs(model:GetDescendants()) do 
        if obj:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(obj, group)
        end 
    end
end

return CollisionMasking