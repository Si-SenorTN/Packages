local VELOCITY_THRESHOLD = 0.001
local POSITION_THRESHOLD = 0.001

local sqrt = math.sqrt
local exp = math.exp
local cos = math.cos
local sin = math.sin

local function getPV(d, s, p0, v0, tar, dt)
	local t = s*dt
	local d2 = d*d

	local h, si, co
	if d2 < 1 then
		h = sqrt(1 - d2)
		local e = exp(-d*t)/h
		co, si = e*cos(h*t), e*sin(h*t)
	elseif d2 == 1 then
		h = 1
		local e = exp(-d*t)/h
		co, si = e, e*t
	else
		h = sqrt(d2 - 1)
		local u = exp((-d + h)*t)/(2*h)
		local v = exp((-d - h)*t)/(2*h)
		co, si = u + v, u - v
	end

	local a0 = h*co + d*si
	local a1 = 1 - (h*co + d*si)
	local a2 = si/s

	local b0 = -s*si
	local b1 = s*si
	local b2 = h*co - d*si

	return a0*p0 + a1*tar + a2*v0, b0*p0 + b1*tar + b2*v0
end

local function absOr(x)
	return type(x) == "number" and math.abs(x) or x
end

return function (damping, speed, position, velocity, target, deltaTime)
	local p, v = getPV(damping, speed, position, velocity, target, deltaTime)
	local velThreshhold = absOr(v) + VELOCITY_THRESHOLD
	local posThreshold = absOr(p - target) + POSITION_THRESHOLD

	local completed = v < velThreshhold and p < posThreshold

	return p, v, completed
end