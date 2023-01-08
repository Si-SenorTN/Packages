local Signal = require(script.Parent.Parent.Signal)

local Binding = {}
Binding.__index = Binding

function Binding.new(initialValue: any)
	local self = setmetatable({}, Binding)

	self._value = initialValue
	self._changed = Signal.Good.new()

	return self
end

function Binding:Subscribe(callback)
	return self._changed:Connect(callback)
end

function Binding:GetValue()
	return self._value
end

function Binding:SetValue(newValue)
	local shouldFireChange = self._value ~= newValue
	self._value = newValue
	if shouldFireChange then
		self._changed:Fire(self._value)
	end
end

function Binding:Map(predicate)
	local newBinding = {}

	newBinding.Subscribe = function(_self, callback)
		return self:Subscribe(function(value)
			callback(predicate(value))
		end)
	end

	newBinding.GetValue = function(_self)
		return predicate(self:GetValue())
	end

	return newBinding
end

function Binding:Destroy()
	self._changed:DisconnectAll()
end

return Binding
