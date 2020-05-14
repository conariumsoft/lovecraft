local Solver = _G.newclass("Solver")

function Solver:__ctor(master_part, follower_part)
    local master_att = Instance.new("Attachment")
    master_att.Parent = master_part
    master_att.Name = "MasterAttachment"

    local follower_att = Instance.new("Attachment")
    follower_att.Parent = follower_part
    follower_att.Name = "FollowerAttachment"

    self.master_part = master_part
    self.follower_part = follower_part

    self.master_attachment = master_att
    self.follower_attachment = follower_att

    self.enabled = true
end

function Solver:Enable()

    self.enabled = true
end

function Solver:Disable()

    self.enabled = false
end

function Solver:IsEnabled()
    return self.enabled
end

function Solver:Destroy()
    self.master_attachment:Destroy()
    self.follower_attachment:Destroy()
end

return Solver