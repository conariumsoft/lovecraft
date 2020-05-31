local mathmod = {}

function mathmod.LineToCFrame(vec1, vec2)
    assert(typeof(vec1) == "Vector3")
    assert(typeof(vec2) == "Vector3")
	local v = (vec2-vec1)
	return CFrame.new(vec1 + (v/2), vec2)
end

function mathmod.RandomVec3(range)
    assert(range >= 1, "Too small! Scale up or you'll get useless results!")
    local x =  math.random(-range, range)
    local y =  math.random(-range, range)
    local z =  math.random(-range, range)

    return Vector3.new(x, y, z)
end

function mathmod.GetPureRotation(cframe)
    return (cframe - cframe.Position)
end


return mathmod