local Physics = {}

local PointSolver   = require(script.PointSolver)
local LineSolver    = require(script.LineSolver)
local SurfaceSolver = require(script.SurfaceSolver)



function Physics.CreatePointSolver(...)
    return PointSolver:new(...)
end

function Physics.CreateLineSolver(...)
    return LineSolver:new(...)
end

function Physics.CreateSurfaceSolver(...)
    return SurfaceSolver:new(...)
end

return Physics