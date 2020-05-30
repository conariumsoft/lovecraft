_G.using "RBX.CollectionService"

local interact = {}

local function is_interactive(object)
    return CollectionService:HasTag(object, "Interactive")
end

local function is_free(object)

    if not CollectionService:HasTag(object, "Interactive") then
        return false
    end


    return true
end

local function is_pinch_interactive(object) end
local function is_grip_interactive(object) end

local function interactives_list()
    return game.Workspace.Physical:GetDescendants()
end


function interact.FindNearestObjVec3(vec3_pos)
    local closest_part = nil
    local closest_dist = math.huge
    min_distance = min_distance or 3
    for _, inst in pairs(interactives_list()) do
        if is_free(inst) then
            local dist = (inst.Position - vec3_pos)

        end
    end
end

function interact.FindNearestObjRay(ray) end

function interact.FindNearestObj(thing)
    if typeof(thing) == "Vector3" then
        interact.FindNearestObjVec3(thing)
    elseif typeof(thing) == "Ray" then
        interact.FindNearestObjRay(thing)
    else
        error("Use the right type dumbass!")
    end
end
        local closest_part = nil
        local closest_dist = math.huge
        min_distance = min_distance or 3
    
        for _, part in pairs(Workspace.Physical:GetDescendants()) do
            if part:FindFirstChild("GripPoint") then
                local dist = (part.Position - self.HandModel.PrimaryPart.Position).magnitude
                if dist < min_distance and dist < closest_dist then
    
                    -- vector must be flipped for right hand
                    local flip = (self.Handedness == "Left") and 1 or -1
    
                    local ray = Ray.new(self.HandModel.PrimaryPart.Position, flip*self.HandModel.PrimaryPart.CFrame.rightVector)
                    local hit, pos, sfnormal = Workspace:FindPartOnRayWithWhitelist(ray, {part})
                    if hit and hit == part then
                        closest_part = part
                    end
                end
            end
        end
        return closest_part
end