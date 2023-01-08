local Trove = require(script.Parent.Parent.Trove)
local Signal = require(script.Parent.Parent.Signal)

local None = require(script.Parent.None)

local function isBinding(value)
	if type(value) == "table" and value.Subscribe and value.GetValue then
		return true
	end

	return false
end

local StatefulInstance = {}
StatefulInstance.__index = StatefulInstance

function StatefulInstance.new()
	local self = setmetatable({}, StatefulInstance)

	self.IsStreamed = false

	self._streamed = Signal.Good.new()
	self._streamedTrove = Trove.new()

	self._pendingState = {}
	self._bindings = {}

	return self
end

function StatefulInstance:_init(initialState: { any }?)
	if initialState then
		self:SetState(initialState)
	end
end

--[[
	Sets the state of a streaming instance.

	State can be primative types that represent valid Properties of the steaming instance ONLY. It is necessary that types do not mimatch or you will cause errors.

	State can also be bindings that represent valid Properties, as so:
	```lua
	local pos = Streamable.createBinding(Vector3.zero)
	si:SetState({
		Position = pos
	})
	```
	Bindings are exceptions to the typical state updates, meaning that any time the binding is set via `binding:SetValue(x)` it will update the instances property to the bindings value.

	It is also important to note that stateUpdater is partial and will reconcile with previous state on multiple `SetState` calls. Reconciliation will only occur when the instance is not streamed in, otherwise set state is immediate.
	```lua
	-- in this example, 'si' is NOT streamed in
	si:SetState({
		Position = Vector3.zero
	})
	print(si:GetState()) --> { Position = Vector3<0, 0, 0> }

	si:SetState({
		Anchored = true,
		CanCollide = false
	})
	print(si:GetState()) --> { Position = Vector3<0, 0, 0>, Anchored = true, CanCollide = false }
	```

	stateUpdater can optionally be a function, that will return a partial state. Within the state updater function you will have access to the current read only state. If you choose to return `nil`, the state update will be omitted
	```lua
	si:SetState(function(currentState)
		if currentState.Anchored then
			return {
				Anchored = false
			}
		else
			-- omit the state update
			return nil
		end
	end)
	```
]]
function StatefulInstance:SetState(stateUpdater: { any })
	if type(stateUpdater) == "table" then
		self:_setPendingState(stateUpdater)
		self:_applyState()
	elseif type(stateUpdater) == "function" then
		local newState = stateUpdater(self:GetState())
		if newState then
			self:_setPendingState(newState)
			self:_applyState()
		end
	else
		error("Cannot apply state, " .. tostring(stateUpdater), 2)
	end
end

--[[
	Returns a read-only, shallow copy of pending state.

	Bindings will appear as the current value that they represent. This state view is intended to only be a snapshot, and will not update when bindings change until you call `GetState` again.
]]
function StatefulInstance:GetState()
	local state = table.clone(self._pendingState)
	for propertyName, binding in self._bindings do
		state[propertyName] = binding.object:GetValue()
	end

	return table.freeze(state)
end

--[[
	Provides a method for watching the instance stream in and out, with a trove.
	trove automatically cleans up when the instance unstreams

	```lua
	local connection = part:Observe(function(instance, trove)
		print(instance, "streamed in")
		trove:Add(function()
			print("streamed out")
		end)
	end)
	```
]]
function StatefulInstance:Observe(callback)
	if self.Instance then
		task.spawn(callback, self.Instance, self._streamedTrove)
	end
	return self._streamed:Connect(callback)
end

function StatefulInstance:ClearState()
	table.clear(self._pendingState)
	self:_clearBindings()
end

function StatefulInstance:_clearBindings()
	for _, binding in self._bindings do
		binding.connection:Disconnect()
	end
	table.clear(self._bindings)
end

function StatefulInstance:_setPendingState(partialState)
	local function disconnectBinding(propertyName)
		local binding = self._bindings[propertyName]
		if binding then
			self._bindings[propertyName].connection:Disconnect()
			self._bindings[propertyName] = nil
		end
	end

	local function connectBinding(propertyName, binding)
		disconnectBinding(propertyName)

		self._bindings[propertyName] = {
			connection = binding:Subscribe(function(value)
				if self.Instance then
					self.Instance[propertyName] = value
				end
			end),
			object = binding,
		}
	end

	local newState = table.clone(self._pendingState)

	for propertyName, propertyValue in partialState do
		if isBinding(propertyValue) then
			connectBinding(propertyName, propertyValue)
		elseif propertyValue == None then
			if self._bindings[propertyName] then
				disconnectBinding(propertyName)
			else
				newState[propertyName] = nil
			end
		else
			newState[propertyName] = propertyValue
		end
	end

	self._pendingState = newState
end

function StatefulInstance:_applyState()
	if next(self._pendingState) and self.IsStreamed then
		for propertyName, propertyValue in self._pendingState do
			local success, err = pcall(function()
				self.Instance[propertyName] = propertyValue
			end)

			if not success then
				warn(err)
			end
		end

		for propertyName, binding in self._bindings do
			self.Instance[propertyName] = binding.object:GetValue()
		end
	end
end

function StatefulInstance:_onStreamed(instance)
	self.Instance = instance
	self.IsStreamed = true

	self._streamed:Fire(self.Instance, self._streamedTrove)

	self:_applyState()
end

function StatefulInstance:_onUnstreamed()
	self.Instance = nil
	self.IsStreamed = false

	self._streamedTrove:Destroy()
end

function StatefulInstance:_destroy()
	self._streamed:DisconnectAll()
	self:_onUnstreamed()

	self:ClearState()
end

return StatefulInstance
