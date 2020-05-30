-- Handles reflection of server-side events

return function (shooter, gun)
	if shooter ~= game.Players.LocalPlayer then

		gun.Fire:Stop()
		gun.Fire.TimePosition = 0.05
		gun.Fire:Play()

		gun.Rifling.BillboardGui.Enabled = true
		gun.Rifling.BillboardGui.ImageLabel.Rotation = math.random(0, 360)
		delay(1/20, function()
			gun.Rifling.BillboardGui.Enabled = false
		end)
	end
end