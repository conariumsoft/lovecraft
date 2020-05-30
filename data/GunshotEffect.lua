return function (gun)

	gun.Rifling.Fire:Stop()
	gun.Rifling.Fire.TimePosition = 0.1
	gun.Rifling.Fire:Play()

    gun.Rifling.PointLight.Enabled = true
	gun.Rifling.BillboardGui.Enabled = true
	gun.Rifling.BillboardGui.ImageLabel.Rotation = math.random(0, 360)
	delay(1/20, function()
		gun.Rifling.BillboardGui.Enabled = false
    end)
    
    delay(1/10, function()
        gun.Rifling.PointLight.Enabled = false
    end)
end