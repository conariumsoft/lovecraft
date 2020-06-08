print("Initializing Client Loading Sequence")
local ReplicatedFirst   = game:GetService("ReplicatedFirst")
local ContentProvider   = game:GetService("ContentProvider")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local bindable = Instance.new("BindableEvent")
bindable.Name = "ClientReady"
bindable.Parent = ReplicatedStorage


local part = script.Parent.LoadingScreen:Clone()
part.Parent = game.Workspace


local LoadingScreen = part.LoadingScreen
--LoadingScreen.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui", 10)

ReplicatedFirst:RemoveDefaultLoadingScreen()

local brk = true

spawn(function()
	while brk do
		wait()
		part.CFrame = game.Workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -10) * CFrame.Angles(0, math.rad(179), 0)
	end
end)

if not game:IsLoaded() then
    game.Loaded:Wait()
end

wait(1)

local tween0 = TweenService:Create(
	LoadingScreen.Frame.Presents, 
	TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0.5), 
	{TextTransparency = 0}
)

tween0:Play()

LoadingScreen.Frame.Title.Size = UDim2.new(0, 0, 0.1, 0)
local tween = TweenService:Create(
	LoadingScreen.Frame.Title, 
	TweenInfo.new(1.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 2), 
	{Size = UDim2.new(0.5, 0, 0.1, 0)}
)

tween:Play()


local tween2 = TweenService:Create(
	LoadingScreen.Frame.Title.Title2, 
	TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 3), 
	{TextTransparency = 0}
)

tween2:Play()
---------
wait(6)
local tween0out = TweenService:Create(
	LoadingScreen.Frame.Title.Title2, 
	TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0), 
	{TextTransparency = 1}
)
tween0out:Play()

local tween1out = TweenService:Create(
	LoadingScreen.Frame.Presents, 
	TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, false, 0), 
	{TextTransparency = 1}
)

tween1out:Play()


local tween2out = TweenService:Create(
	LoadingScreen.Frame.Title, 
	TweenInfo.new(1.25, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false, 1.25), 
	{Size = UDim2.new(0, 0, 0.1, 0)}
)

tween2out:Play()
wait(2.5)
LoadingScreen:Destroy()
part:Destroy()
brk = false