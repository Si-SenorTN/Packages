local Trove = require(script.Parent.Trove)
local Symbol = require(script.Parent.Symbol)

local ERR_NOT_DICTIONARY = "State must be a dictionary"

local State = Symbol.named("State")
local Observers = Symbol.named("Observers")
local DeleteToken = Symbol.named("DeleteToken")

local Config = {}
Config.prototype = {}

Config.DeleteToken = DeleteToken

local globalConfigs = {}

function Config.new(initialState: {[string]: any})
	assert(type(initialState) == "table", ERR_NOT_DICTIONARY)

	local state = initialState or {}

	local metatable = { __index = Config.prototype }
	local self = setmetatable({
		[State] = state,
		[Observers] = {}
	}, metatable)

	return self
end

function Config.newGlobalConfig(name, ...)
	local gconfig = Config.new(name, ...)

	globalConfigs[name] = gconfig
end

function Config.getGlobalConfig(name)
	return assert(globalConfigs[name], string.format("%q does not exist within GlobalConfigs", name))
end

function Config.prototype:Set(state)
	assert(type(state) == "table", ERR_NOT_DICTIONARY)
	-- override our entire state, check our observers. if theyre watching for a certain key AND its been changed, then do the
	-- necessary update. if there was no change or key was removed, do nothing to it

	local observers = self[Observers]

	for name, data in pairs(observers) do

	end
end

return Config