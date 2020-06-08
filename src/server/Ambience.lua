local Lighting = game:GetService("Lighting")

local ambience = {}

local timescale = 1/5

function ambience.Step(delta)

    local timedelta = delta*timescale

    Lighting:SetMinutesAfterMidnight(Lighting:GetMinutesAfterMidnight()+timedelta)
end



return ambience