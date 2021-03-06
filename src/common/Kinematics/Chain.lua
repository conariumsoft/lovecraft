local Class = require(game.ReplicatedStorage.Common.Class)

local chain = Class:subclass("KinematicsChain")
-- fabrik chain class
function chain:__ctor(joints)

	self.lengths = {}
	self.totallength = 0
	for i = 1, #joints - 1 do
		self.lengths[i] = joints[i].length
		self.totallength = self.totallength + joints[i].length
	end
	
	self.n = #joints
	self.tolerance = 0.01
	self.target = Vector3.new(0, 0, 0)
	self.joints = joints
	self.origin = CFrame.new(joints[1].vec)
	
end
return chain