using "Lovecraft.BaseClass"

local VRHead = BaseClass:subclass("VRHead")


function VRHead:__ctor(player)

    self.Player = player
end

function VRHead:Update(delta)
    
end


return VRHead