local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages

local Table = require(Packages.Table)
local Symbol = require(Packages.Symbol)
local strict = require(Packages.strict)

local Events = {}
Events.Schedulers = strict({
	PreSimulation = RunService.RenderStepped,
	PostSimulation = RunService.Heartbeat
})

function Events.getNetworkConnection()
	if RunService:IsClient() then
		return Events.Schedulers.PreSimulation
	elseif RunService:IsRunning() then
		return Events.Schedulers.PostSimulation
	else
		error("Unknown state", 2)
	end
end

function Events.lockTo(signal, rate)
	local frameRate = 1 / rate

	local lockedObject = {}
	local handlers = {}

	local frameCount = 0
	local connection = signal:Connect(function(deltaTime)
		frameCount += deltaTime
		if frameCount >= frameRate then
			frameCount = 0
			for _, handler in pairs(handlers) do
				handler(deltaTime)
			end
		end
	end)

	function lockedObject:Add(handler)
		table.insert(handlers, handler)
	end

	function lockedObject:Disconnect()
		connection:Disconnect()
		connection = nil
		handlers = nil
		table.clear(self)
	end
	lockedObject.Destroy = lockedObject.Disconnect

	return lockedObject
end

local collectiveScheduler = {} do
	collectiveScheduler.prototype = {}

	function collectiveScheduler.new(signal, rate)
		return setmetatable({
			_scheduler = signal,
			_rate = 1 / rate,
			_eventHandlers = {}
		}, { __index = collectiveScheduler.prototype })
	end

	function collectiveScheduler.prototype:GetRate()
		return self._rate
	end

	function collectiveScheduler.prototype:SetRate(rate)
		self._rate = 1 / rate
	end

	function collectiveScheduler.prototype:SetScheduler(scheduler)
		local started = self._started
		self:Stop()
		self._scheduler = scheduler

		if started then
			self:Start()
		end
	end

	function collectiveScheduler.prototype:Automatic()
		self._automaticBehavior = true
	end

	function collectiveScheduler.prototype:Manual()
		self._automaticBehavior = nil
	end

	function collectiveScheduler.prototype:Add(handler)
		local marker = Symbol.unnamed()
		self._eventHandlers[marker] = handler
		if self._automaticBehavior and not Table.empty(self._eventHandlers) then
			self:Start()
		end
		return marker
	end

	function collectiveScheduler.prototype:Remove(marker)
		self._eventHandlers[marker] = nil
		if self._automaticBehavior and Table.empty(self._eventHandlers) then
			self:Stop()
		end
	end

	function collectiveScheduler.prototype:Clear()
		table.clear(self._eventHandlers)
		if self._automaticBehavior then
			self:Stop()
		end
	end

	function collectiveScheduler.prototype:Flush(...)
		for _, handler in pairs(self._eventHandlers) do
			handler(...)
		end
	end

	function collectiveScheduler.prototype:Start()
		if self._started then
			return
		end
		self._started = true

		local scheduler = assert(self._scheduler, "TrackerClass must include a proper Scheduler!")
		local accumulated = 0
		self._connection = scheduler:Connect(function(deltaTime)
			accumulated += deltaTime
			if accumulated >= self._rate then
				accumulated = 0
				self:Flush(deltaTime)
			end
		end)
	end

	function collectiveScheduler.prototype:Stop()
		if self._connection then
			self._connection:Disconnect()
			self._connection = nil
			self._started = false
		end
	end

	function collectiveScheduler.prototype:Destroy()
		self:Stop()
		self:Clear()
	end
end

function Events.consolidate(signal, rate)
	return collectiveScheduler.new(signal, rate)
end

return Events