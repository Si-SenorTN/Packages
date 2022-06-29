local function createYieldable(value)
	local yieldable = {
		Value = value,
	}

	local yieldingTheads = {}

	local function getValue()
		return yieldable.Value
	end

	local function setValue(newValue)
		yieldable.Value = newValue

		for index, yielding in pairs(yieldingTheads) do
			if yielding.evaluate(newValue) then
				task.spawn(yielding.thread)
				table.remove(yieldingTheads, index)
			end
		end
	end

	local function waitUntil(expectedValue)
		local function evaluate(expected)
			return yieldable.Value == expected
		end

		if evaluate(expectedValue) then
			return
		end

		local runningCoroutine = coroutine.running()

		table.insert(yieldingTheads, {
			evaluate = evaluate,
			thread = runningCoroutine
		})

		return coroutine.yield()
	end

	return {
		waitUntil = waitUntil,
		getValue = getValue
	}, setValue
end

return {
	create = createYieldable
}