local Symbol = require(script.Parent.Parent.Symbol)

local Interpolator = {}
Interpolator.prototype = {}

function Interpolator.new(interpolationParams)
	local init = interpolationParams.Target
	local clock = interpolationParams.Clock

	local self = setmetatable({
		_clock = clock,
		_t0 = clock(),
		_p0 = init,
		_v0 = 0 * (init or 0),
		_s = interpolationParams.Speed,
		_d = interpolationParams.Damping,
		_tar = init or 0,

		_completed = false,
		_getpv = interpolationParams.StepFunction,
		_stepEvent = interpolationParams.StepEvent,

		_onStepFuncs = {}
	}, Interpolator.prototype)

	return self
end

function Interpolator.prototype:__index(index)
	local s = string.lower(index)

	if Interpolator.prototype[index] then
		return Interpolator.prototype[index]
	end

	if s == "position" or s == "p" then
		local p = self:Step()
		return p
	elseif s == "velocity" or s == "v" then
		local _, v = self:Step()
		return v
	elseif s == "target" or s == "t" then
		return self._t
	elseif s == "complete" or s == "c" then
		return self._completed
	elseif index == "a" or index == "Acceleration" then
		local p, v = self:Step()
		local a = self._s * self._s * (self._tar - p) - 2 * self._s * self._d * v
		return a
	end
end

function Interpolator.prototype:__newindex(index, value)
	local s = string.lower(index)

	self:Step()

	if s == "p" or s == "position" then
		self._p0 = value
	elseif s == "v" or s == "velocity" then
		self._v0 = value
	elseif s == "t" or s == "target" then
		self._tar = value
	elseif s == "d" or s == "dampening" then
		self._d = value
	elseif s == "s" or s == "speed" then
		self._s = value
	end
end

function Interpolator.prototype:SetStepFunc(stepFunc)
	self._getpv = stepFunc
end

function Interpolator.prototype:SetParams(params)
	local init = params.Target
	local clock = self._clock

	self._t0 = clock()
	self._p0 = init
	self._v0 = 0 * (init or 0)
	self._s = params.Speed
	self._d = params.Damping
	self._tar = init or 0

	self._completed = false
	self._getpv = params.StepFunction
	self._stepEvent = params.StepEvent
end

function Interpolator.prototype:Step(dt, stepFuncOverride)
	local stepFunc = stepFuncOverride or self._getpv
	local p, v, completed = stepFunc(self._d, self._s, self._p0, self._v0, self._tar, dt or (self._clock() - self._t0))

	self._t0 = self._clock()
	self._p0 = p
	self._v0 = v
	self._completed = completed

	for _, handler in pairs(self._onStepFuncs) do
		task.spawn(handler, p, completed)
	end

	return p, v
end
Interpolator.prototype.Update = Interpolator.prototype.Step

function Interpolator.prototype:OnStep(onStepHandler: (position: any, isComplete: boolean) -> nil)
	local marker = Symbol.unnamed()
	self._onStepFuncs[marker] = onStepHandler

	return marker
end

function Interpolator.prototype:RemoveOnStep(sym)
	self._onStepFuncs[sym] = nil
end

function Interpolator.prototype:ClearAllOnStep()
	table.clear(self._onStepFuncs)
end

function Interpolator.prototype:Start(stepFuncOverride)
	if self._connection then
		return
	end
	self._connection = self._stepEvent:Connect(function(dt)
		self:Step(dt, stepFuncOverride)
	end)
end

function Interpolator.prototype:Stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

function Interpolator.prototype:IsComplete()
	return self._completed
end

return Interpolator