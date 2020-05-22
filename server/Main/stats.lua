--https://developer.roblox.com/en-us/api-reference/class/Stats
--TODO: implement stats

_G.using "RBX.Stats"


return function()
    print("Stats:")
    print("\tDataReceiveKbps:"..Stats.DataReceiveKbps)
    print("\tDataSendKbps:"..Stats.DataSendKbps)
    print("\tInstanceCount:"..Stats.InstanceCount)
    print("\tMovingPrimitivesCount:"..Stats.MovingPrimitivesCount)
    print("\tInstanceCount:"..Stats.InstanceCount)
    print("\tPhysicsReceiveKbps:"..Stats.PhysicsReceiveKbps)
    print("\tPhysicsSendKbps:"..Stats.PhysicsSendKbps)
    print("\tTotalMemoryUsageMB:"..Stats.MovingPrimitivesCount)
end