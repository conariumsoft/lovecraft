local RunService = game:GetService("RunService")
local TestAutomation = {}

local running = false
local has_deployed_task = false

-- this is totally gonna be a giant fucking memory leak, but it's just a testing tools
local task = coroutine.create(function()
	while true do
		if (running) then
			require(game.ReplicatedStorage.Test:Clone())()
		end
		wait(1/8) -- should be nice enuff
	end
end)

function TestAutomation.StartThread()
	running = true
	if (has_deployed_task == false) then
		has_deployed_task = true
		coroutine.resume(task)
	end
end

function TestAutomation.StopThread()
	running = false
	--coroutine.yield(task)
end


return TestAutomation