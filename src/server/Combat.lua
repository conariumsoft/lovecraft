local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networking = ReplicatedStorage.Networking

local on_client_shoot            = Networking.ClientShoot
local on_client_hit              = Networking.ClientHit

local function client_reflect_gunshot(client, weapon)
    on_client_shoot:FireAllClients(client, weapon)
end

-- ? no hit verification?
-- yes. this is bad. extremely bad.
-- don't worry, hit verification will be implemented before
-- public testing.
local function client_hit_enemy(client, enemy, damage, tagged_part, ray)
    --! WARNING: SERIOUSLY DUMB. NO SANITY CHECKING YET. DO NOT RELEASE IN THIS STATE
    enemy.Humanoid:TakeDamage(damage)
   
end

on_client_shoot.OnServerEvent:Connect(client_reflect_gunshot)
on_client_hit.OnServerEvent:Connect(client_hit_enemy)

return true