local chain = {}
-- fabrik chain class
function chain.new(joints, target)
	local self = setmetatable({}, {__index = chain})

	self.lengths = {}
	self.totallength = 0
	for i = 1, #joints - 1 do
		self.lengths[i] = joints[i].length
		self.totallength = self.totallength + joints[i].length
	end
	
	self.n = #joints
	self.tolerance = 0.01
	self.target = target
	self.joints = joints
	self.origin = CFrame.new(joints[1].vec)
	
	return self
end
return chain