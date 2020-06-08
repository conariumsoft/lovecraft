local Class = require(game.ReplicatedStorage.Common.Class)

local joint = Class:subclass("KinematicsJoint")

function joint:__ctor(vec, len, constr, ll, lr, lu, ld)

    self.length = len or 0 -- in studs
    self.constrained = (constr ~= nil) and constr or false
    self.left   = ll or math.rad(89)
    self.right  = lr or math.rad(89)
    self.up     = lu or math.rad(89)
    self.down   = ld or math.rad(89)

    self.vec = vec or Vector3.new(0, 0, 0)

end

return joint