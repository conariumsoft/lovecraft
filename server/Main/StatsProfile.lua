--[[
    Collects information on players for developers.
]]
_G.using "RBX.DataStoreService"
_G.using "RBX.RunService"

local DEFAULT_STATS = {
    ["PlayTime"] = 0,
    ["TimesJoined"] = 0,
    ["Deaths"] = 0,
    ["BulletsFired"] = 0,
    ["BulletsHit"] = 0,
    ["Headshots"] = 0,
    ["TimesGotShot"] = 0,
    ["TimesGotShotHead"] = 0,
    ["TimesGotShotBody"] = 0,
    ["TimesGotShotLeg"] = 0,
    ["TimeHoldingGlock17"] = 0,
    ["Movement"] = 0,
    ["Skins"] = {}
}

local DATABASE_ENABLED = not RunService:IsStudio()

local StatsProfile = _G.newclass("StatsProfile")

local session_db
if DATABASE_ENABLED then
    session_db = DataStoreService:GetDataStore("SessionStats", "A")
end

function StatsProfile:__ctor(player)
    self.Player = player
    self.Stats = {}


    for i, v in pairs(DEFAULT_STATS) do
        self.Stats[i] = v
    end
end

function StatsProfile:Load()
    if not DATABASE_ENABLED then return end
    local session_stats = {}
    local success, errmsg = pcall(function()
        session_stats = session_db:GetAsync("plr"..self.Player.UserId)
    end)

    for i, v in pairs(session_stats) do
        self.Stats[i] = v
    end
end

function StatsProfile:Save()
    if not DATABASE_ENABLED then return end
    local session_stats = {}
    local success, errmsg = pcall(function()
        session_db:SetAsync("plr"..self.Player.UserId, self.Stats)
    end)
end

function StatsProfile:Increment(key, incr)
    assert(typeof(incr) == "number")
    self.Stats[key] = self.Stats[key] + incr
end
function StatsProfile:Set(key, val)
    self.Stats[key] = val
end
function StatsProfile:Get(key)
    return self.Stats[key]
end
function StatsProfile:SetAllDefault()
    for i, v in pairs(DEFAULT_STATS) do
        self.Stats[i] = v
    end
end

return StatsProfile