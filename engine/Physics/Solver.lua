local Solver = _G.newclass("Solver")

function Solver:__ctor(master_attach, follower_attach)
    --[[local master_att = Instance.new("Attachment")
    master_att.Parent = master_part
    master_att.Name = "MasterAttachment"

    local follower_att = Instance.new("Attachment")
    follower_att.Parent = follower_part
    follower_att.Name = "FollowerAttachment"

    self.master_part = master_part
    self.follower_part = follower_part]]

    self.master_attachment = master_attach
    self.follower_attachment = follower_attach

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
    --self.master_attachment:Destroy()
    --self.follower_attachment:Destroy()
end

return Solver