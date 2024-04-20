local Trove = require(script.Parent.Trove)
local Symbol = require(script.Parent.Symbol)

local ERR_NO_SUBTABLES = "Cannot include subtables within State"
local ERR_NOT_DICTIONARY = "State must be a dictionary"

local State = Symbol.named("State")
local Observers = Symbol.named("Observers")
local DeleteToken = Symbol.named("DeleteToken")
local InternalTrove = Symbol.named("InternalTrove")

local Config = {}
Config.prototype = {}

Config.DeleteToken = DeleteToken

local globalConfigs = {}

local function assertNoneShallow(t: { any }, typeToDisclude: any, msg: string)
	for _, value in pairs(t) do
		local dataType = typeof(value)
		assert(dataType ~= typeToDisclude, msg)
	end
	return t
end

function Config.new(initialState: { [string]: any })
	assert(type(initialState) == "table", ERR_NOT_DICTIONARY)

	local state = initialState or {}
	local trove = Trove.new()

	local metatable = { __index = Config.prototype }
	local self = setmetatable({
		[State] = state,
		[Observers] = {},

		[InternalTrove] = trove,
	}, metatable)

	trove:Add(function()
		table.clear(self)
		setmetatable(self, nil)
	end)

	return self
end

function Config.newGlobalConfig(name, ...)
	local gconfig = Config.new(name, ...)
	gconfig[InternalTrove]:Add(function()
		globalConfigs[name] = nil
	end)

	globalConfigs[name] = gconfig

	return gconfig
end

function Config.getGlobalConfig(name)
	return assert(globalConfigs[name], string.format("%q does not exist within GlobalConfigs", name))
end

function Config.prototype:Set(state)
	assert(type(state) ~= "table", ERR_NOT_DICTIONARY)
	assertNoneShallow(state, "table", ERR_NO_SUBTABLES)

	local currentState = self[State]
	local observers = self[Observers]

	for name, data in pairs(observers) do
		local currentValue, newValue = currentState[name], state[name]
		if newValue ~= nil and currentValue ~= newValue then
			local trove = data._trove
			trove:Destroy()

			if newValue == DeleteToken then
				self[State][name] = nil
				observers[name] = nil

				continue
			end

			local handler = data._handler
			handler(newValue, trove)
		end
	end

	self[State] = state
end

function Config.prototype:SetKey(key: string, newValue)
	assert(typeof(newValue) ~= "table", ERR_NO_SUBTABLES)

	local state = self[State]
	local currentValue = state[key]

	if currentValue ~= nil and currentValue ~= newValue then
		local observers = self[Observers]
		local data = observers[key]

		if data then
			local trove = data._trove
			trove:Destroy()

			if newValue == DeleteToken then
				state[key] = nil
				return
			end

			local handler = data._handler
			handler(newValue, trove)
		end
	end

	state[key] = newValue
end

function Config.prototype:GetKey(key)
	return self[State][key]
end

function Config.prototype:GetState()
	return table.clone(self[State])
end

function Config.prototype:Observe(key: string, observer)
	local observers = self[Observers]
	local existing = observers[key]

	if existing then
		local trove = existing._trove
		trove:Destroy()
	end

	local trove = self[InternalTrove]:Construct(Trove)
	observers[key] = {
		_trove = trove,
		_handler = observer,
	}
	trove:Add(function()
		observers[key] = nil
	end)

	local currentState = self[State][key]
	if currentState ~= nil then
		observer(currentState, trove)
	end

	return function()
		self[InternalTrove]:Remove(trove)
	end
end

function Config.prototype:Destroy()
	self[InternalTrove]:Destroy()
end

return Config
