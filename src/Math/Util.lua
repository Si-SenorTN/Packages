--!strict

local Math = {}

local function cSquared(pointA: Vector3 | Vector2, pointB: Vector3 | Vector2)
	local z = typeof(pointA) == "Vector3" and (pointA.Z - pointB.Z)^2 or 0
	return (pointA.X - pointB.X)^2 + (pointA.Y - pointB.Y)^2 + z
end

function Math.map(num, min0, max0, min1, max1)
	if max0 == min0 then
		error("Range of zero")
	end
	return (((num - min0)*(max1 - min1)) / (max0 - min0)) + min1
end

--- Interpolates between two numbers based off percentage given
--- @return number x interpolated num0 towards num1 based off percent
function Math.lerp(num0: number, num1: number, percent: number)
	math.clamp(percent, 0, 1)
	return num0 + ((num1 - num0) * percent)
end

--- Reflects a Vector from a surface normal
--- @return Vector3 reflected
function Math.reflect(v: Vector3, n: Vector3)
	return -2 * v:Dot(n) * n + v
end

--- Determines the distance between two Vector points
--- @return number dist distace/magnitude
function Math.distance(pointA: Vector3 | Vector2, pointB: Vector3 | Vector2)
	return math.sqrt(cSquared(pointA, pointB))
end

--- Determines if pointA is within pointB by given radius
--- @return boolean isWithin pointA is within radius of pointB
 function Math.within(pointA: Vector3 | Vector2, pointB: Vector3 | Vector2, radius: number)
	return Math.distance(pointA, pointB) <= radius
end

--- Returns the inverse of x, where min is the Minimum range and max the Maximum range
--- @return number inversed inverse of x within range min/max
function Math.inverse(min: number, max: number, x: number): number
	return (max + min) - x
end

--- Determins if pointB is infront pointA given the target angle
--- @return boolean isFront pointB is infront of pointA
function Math.isFront(pointA: CFrame, pointB: CFrame, targAngle: number)
	local facing = pointA.LookVector
	local vectorUnit = (pointA.Position - pointB.Position).Unit
	local angle = math.acos(facing:Dot(vectorUnit))

	return angle >= targAngle
end

--- Determines if argument is NaN
--- @return boolean isNaN
function Math.isNaN(num: (number?))
	return string.find(tostring(num), "nan") ~= nil
end

return Math