--[[
    FABRIK Solver
    Original code by EgoMoose
    Modified by joshuu
]] 


local Solver = {}

function Solver.SolveArm(og_cf, target, l1, l2)

	local localized = og_cf:pointToObjectSpace(target)
	local localized_unit = localized.unit
	local l3 = localized.magnitude

	local axis = Vector3.new(0, 0, -1):Cross(localized)

	local angle = math.acos(-localized_unit.Z)
	local plane_cf = og_cf * CFrame.fromAxisAngle(axis, angle)

	local lim = math.max(l2, l1) - math.min(l2, l1)

	-- point is too close
	-- push it back, compress angles
	if l3 < lim then
		return plane_cf * CFrame.new(0, 0, lim-l3), -math.pi/2, math.pi 
	-- point is too far away
	-- so we shall EXPAND DONG
	elseif l3 > l1 + l2 then
		return plane_cf * CFrame.new(0, 0, l1 + l2 - l3), math.pi/2, 0

	-- point is reachable
	-- plane is fine, solve angles of triangle
	else
		local a1 = -math.acos((-(l2 * l2) + (l1 * l1) + (l3 * l3)) / (2*l1*l3))
		local a2 = math.acos(((l2 * l2) - (l1 * l1) + (l3 * l3)) / (2*l2*l3))

		return plane_cf, a1+math.pi/2, a2 - a1
	end
end


-- this is the hardest part of the code so I super commented it!
function Solver.Constrain(jt, calc_vec, line, cf)
	local scalar = calc_vec:Dot(line) / line.magnitude;
	local proj = scalar * line.unit;
	
	-- get axis that are closest
	local ups = {
        cf:vectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Top)), 
        cf:vectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Bottom))
    }
	local rights = {
        cf:vectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Right)), 
        cf:vectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Left))
    }

	table.sort(ups, function(a, b) return (a - calc_vec).magnitude < (b - calc_vec).magnitude end);
	table.sort(rights, function(a, b) return (a - calc_vec).magnitude < (b - calc_vec).magnitude end);
	
	local upvec = ups[1];
	local rightvec = rights[1];

	-- get the vector from the projection to the calculated vector
	local adjust = calc_vec - proj;
	if scalar < 0 then
		-- if we're below the cone flip the projection vector
		proj = -proj;
	end;
	
	-- get the 2D components
	local xaspect = adjust:Dot(rightvec);
	local yaspect = adjust:Dot(upvec);
	
	-- get the cross section of the cone
	local left = -(proj.magnitude * math.tan(jt.left));
	local right = proj.magnitude * math.tan(jt.right);
	local up = proj.magnitude * math.tan(jt.up);
	local down = -(proj.magnitude * math.tan(jt.down));
	
	-- find the quadrant
	local xbound = xaspect >= 0 and right or left
	local ybound = yaspect >= 0 and up or down
	
	local f = calc_vec
	-- check if in 2D point lies in the ellipse 
	local ellipse = xaspect^2/xbound^2 + yaspect^2/ybound^2
	local inbounds = ellipse <= 1 and scalar >= 0
	
	if not inbounds then
		-- get the angle of our out of ellipse point
		local a = math.atan2(yaspect, xaspect)
		-- find nearest point
		local x = xbound * math.cos(a)
		local y = ybound * math.sin(a)
		-- convert back to 3D
		f = (proj + rightvec * x + upvec * y).unit * calc_vec.magnitude
	end
	
	-- return our final vector
	return f
end

function Solver.Backward(chain)
	-- backward reaching; set end effector as target
	chain.joints[chain.n].vec = chain.target;
    for i = chain.n - 1, 1, -1 do
        local cj = chain.joints[i] -- current joint
        local nj = chain.joints[i+1] -- next joint

		local r = (nj.vec - cj.vec);
		local l = cj.length / r.magnitude;
		-- find new joint position
		local pos = (1 - l) * nj.vec + l * cj.vec;
		cj.vec = pos;
	end;
end;

function Solver.Forward(chain)
	-- forward reaching; set root at initial position
	chain.joints[1].vec = chain.origin.p;
	local coneVec = (chain.joints[2].vec - chain.joints[1].vec).unit;
    for i = 1, chain.n - 1 do
        local cj = chain.joints[i] -- current joint
        local nj = chain.joints[i+1] -- next joint
		local r = (nj.vec - cj.vec);
		local l = cj.length / r.magnitude;
		-- setup matrix
		local cf = CFrame.new(cj.vec, cj.vec + coneVec);
		-- find new joint position
		local pos = (1 - l) * cj.vec + l * nj.vec;
		local t = Solver.Constrain(cj, pos-cj.vec, coneVec, cf);
		nj.vec = cj.constrained and cj.vec + t or pos;
		coneVec = nj.vec - cj.vec;
	end;
end;

function Solver.Solve(chain)
	local distance = (chain.joints[1].vec - chain.target).magnitude
	if distance > chain.totallength then
		-- target is out of reach
        for i = 1, chain.n - 1 do
            local cj = chain.joints[i] -- current joint
            local nj = chain.joints[i+1] -- next joint
			local r = (chain.target - cj.vec).magnitude;
			local l = cj.length / r;
			-- find new joint position
			nj.vec = (1 - l) * cj.vec + l * chain.target;
		end
	else
		-- target is in reach
		local bcount = 0;
		local dif = (chain.joints[chain.n].vec - chain.target).magnitude;
		while dif > chain.tolerance do
			Solver.Backward(chain);
			Solver.Forward(chain);
			dif = (chain.joints[chain.n].vec - chain.target).magnitude;
			-- break if it's taking too long so the game doesn't freeze
			bcount = bcount + 1
			if bcount > 10 then break end
		end
	end
end

return Solver

--[[-- FABRIK
-- Ego

local chain = {};
local plane = {};

-- table sum function
function sum(t)
	local s = 0;
	for _, value in ipairs(t) do
		s = s + value;
	end;
	return s;
end;

local part = Instance.new("Part");
part.Material = Enum.Material.Plastic;
part.Anchored = true;
part.CanCollide = false;
part.BrickColor = BrickColor.Blue();

local parts = {};
local model = Instance.new("Model", game.Workspace);
function drawline(key, a, v)
	if not parts[key] then parts[key] = part:Clone(); parts[key].Parent = model; end;
	parts[key].Size = Vector3.new(.2, .2, v.magnitude);
	parts[key].CFrame = CFrame.new(a + v/2, a + v);	
	return parts[key];
end;

-- fabrik chain class
function chain.new(joints, target)
	local self = setmetatable({}, {__index = chain});

	local lengths = {};
	for i = 1, #joints - 1 do
		lengths[i] = (joints[i] - joints[i+1]).magnitude;
	end;	
	
	self.n = #joints;
	self.tolerance = 0.1;
	self.target = target;
	self.joints = joints;
	self.lengths = lengths;
	self.origin = CFrame.new(joints[1]);
	self.totallength = sum(lengths);
	
	-- rotation constraints
	self.constrained = false;
	self.left = math.rad(89);
	self.right = math.rad(89);
	self.up = math.rad(89);
	self.down = math.rad(89);
	
	return self;
end;

-- this is the hardest part of the code so I super commented it!
function chain:constrain(calc, line, cf)
	local scalar = calc:Dot(line) / line.magnitude;
	local proj = scalar * line.unit;
	
	-- get axis that are closest
	local ups = {cf:vectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Top)), cf:vectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Bottom))};
	local rights = {cf:vectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Right)),  cf:vectorToWorldSpace(Vector3.FromNormalId(Enum.NormalId.Left))};
	table.sort(ups, function(a, b) return (a - calc).magnitude < (b - calc).magnitude end);
	table.sort(rights, function(a, b) return (a - calc).magnitude < (b - calc).magnitude end);
	
	local upvec = ups[1];
	local rightvec = rights[1];

	-- get the vector from the projection to the calculated vector
	local adjust = calc - proj;
	if scalar < 0 then
		-- if we're below the cone flip the projection vector
		proj = -proj;
	end;
	
	-- get the 2D components
	local xaspect = adjust:Dot(rightvec);
	local yaspect = adjust:Dot(upvec);
	
	-- get the cross section of the cone
	local left = -(proj.magnitude * math.tan(self.left));
	local right = proj.magnitude * math.tan(self.right);
	local up = proj.magnitude * math.tan(self.up);
	local down = -(proj.magnitude * math.tan(self.down));
	
	-- find the quadrant
	local xbound = xaspect >= 0 and right or left;
	local ybound = yaspect >= 0 and up or down;
	
	local f = calc;
	-- check if in 2D point lies in the ellipse 
	local ellipse = xaspect^2/xbound^2 + yaspect^2/ybound^2;
	local inbounds = ellipse <= 1 and scalar >= 0;
	
	if not inbounds then
		-- get the angle of our out of ellipse point
		local a = math.atan2(yaspect, xaspect);
		-- find nearest point
		local x = xbound * math.cos(a);
		local y = ybound * math.sin(a);
		-- convert back to 3D
		f = (proj + rightvec * x + upvec * y).unit * calc.magnitude;
	end;
	
	-- return our final vector
	return f;
end;

function chain:backward()
	-- backward reaching; set end effector as target
	self.joints[self.n] = self.target;
	for i = self.n - 1, 1, -1 do
		local r = (self.joints[i+1] - self.joints[i]);
		local l = self.lengths[i] / r.magnitude;
		-- find new joint position
		local pos = (1 - l) * self.joints[i+1] + l * self.joints[i];
		self.joints[i] = pos;
	end;
end;

function chain:forward()
	-- forward reaching; set root at initial position
	self.joints[1] = self.origin.p;
	local coneVec = (self.joints[2] - self.joints[1]).unit;
	for i = 1, self.n - 1 do
		local r = (self.joints[i+1] - self.joints[i]);
		local l = self.lengths[i] / r.magnitude;
		-- setup matrix
		local cf = CFrame.new(self.joints[i], self.joints[i] + coneVec);
		-- find new joint position
		local pos = (1 - l) * self.joints[i] + l * self.joints[i+1];
		local t = self:constrain(pos - self.joints[i], coneVec, cf);
		self.joints[i+1] = self.constrained and self.joints[i] + t or pos;
		coneVec = self.joints[i+1] - self.joints[i];
	end;
end;

function chain:solve()
	local distance = (self.joints[1] - self.target).magnitude;
	if distance > self.totallength then
		-- target is out of reach
		for i = 1, self.n - 1 do
			local r = (self.target - self.joints[i]).magnitude;
			local l = self.lengths[i] / r;
			-- find new joint position
			self.joints[i+1] = (1 - l) * self.joints[i] + l * self.target;
		end;
	else
		-- target is in reach
		local bcount = 0;
		local dif = (self.joints[self.n] - self.target).magnitude;
		while dif > self.tolerance do
			self:backward();
			self:forward();
			dif = (self.joints[self.n] - self.target).magnitude;
			-- break if it's taking too long so the game doesn't freeze
			bcount = bcount + 1;
			if bcount > 20 then break; end;
		end;
	end;
end;

return chain;]]