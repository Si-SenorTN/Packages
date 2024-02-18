local Signal = require(script.Parent.Parent.Signal)
local Trove = require(script.Parent.Parent.Trove)

return function(streams)
	local trove = Trove.new()
	local shownTrove = trove:Extend()
	local streamedIn = trove:Construct(Signal.Good)

	local instances = {}
	local isStreamed = false
	local function update()
		table.clear(instances)
		local didStop = false
		for name, s in streams do
			if not s.IsStreamed then
				didStop = true
				break
			else
				instances[name] = s.Instance
			end
		end

		if didStop then
			shownTrove:Destroy()
		elseif not isStreamed then
			isStreamed = true
			shownTrove:Add(function()
				isStreamed = false
			end)
			streamedIn:Fire(instances, shownTrove)
		end
	end

	for _, s in streams do
		trove:Add(s:Observe(update))
	end

	return {
		Observe = function(_, handler)
			if isStreamed then
				task.spawn(handler, instances, shownTrove)
			end
			return streamedIn:Connect(handler)
		end,

		Destroy = function(_)
			trove:Destroy()
		end,
	}
end
