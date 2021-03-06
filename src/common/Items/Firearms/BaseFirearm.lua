local Debris            = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")


local comm = ReplicatedStorage.Common
local Shatter       = require(comm.Shatter)
local Utils         = require(comm.Utils)
local Math3D        = require(comm.Math3D)
local ItemInstances = require(comm.ItemInstances)


local BaseItem = require(comm.Items.BaseItem)
local Cartridges = require(ReplicatedStorage.Data.Cartridges)


--[[
    Bullet Penetration calculations:
    get material
    get thickness of material on collided face
    if hit X , then size X
    if object has any size axis less than 1
    recoil based on material.
]]

-- HitPoint reduction per stud
local MATERIALS_DENSITIES = {
    CorrodedMetal = 1,
    Concrete = 1,
    Wood = 1,
    WoodPlanks = 1,
    Plastic = 1,
    SmoothPlastic = 1,
    Neon = 1,
    Slate = 1,
    Grass = 1,
    Brick = 1,
    Fabric = 1,
    DiamondPlate = 1,
    Sand = 1,
    Foil = 1,
    ForceField = 1,
}

local max_steps = 50
local bullet_step = 0.05

local adornment_part_parent = Instance.new("Part")
adornment_part_parent.Anchored = true
adornment_part_parent.CanCollide = false
adornment_part_parent.Size = Vector3.new(1,1,1)
adornment_part_parent.Transparency = 1
adornment_part_parent.Parent = game.Workspace
adornment_part_parent.Name = "LocalAdornment"

local function bullet_penetration(part, intersection, direction_vec)
    local vis_head_cf = CFrame.new(intersection, intersection+direction_vec.Unit)

    local vis_head = Instance.new("ConeHandleAdornment")
    vis_head.Radius = 0.03
    vis_head.ZIndex = 2
    vis_head.AlwaysOnTop = true
    vis_head.Adornee = adornment_part_parent
    vis_head.CFrame = vis_head_cf
    vis_head.Parent = adornment_part_parent
    vis_head.Height = 0.3
    vis_head.Color3 = Color3.new(0, 0, 1)

    local step
    local material_covered = 0
    for i = 0, 3, bullet_step do
        step = intersection + (direction_vec.Unit * i)

       if Math3D.PartIntersectsPoint(part, step) then
            local material_multiplier = 1
            material_covered = material_covered + bullet_step
       else

            local vis_line = Instance.new("CylinderHandleAdornment")
            vis_line.Radius = 0.01
            vis_line.AlwaysOnTop = true
            vis_line.ZIndex = 2
            vis_line.Color3 = Color3.new(1, 1, 1)
            vis_line.Height = (intersection - step).magnitude
            vis_line.CFrame = CFrame.new(intersection:Lerp(step, 0.5), step+direction_vec)
            vis_line.Adornee = adornment_part_parent
            vis_line.Parent = adornment_part_parent

            local vis_end = Instance.new("ConeHandleAdornment")
            vis_end.Radius = 0.03
            vis_end.ZIndex = 2
            vis_end.AlwaysOnTop = true
            vis_end.CFrame = CFrame.new(step, step+direction_vec)
            vis_end.Parent = adornment_part_parent
            vis_end.Adornee = adornment_part_parent
            vis_end.Height = 0.3
            vis_end.Color3 = Color3.new(0, 1, 0)
            return material_covered
        end
    end
    local vis_line = Instance.new("CylinderHandleAdornment")
            vis_line.Radius = 0.01
            vis_line.AlwaysOnTop = true
            vis_line.ZIndex = 2
            vis_line.Color3 = Color3.new(0.5, 0.5, 0.5)
            vis_line.Height = (intersection - step).magnitude
            vis_line.CFrame = CFrame.new(intersection:Lerp(step, 0.5), step+direction_vec)
            vis_line.Adornee = adornment_part_parent
            vis_line.Parent = adornment_part_parent

            local vis_end = Instance.new("ConeHandleAdornment")
            vis_end.Radius = 0.03
            vis_end.ZIndex = 2
            vis_end.AlwaysOnTop = true
            vis_end.CFrame = CFrame.new(step, step+direction_vec)
            vis_end.Parent = adornment_part_parent
            vis_end.Adornee = adornment_part_parent
            vis_end.Height = 0.3
            vis_end.Color3 = Color3.new(1, 1, 0)

    return material_covered
end

local BF = BaseItem:subclass("BaseFirearm") do
    BF.TriggerStiffness = 0.95
    BF.RateOfFire = 850
    BF.RecoilRecoverySpeed = 2
    BF.BoltTravelDistance = 0.2
    BF.BarrelComponent = nil
    BF.BoltComponent = nil
    BF.MagazineType = nil
    BF.Automatic = false
    BF.MagazineSize = RunService:IsStudio() and 999999 or 30
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

    --self:SummonMag()
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

function BF:BloodSplatter(hit, dir)
    local dt = dir.Unit.Direction
    local bloodpart = Instance.new("Part")
    bloodpart.Color = Color3.new(0, 1, 0)
    bloodpart.Anchored = false
    bloodpart.CanCollide = false
    bloodpart.Material = Enum.Material.Neon
    bloodpart.Size = Vector3.new(0.1, 0.1, 0.1)
    bloodpart.Transparency = 0.25
    bloodpart.Position = hit.Position
    bloodpart.Parent = game.Workspace
    bloodpart.Massless = true
    bloodpart.Velocity = (dt*20) + Math3D.RandomVec3(2)

    Debris:AddItem(bloodpart, 1)
end
--------------------------------------------------------------

local function calc_damage(cartridge, hit_body_part)
    -- TODO: bullet penetration and damage dropoff
    local resultant_damage = cartridge.Damage

    if Utils.TableContains(hit_body_part.Name, {"Head", "HeadJ"}) then
        resultant_damage = resultant_damage * cartridge.HeadMul        
    end
    if Utils.TableContains(hit_body_part.Name, {"LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm"}) then
        resultant_damage = resultant_damage * cartridge.ArmMul
    end
    return resultant_damage
end

local Networking = ReplicatedStorage.Networking

function BF:HitTest(ray)
    local cartridge = Cartridges[self.Cartridge]
    local hit, pos = game.Workspace:FindPartOnRay(ray, self.Model)

    if not hit then return end

    local reslt = bullet_penetration(hit, pos, ray.Unit.Direction)

    print("Shoot:"..reslt)
    
    if hit.Name == "BreakableGlass" then
        Shatter(hit, pos)
        return
    end

    -- gotta hit
    if hit.Parent:FindFirstChild("Humanoid") then

        local resultant_damage = calc_damage(cartridge, hit)

        for i = 1, resultant_damage/2 do
            self:BloodSplatter(hit, ray)
        end

        local hit_reflect = Networking.ClientHit
        hit_reflect:FireServer(hit.Parent, resultant_damage)
        hit.Parent.Humanoid:TakeDamage(resultant_damage)
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

function BF:FireProjectile()
    local barrel = self.Model[self.BarrelComponent]
    -- TODO: push ray back a little bit to help with hitreg missing at point-blank
    local ray = Ray.new(barrel.CFrame.p, barrel.CFrame.rightVector*200)

    self:HitTest(ray)
end

local GunshotEffect = require(script.Parent.Parent.Parent.GunshotEffect)

function BF:Fire(hand, grip_point)
    local cf_reflect = Networking.ClientShoot
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
    self:FireProjectile()

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
        local pop = require(script.Parent.Parent.Magazine)
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

    if handinst.PointerState > self.TriggerStiffness then
        self:TriggerDown(handinst, dt, handlepart)
        self.TriggerPressed = true
    end
    
    if handinst.PointerState < 0.25 then
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
            --self:OnMagazineInsert(part.Parent)
        end
    end

    if grip_point.Name == "Handle"         then self:HandleStep(hand, dt, grip_point) end
    if grip_point.Name == "ChargingHandle" then self:BoltStep(hand, dt, grip_point)   end
end
return BF