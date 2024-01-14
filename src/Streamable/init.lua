local Trove = require(script.Parent.Trove)

local None = require(script.None)
local StatefulInstance = require(script.StatefulInstance)
local Binding = require(script.Binding)
local streamingCompound = require(script.streamingCompound)

local Streamable = {}
--[[
	Special key used in state

	Use it to wipe any pending state or bindings from an expected instance
	```lua
	instance:SetState({
		Transparency = binding
	})

	instance:SetState({
		Transparency = Streamable.None
	})
	```
]]
Streamable.None = None
--[[
	Creates a special value that can be set, subscribed to, and mapped

	```lua
	local binding = Streamable.createBinding(false)
	print(binding:GetValue()) -- false

	binding:SetValue(true)
	print(binding:GetValue()) -- true

	binding:Subscribe(function(newValue)
		-- do something on value changes
	end)

	local newBinding = binding:Map(function(value)
		return value and 1 or 0
	end)

	local subscription = newBinding:Subscribe(print)

	binding:SetValue(false) -- subscription will print 0
	binding:SetValue(true) -- subscription will print 1

	subscription:Disconnect()

	binding:SetValue(false) -- nothing will print
	```
]]
Streamable.createBinding = Binding.new

--[[
	Accepts multiple streams and combines them into one with an `Observe` method that only
	evaluates when all streams are streamed in.

	```lua
	local stream = Streamable.new(model)
	local compound = Streamable.compound({
		Head = stream:Watch("Head"),
		UpperTorso = stream:Watch("UpperTorso"),
	})

	compound:Observe(function(parts, trove)
		local head, upperTorso = parts.Head, parts.UpperTorso
		trove:Add(function()
			print("something streamed out")
		end)
	end)

	-- we are done with this compound
	compound:Destroy()
	```

	Destroying the compound will **NOT** unwatch the original watched parts

	If you need to access the state of these watched parts, either forward declare them or call `Watch` again to re access them.
]]
Streamable.compound = streamingCompound

Streamable.__index = Streamable

--[[
	Constructs a new Streamable base.

	```lua
	local stream = Streamable.new(Workspace.Model)

	stream:Watch("HumanoidRootPart"):Observe(function(instance, trove)
		print(instance, " has streamed in")
		trove:Add(function()
			print("'HumanoidRootPart' streamed out")
		end)
	end)
	```
]]
function Streamable.new(model: Model?)
	local self = setmetatable({}, Streamable)
	self.Instance = model

	self._trove = Trove.new()

	self._watching = {}

	self._trove:Add(function()
		table.clear(self._watching)
	end)

	for _, child in model:GetChildren() do
		self:_onChildAdded(child)
	end
	self._trove:Connect(model.ChildAdded, function(child)
		self:_onChildAdded(child)
	end)

	self._trove:Connect(model.ChildRemoved, function(child)
		self:_onChildRemoved(child)
	end)

	return self
end

function Streamable:_onChildAdded(child)
	local si = self._watching[child.Name]
	if si then
		si:_onStreamed(child)
	end
end

function Streamable:_onChildRemoved(child)
	local si = self._watching[child.Name]
	if si then
		si:_onUnstreamed()
	end
end

--[[
	Watches a new child by name, it is ideal to name children differently to avoid collisions

	```lua
	local child = Streamable:Watch("Part", {
		Position = Vector3.zero
	})
	```

	This method caches, meaning any subsequent calls will return the same watched instance.

	`initialState` will only be regarded on the first call
]]
function Streamable:Watch(name: string, initialState: { any })
	if self._watching[name] then
		return self._watching[name]
	end

	local si = StatefulInstance.new()
	self._trove:Add(si, "_destroy")

	self._watching[name] = si

	local child = self.Instance:FindFirstChild(name)
	if child then
		si:_onStreamed(child)
	end

	si:_init(initialState)

	return si
end

function Streamable:UnWatch(name: string)
	local si = self._watching[name]
	if si then
		self._trove:Remove(si)
		self._watching[name] = nil
	end
end

function Streamable:Destroy()
	self._trove:Destroy()
end

return Streamable
