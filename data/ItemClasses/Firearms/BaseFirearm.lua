_G.using "Lovecraft.Networking"
_G.using "RBX.Debris"
_G.using "Lovecraft.ItemInstances"


local BaseItem = require(script.Parent.Parent.BaseItem)
local Cartridges = require(script.Parent.Parent.Parent.Cartridges)

local BF = BaseItem:subclass("BaseFirearm") do
    BF.TriggerStiffness = 0.95
    BF.RateOfFire = 850
    BF.RecoilRecoverySpeed = 2
    BF.BoltTravelDistance = 0.2
    BF.BarrelComponent = nil
    BF.BoltComponent = nil
    BF.MagazineType = nil
    BF.Automatic = false
    BF.MagazineSize = 20
    BF.Recoil = {
        XMoveMax = 0.05,
        XMoveMin = -0.05,
        YMoveMin = 0,
        YMoveMax = 0,
        ZMoveMin = 0,
        ZMoveMax = 0,
        XTiltMin = 0,
        XTiltMax = 0,
        YTiltMin = 0,
        YTiltMax = 0,
        ZTiltMin = 0,
        ZTiltMax = 0,
    }
    BF.Cartridge = ".22LR"
    BF.MagazineCFrame = CFrame.new(0, 0, 0)
end

local animation_track = nil

function BF:__ctor(...) -- TODO pass in the model?
    BaseItem.__ctor(self, ...)
    self.Timer = 1
    self.RoundInChamber = true
    self.MagazineInserted = false
    self.MagazineRoundCount = self.MagazineSize-- put back to nominal values later
    self.BoltGrabbed = false
    self.TriggerPressed = false
    self.HandleStepDebounce = false
    self.BoltForward = true

    self:SummonMag()
end

-- will get a mag from replicated storage and auto-chamber first round
function BF:SummonMag()
    local mymag = game.ReplicatedStorage.Content.Magazines[self.MagazineType]:Clone()

    mymag.Parent = game.Workspace.Physical

    self:OnMagazineInsert(mymag)
end

------------------------------------------------
-- Various Methods
function BF:GetCycleTime() return self.RateOfFire/60 end
-------------------------------------------------------
-- Handle (Trigger Group) Functionality
function BF:HandleOnGrab(hand)
    if animation_track ~= nil then return end
    -- load this thing if it hasn't already
    animation_track = self.Model.AnimationController:LoadAnimation(self.Model.slideBack)
    animation_track.Priority = Enum.AnimationPriority.Core
end

function BF:HandleOnRelease(hand) end

function BF:ChargingHandleOnGrab(hand) 

    self.BoltGrabbed = true 
end

function BF:ChargingHandleOnRelease(hand)



    if self.MagazineInserted and self.RoundInChamber == false then
        self.RoundInChamber = true
        self.MagazineRoundCount = self.MagazineRoundCount - 1
        animation_track:Play()
        animation_track:AdjustSpeed(1)
        -- TODO: sound fx and remove charginghandle grip point
    end
end

function BF:BloodSplatter(hit)
    local bloodpart = Instance.new("Part")
    bloodpart.Color = Color3.new(1, 0.5, 0)
    bloodpart.Anchored = false
    bloodpart.CanCollide = false
    bloodpart.Size = Vector3.new(0.1, 0.1, 0.1)
    bloodpart.Transparency = 0.25
    bloodpart.Position = hit.Position
    bloodpart.Parent = game.Workspace
    bloodpart.Velocity = Vector3.new(math.random(-15, 15), math.random(-15, 15), math.random(-15, 15))
    Debris:AddItem(bloodpart, 0.5)
end
--------------------------------------------------------------

function BF:FireProjectile()
    local barrel = self.Model[self.BarrelComponent]
    local coach_ray = Ray.new(barrel.CFrame.p, barrel.CFrame.rightVector*200)

    local cartridge = Cartridges[self.Cartridge]

    local hit, pos = game.Workspace:FindPartOnRay(coach_ray, self.Model)

    if not hit then return end

    -- gotta hit
    if hit.Parent:FindFirstChild("Humanoid") then
        local resultant_damage = cartridge.Damage
        if hit.Name == "Head" or hit.Name == "HeadJ" then
            print("Headshot!")
            resultant_damage = resultant_damage * cartridge.HeadMul
        end

        if hit.Name == "LeftUpperArm" or hit.Name == "LeftLowerArm" or hit.Name == "RightUpperArm" or hit.Name == "RightLowerArm" then
            resultant_damage = resultant_damage * cartridge.ArmMul
        end

        for i = 1, resultant_damage/2 do
            self:BloodSplatter(hit)
        end

        local hit_reflect = Networking.GetNetHook("ClientHit")
        hit_reflect:FireServer(hit.Parent, resultant_damage)
        hit.Parent.Humanoid:TakeDamage(resultant_damage)

        -- TODO: hitreg?
    end

    if hit.Anchored then
        local bullet_impact = Instance.new("Part") do
            bullet_impact.Color = Color3.new(1, 1, 1)
            bullet_impact.Material = Enum.Material.Neon
            bullet_impact.Shape = Enum.PartType.Ball
            bullet_impact.Transparency = 0.25
            local impact_size = cartridge.BoreDiameter/2
            bullet_impact.Size = Vector3.new(impact_size, impact_size, impact_size)
            bullet_impact.Anchored = true
            bullet_impact.CanCollide = false
            bullet_impact.CFrame = CFrame.new(pos)
            bullet_impact.Parent = game.Workspace

            Debris:AddItem(bullet_impact, 30)
        end
    end
end

local GunshotEffect = require(script.Parent.Parent.Parent.GunshotEffect)

function BF:Fire(hand, grip_point)
    local cf_reflect = Networking.GetNetHook("ClientShoot")
    cf_reflect:FireServer(self.Model)
    local barrel = self.Model[self.BarrelComponent]
    local bolt = self.Model[self.BoltComponent]

    GunshotEffect(self.Model)

    barrel.Fire:Stop()
    barrel.Fire.TimePosition = 0.1
    barrel.Fire:Play()

    barrel.PointLight.Enabled = true

    self:BoltCycle()
    self:ApplyRecoilImpulse(hand, grip_point)
    self:FireProjectile(hand, grip_point)

    barrel.BillboardGui.Enabled = true
    barrel.BillboardGui.ImageLabel.Rotation = math.random(0, 360)

    delay(1/20, function() barrel.BillboardGui.Enabled = false end)
    delay(1/10, function() barrel.PointLight.Enabled = false end)
end

function BF:BoltCycle()
    animation_track:Stop()
    animation_track:Play()
    animation_track.TimePosition = 0
    animation_track:AdjustSpeed(1)

    if self.RoundInChamber == false then 
        animation_track:AdjustSpeed(0)
        animation_track.TimePosition = (animation_track.Length * 0.25)
    end
end

function BF:ClientFireEffects(hand, grip_point)

end

local scale = 1000
function BF:ApplyRecoilImpulse(hand, grip_point)
    local recoil = self.Recoil -- recoil profile
    local xmove = math.random(recoil.XMoveMin*scale, recoil.XMoveMax*scale)/scale
    local ymove = math.random(recoil.YMoveMin*scale, recoil.YMoveMax*scale)/scale
    local zmove = math.random(recoil.ZMoveMin*scale, recoil.ZMoveMax*scale)/scale
    local xtilt = math.random(recoil.XTiltMin*scale, recoil.XTiltMax*scale)/scale -- Pitch
    local ytilt = math.random(recoil.YTiltMin*scale, recoil.YTiltMax*scale)/scale -- Yaw
    local ztilt = math.random(recoil.ZTiltMin*scale, recoil.ZTiltMax*scale)/scale -- Roll
    hand.RecoilCorrectionCFrame = hand.RecoilCorrectionCFrame 
     * CFrame.new(xmove, ymove, zmove)
     * CFrame.Angles(math.rad(xtilt), math.rad(ytilt), math.rad(ztilt)) 


    local cam_rattle = math.random(recoil.CamRattle*scale, recoil.CamRattle*scale)/scale
    local cam_jolt   = math.random(-recoil.CamJolt*scale, recoil.CamJolt*scale)/scale
    local cam_kick   = math.random(recoil.MinKick*scale, recoil.MaxKick*scale)/scale

    game.Workspace.CurrentCamera.CFrame = game.Workspace.CurrentCamera.CFrame 
     * CFrame.new(cam_kick, 0, 0) 
     * CFrame.Angles(math.rad(cam_jolt), 0, math.rad(cam_rattle))
end

function BF:TriggerDown(hand, dt, grip_point)
    if self.Automatic ~= true and self.TriggerPressed then return end
    if self.Timer >= (1/self:GetCycleTime()) and self.RoundInChamber then
        self.Timer = 0
        self.MagazineRoundCount = self.MagazineRoundCount - 1
        if self.MagazineRoundCount == 0 then
            self.RoundInChamber = false
        end
        hand:SetRumble(1)
        self:Fire(hand, grip_point)
        delay(0.1, function() hand:SetRumble(0) end)
    end
end

function BF:OnMagazineInsert(magazine)

    local inst = ItemInstances.GetClassInstance(magazine)

    if inst == nil then
        local pop = require(script.Parent.Magazine)
        inst = ItemInstances.CreateClassInstance(magazine, pop)
    end

    if inst.BeingGripped == true then return end
    
    inst:OnInsert(self)

    print("Magazine Inserted")
    self.MagazineInserted = true
    self.MagazineRoundCount = self.MagazineSize

    magazine:SetPrimaryPartCFrame(self.Model:GetPrimaryPartCFrame() * self.MagazineCFrame)
    local magweld = Instance.new("WeldConstraint")

    magweld.Name = "MagWeld"
    magweld.Parent = magazine.PrimaryPart
    magweld.Part1 = magazine.PrimaryPart
    magweld.Part0 = self.Model.PrimaryPart
end

function BF:OnMagazineRemove(hand)
    self.MagazineInserted = false
    self.MagazineRoundCount = 0
end

---------------------------------
-- External API-Hook methods
function BF:OnGrab(hand, grip_point)
    BaseItem.OnGrab(self, hand, grip_point)
    if not self.Model:FindFirstChild("Data") then
        local folder = Instance.new("Folder")
        folder.Name = "Data"
        folder.Parent = self.Model
    end

    local g = grip_point.Name
    if g == "Handle"         then self:HandleOnGrab(hand)         end 
    if g == "ChargingHandle" then self:ChargingHandleOnGrab(hand) end
end

function BF:OnRelease(hand, grip_point)
    BaseItem.OnRelease(self, hand, grip_point)
    local gp = grip_point.Name
    if gp == "Handle"         then self:HandleOnRelease(hand)         end
    if gp == "ChargingHandle" then self:ChargingHandleOnRelease(hand) end
end

function BF:HandleStep(handinst, dt, handlepart)
    self.Timer = self.Timer + dt
        
    handinst.RecoilCorrectionCFrame = handinst.RecoilCorrectionCFrame:Lerp(CFrame.new(0, 0, 0), 1/self.RecoilRecoverySpeed)

    if handinst.IndexFingerPressure > self.TriggerStiffness then
        self:TriggerDown(handinst, dt, handlepart)
        self.TriggerPressed = true
    end
    
    if handinst.IndexFingerPressure < 0.25 then
        self.TriggerPressed = false
    end
end

function BF:BoltStep(handinst, dt, boltpart) end


function BF:OnSimulationStep(hand, dt, grip_point)

    -- magazine insertion
    local mag_well = self.Model.MagazineCorrect -- TODO: hardcoded not good
    local model = self.Model
    for _, part in pairs(model.MagazineCorrect:GetTouchingParts()) do
        if part.Parent.Name == self.MagazineType then
            self:OnMagazineInsert(part.Parent)
        end
    end

    if grip_point.Name == "Handle"         then self:HandleStep(hand, dt, grip_point) end
    if grip_point.Name == "ChargingHandle" then self:BoltStep(hand, dt, grip_point)   end
end

function BF:OnTriggerState(hand, finger_pressure, grip_point)
end

return BF