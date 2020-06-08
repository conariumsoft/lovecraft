local Stats = game:GetService("Stats")

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