local unit_cube = Instance.new("Part") do
    unit_cube.Size = Vector3.new(1,1,1)
    unit_cube.Material = Enum.Material.SmoothPlastic
    unit_cube.Anchored = true
    unit_cube.Color3 = Color3.new(1,1,1)
end



local unit_sphere = Instance.new("Part") do
    unit_sphere.Size = Vector3.new(1,1,1)
    unit_sphere.Material = Enum.Material.SmoothPlastic
    unit_sphere.Color3 = Color3.new(1,1,1)
    unit_sphere.Shape = Enum.PartType.Ball
end


return {
    UnitCube   = function() return unit_cube:Clone()   end,
    UnitSphere = function() return unit_sphere:Clone() end,
    Make = function(properties) 
        local base = unit_cube:Clone()

        for k, v in pairs(properties) do
            if k == "Size" then base.Size = v end
            if k == "Anchored" then base.Anchored = v end
        end




        return base
    end,

}