return function (gun)
	gun.Muzzle.Fire:Stop()
	gun.Muzzle.Fire.TimePosition = 0.1
	gun.Muzzle.Fire:Play()

    gun.Muzzle.PointLight.Enabled = true
	gun.Muzzle.BillboardGui.Enabled = true
	gun.Muzzle.BillboardGui.ImageLabel.Rotation = math.random(0, 360)
	delay(1/20, function()
		gun.Muzzle.BillboardGui.Enabled = false
    end)
    
    delay(1/10, function()
        gun.Muzzle.PointLight.Enabled = false
    end)
end