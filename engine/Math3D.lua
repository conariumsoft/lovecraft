local mathmod = {}
mathmod.Vector3Up = Vector3.new(0, 1, 0)

-- TODO: please provide context and theory for all mathematical equations


function mathmod.PointSphereIntersection()

end


-- Determines how a ray intersects with a sphere
-- Returns either 0, 1, or 2 parts depending on how many intersections are found
function mathmod.LineSegmentSphereIntersection(O, E, C, radius)
    -- O: origin of ray
    -- E: destination of ray
    -- C: center of sphere
    -- radius: of sphere
    -- https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-sphere-intersection
    -- https://devforum.roblox.com/t/how-to-find-first-and-last-points-along-a-ray-that-intersect-with-a-sphere/126580/4

    local D = (E - O).unit -- direction unit from O to E
    local tmax = (E - O).magnitude -- length of line LineSegmentSphereIntersection
    local L = C - O -- vector from origin to center

    local tca = L:Dot(D) -- measure of angle between L and D
    if tca < 0 then -- the ray points away from sphere
        return nil, nil -- no intersection possible
    end

    local d = math.sqrt(L:Dot(L) - tca ^ 2) -- distance to closest point on ray

    if d < 0 then 
        -- not a number, or not useful
        -- no intersection found
        return nil,nil
    end
    -- find offset between closest point to sphere and the intersections
    local thc = math.sqrt(radius ^ 2 - d^2)

    local t0 = tca - thc
    local t1 = tca + thc

    if t1 <= tmax then
        -- both points are within range of ray
        return O + D * t0, O + D * t1
    elseif t0 <= tmax then
        -- only first point is within range of ray
        return O + D * t0, nil
    else
        return nil, nil
    end
end


function mathmod.LineToCFrame(vec1, vec2)
    assert(typeof(vec1) == "Vector3")
    assert(typeof(vec2) == "Vector3")
	local v = (vec2-vec1)
	return CFrame.new(vec1 + (v/2), vec2)
end

function mathmod.RandomVec3(range)
    assert(range >= 1, "Too small! Scale up or you'll get useless results!")
    local x =  math.random(-range, range)
    local y =  math.random(-range, range)
    local z =  math.random(-range, range)

    return Vector3.new(x, y, z)
end

function mathmod.GetPureRotation(cframe)
    return (cframe - cframe.Position)
end

function mathmod.PartIntersectsPoint(part, point)
    local delta = part.CFrame:pointToObjectSpace(point)
    delta = Vector3.new(math.abs(delta.X), math.abs(delta.Y), math.abs(delta.Z))
    local halfsize = part.Size/2
    local inX = delta.X <= halfsize.X
    local inY = delta.Y <= halfsize.Y
    local inZ = delta.Z <= halfsize.Z
    return inX and inY and inZ
end

function mathmod.GetIntersectingParts(point, check_region)
    check_region = check_region or 8

    local delta = Vector3.new(check_region, check_region, check_region)
    local r3 = Region3.new(point - delta, point+delta)
    local parts = Workspace:FindPartsInRegion3(r3)

    local intersecting = {}
    for _, part in parts do
        if mathmod.PartIntersectsPoint(part, point) then
            table.insert(intersecting, part)
        end
    end
    return intersecting
end


return mathmod