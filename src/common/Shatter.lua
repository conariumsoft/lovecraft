local Debris = game:GetService("Debris")


local GLASS_NORMAL_DISTRIBUTION = 0.25
local GLASS_POINT_COUNT = 30
local MIN_SHARD_SIZE = 0.1

local Delaunay = require(script.Parent.Delaunay)

local function draw_tri(a, b, c, w1, w2)
	local ab, ac, bc = b-a, c-a, c-b
	
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	
	if (abd > acd and abd > bcd) then
		c, a = a, c
	elseif (acd > bcd and acd > abd) then
		a, b = b, a
	end
	
	ab, ac, bc = b - a, c - a, c - b
	
	local right = ac:Cross(ab).unit
	local up = bc:Cross(right).unit
	local back = bc.unit
	
	local height = math.abs(ab:Dot(up))
	
	w1.Size = Vector3.new(0, height, math.abs(ab:Dot(back)))
	w1.CFrame = CFrame.fromMatrix((a+b)/2, right, up, back)
	
	w2.Size = Vector3.new(0, height, math.abs(ac:Dot(back)))
	w2.CFrame = CFrame.fromMatrix( (a + c)/2, -right, up, -back)
	
end

local function gaussian(mean, variance)
	return math.sqrt(-2 * variance * math.log(math.random())) *
			math.cos(2 * math.pi * math.random()) + mean
end

local function copy_props_into_wedge(part)
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.Color = part.Color
	w.Transparency = part.Transparency
    w.Material = part.Material
	w.Name = "Shatter"
	return w
end

--[[

]]
return function(window_part, impact_pos)
	local points = {}

	-- manually insert corners
	local px = window_part.Position.X
	local py = window_part.Position.Y
	local sx = window_part.Size.X
	local sy = window_part.Size.Y

	-- generate random points
    for i = 1, GLASS_POINT_COUNT do
        local x = gaussian(0, GLASS_NORMAL_DISTRIBUTION)
        local y = gaussian(0, GLASS_NORMAL_DISTRIBUTION)
        points[i] = Delaunay.Point(impact_pos.X + x, impact_pos.Y + y)
        
	end

    table.insert(points, Delaunay.Point(px - (sx/2), py - (sy/2)) )
    table.insert(points, Delaunay.Point(
        window_part.Position.X+ (window_part.Size.X/2),
        window_part.Position.Y+ (window_part.Size.Y/2)
    ))
    table.insert(points, Delaunay.Point(
        window_part.Position.X+ (window_part.Size.X/2),
        window_part.Position.Y- (window_part.Size.Y/2)
    ))
    table.insert(points, Delaunay.Point(
        window_part.Position.X- (window_part.Size.X/2),
        window_part.Position.Y+ (window_part.Size.Y/2)
	))
    
	
    local tris = Delaunay.triangulate(unpack(points))
    
    local geep = Instance.new("Model")
    
    local center = Instance.new("Part")
    center.Anchored = true
    center.Size = Vector3.new(0.1, 0.1, 0.1)
    center.Position = window_part.Position
    center.Parent = geep

    geep.PrimaryPart = center

    for i, tri in ipairs(tris) do
        if tri:getArea() > MIN_SHARD_SIZE then
            local w1, w2 = copy_props_into_wedge(window_part), copy_props_into_wedge(window_part)
                
            draw_tri(
                Vector3.new(tri.p1.x, tri.p1.y, window_part.Position.Z),
                Vector3.new(tri.p2.x, tri.p2.y, window_part.Position.Z),
                Vector3.new(tri.p3.x, tri.p3.y, window_part.Position.Z),
            w1, w2)
            
            if tri:getArea() > 3.5 then
                w1.Name = "BreakableGlass"
                w2.Name = "BreakableGlass"
                w1.Anchored = true
                w2.Anchored = true
            else
                w1.Anchored = false
                w2.Anchored = false
                Debris:AddItem(w1, 20)
                Debris:AddItem(w2, 20)
            end
            w1.Parent = geep
            w2.Parent = geep
        end
        geep.Parent = game.Workspace
        geep:SetPrimaryPartCFrame(window_part.CFrame)
        window_part:Destroy()
        geep.Parent = game.Workspace
    end	
end