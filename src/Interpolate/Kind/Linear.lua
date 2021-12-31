local function getpv(s, p0, v0, tar, dt)
	local p = p0
	local v = v0 * dt
	p += v * (tar > p and s or -s)

	return p, v
end

local function absOr(x)
	return type(x) == "number" and math.abs(x) or x
end

return function (_, s, p0, v0, tar, dt)
	local p, v = getpv(s, p0, v0, tar, dt)
	local goal = tar

	local completed = v >= absOr(goal - p)

	return p, v, completed
end