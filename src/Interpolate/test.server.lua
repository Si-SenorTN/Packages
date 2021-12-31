local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages

local Interpolate = require(Packages.Interpolate)

local interParams = Interpolate.InterpolationParams.new()
interParams.Speed = 10
interParams.Dampening = .6
interParams.Target = Vector3.new()
interParams.StepFunction = Interpolate.Kind.Spring

local COMPLETE_COLOR = BrickColor.new("Bright green")
local NOT_COMPLETE_COLOR = BrickColor.new("Bright red")
local p0, p1 = workspace:WaitForChild("part0"), workspace:WaitForChild("part1")

local int = Interpolate.Create(interParams)
int:OnStep(function(position, isComplete)
	p0.Position = position
	p0.BrickColor = isComplete and COMPLETE_COLOR or NOT_COMPLETE_COLOR
end)
int:Start()

local function onPosChange()
	int.Target = p1.Position
end

p1:GetPropertyChangedSignal("Position"):Connect(onPosChange)
onPosChange()