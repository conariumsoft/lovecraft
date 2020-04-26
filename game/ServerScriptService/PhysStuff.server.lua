
-- uhh TODO: at least make attempt at multiplayer compatibility?
local PhysicsService = game:GetService("PhysicsService")
local Workspace      = game:GetService("Workspace")

local Player = game.Players:GetPlayers()[1] or game.Players.PlayerAdded:Wait()

print("Setting NetworkOwnership of the physics stuff")
for _,part in pairs(Workspace.physics:GetDescendants()) do
	if part:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(part, "Interactives")
   		part:SetNetworkOwner(Player)
	end
end
