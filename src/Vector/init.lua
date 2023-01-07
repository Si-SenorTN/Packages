local RNG = Random.new()
local NORMALIZED = (Vector3.one).Unit

local VectorUtil = {}

function VectorUtil.limit(vector, mag)
	return vector.Magnitude <= mag and vector or vector.Unit * mag
end

function VectorUtil.setMag(vector, mag)
	local normalized = vector.Unit
	if vector == Vector3.zero then
		normalized = NORMALIZED
	end
	return normalized * mag
end

function VectorUtil.heading2D(vector: Vector2)
	return math.atan2(vector.Y, vector.X)
end

function VectorUtil.heading3D(vector: Vector3)
	return math.atan2(vector.Z, vector.X)
end

function VectorUtil.random(range: number)
	return Vector3.new(RNG:NextNumber(-range, range), RNG:NextNumber(-range, range), RNG:NextNumber(-range, range))
end

function VectorUtil.angleBetween(vector1, vector2)
	return math.acos(math.clamp(vector1.Unit:Dot(vector2.Unit), -1, 1))
end

function VectorUtil.project(startPoint, future, endPoint)
	local v1, v2 = future - startPoint, (endPoint - startPoint).Unit
	local scalar = v1:Dot(v2)
	return (v2 * scalar) + startPoint
end

return VectorUtil
