local RunService = game:GetService("RunService")

local recorded_velocities = {}
local last_pos = {}

local captures_per_second = 80
local totalcaptures = 10
local capture_step = 0

local mod = {}

local index = 0

RunService.Heartbeat:Connect(function(delta)
    capture_step = capture_step + delta

    if capture_step >= (1/captures_per_second) then
        capture_step = 0
        index = index + 1

        local realidx = (index % totalcaptures) + 1

        for part, t in pairs(recorded_velocities) do

            if last_pos[part] then
                local vel = math.abs((part.Position - last_pos[part]).magnitude)
                t[realidx] = vel
            end
            last_pos[part] = part.Position
        end
    end
end)

function mod.Track(part)
    recorded_velocities[part] = {}

    for i = 1, totalcaptures do
        recorded_velocities[part][i] = 0
    end
end

function mod.Untrack(part)
    recorded_velocities[part] = nil
end

function mod.GetAverageVelocity(part)
    local t = recorded_velocities[part]
    local x = 0

    for _, v in pairs(t) do
        x = x + v
    end
    return x/#t
end

return mod