local DISTANCE = 1000 -- in studs

local UserInputService = game:GetService("UserInputService")

local Cursor = {}
Cursor.prototype = {}

function Cursor.new()
	local metatable = { __index = Cursor.prototype }
	local self = setmetatable({}, metatable)

	self.DefaultSensitivity = UserInputService.MouseDeltaSensitivity
	self._sensitivityFactor = 2

	return self
end

function Cursor.GetMousePosition()
	return UserInputService:GetMouseLocation()
end

function Cursor.DefaultMouseBehavior()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function Cursor.LockCurrentPosition()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end

function Cursor.LockCenter()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function Cursor.prototype:Raycast(raycastParams, distance)
	assert(typeof(raycastParams) == "RaycastParams", "assertion failed!")

	local mouseRay = self:GetMouseUnitRay()
	local result = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * (distance or DISTANCE), raycastParams)

	return result
end

function Cursor.prototype:GetMouseRay(depth)
	return self:GetMouseUnitRay(depth or DISTANCE)
end

function Cursor.prototype:GetMouseUnitRay(depth)
	local mouseLocation = Cursor.GetMousePosition()
	return workspace.CurrentCamera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y, depth or 0)
end

function Cursor.prototype:GetSensitivity()
	return UserInputService.MouseDeltaSensitivity
end

function Cursor.prototype:SetSensitivity(amount)
	UserInputService.MouseDeltaSensitivity = amount
end

function Cursor.prototype:GetSensitivityFactor()
	return self._sensitivityFactor
end

function Cursor.prototype:SetSensitivityFactor(factor)
	self._sensitivityFactor = factor
end

function Cursor.prototype:SetDefaultSensitivity()
	self:SetSensitivity(self.DefaultSensitivity)
end

function Cursor.prototype:ApplySensitivityFactor()
	self:SetSensitivity(self.DefaultSensitivity / self._sensitivityFactor)
end

return Cursor