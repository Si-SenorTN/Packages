local set = require(script.Parent.set)
local Signal = require(script.Parent.Signal)

local typeClassMap = {
	boolean = "BoolValue";
	string = "StringValue";
	table = true;
	CFrame = "CFrameValue";
	Color3 = "Color3Value";
	BrickColor = "BrickColorValue";
	number = "NumberValue";
	Instance = "ObjectValue";
	Ray = "RayValue";
	Vector3 = "Vector3Value";
	["nil"] = "ObjectValue";
}

local Attribute = {}
Attribute.prototype = {}

function Attribute.Is(object)
	return type(object) == "table" and getmetatable(object) == Attribute
end

function Attribute.new(value)
	local t = typeof(value)
	local class = assert(typeClassMap[t], "Attribute does not support type \"" .. t .. "\"")

	local metatable = { __index = Attribute }
	local self = setmetatable({
		_value = value,
		_isTable = (t == "table")
	}, metatable)

	if self._isTable then
		self.Changed = Signal.Good.new()
	else
		self._object = Instance.new(class)
		self._object.Value = value
		self.Changed = self._object.Changed
	end

	return self
end

function Attribute.prototype:Set(value)
	if self._isTable then
		self.Changed:Fire(value)
	else
		self._object.Value = value
	end
	self._value = value
end

function Attribute.prototype:Get()
	return self._value
end

function Attribute.prototype:Mount(parent: Instance, props: {any})
	if not self._isTable then
		if props then
			set.properties(self._object, props)
		end

		self._object.Parent = parent
	end
end

function Attribute.prototype:Destroy()
	if self._object then
		self._object:Destroy()
	end

	table.clear(self)
	setmetatable(self, nil)
end

return Attribute