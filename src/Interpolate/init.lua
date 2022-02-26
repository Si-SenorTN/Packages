export type StepValueType = Color3 | UDim | UDim2 | Vector2 | Vector3 | number
export type StepFunction = (d: number, s: number, p0: StepValueType, v0: StepValueType, tar: StepValueType, dt: number) -> (StepValueType, StepValueType, boolean)
export type InterpolationParams = {
	Damping: number,
	Speed: number,
	Target: StepValueType,

	StepFunction: StepFunction,
	StepEvent: RBXScriptSignal
}

local RunService = game:GetService("RunService")

local Interpolator = require(script.Interpolator)
local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)
local list = require(script.Parent.list)

local Interpolate = {
	Kind = strict(list.shallow(script.Kind))
}

local allInterpolators = {}

local interpolationParams = {} do
	local function getInterpolationSettings(): InterpolationParams
		return {
			Damping = 1,
			Speed = 1,
			Target = 0,

			Clock = os.clock,
			StepFunction = Interpolate.Kind.Linear,
			StepEvent = RunService.Heartbeat
		}
	end

	interpolationParams.new = getInterpolationSettings
end
Interpolate.InterpolationParams = interpolationParams

local function mandate(val, t, msg)
	if val ~= nil then
		return assert(typeof(val) == t, msg)
	end
end

function Interpolate.Create(params: InterpolationParams, name: string?)
	local inter = Interpolator.new(params)

	if mandate(name, "string", "Name must be a string in order for Interpolator to be queried!") then
		local sym = Symbol.named(name)
		allInterpolators[sym] = inter
	end

	return inter
end

function Interpolate.Query(sym: Symbol.NamedSymbol)
	return assert(allInterpolators[sym], sym.." is not a valid member of Interpolators[]")
end

return Interpolate