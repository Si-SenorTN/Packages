local function createYieldable(value)
	local yieldable = {
		Value = value
	}

	local function getValue()
		return yieldable.Value
	end

	local function setValue(newValue)
		yieldable.Value = newValue

		if yieldable.resumeThread then
			yieldable.resumeThread()
		end
	end

	local function evaluate(expected)
		return yieldable.Value == expected
	end

	local function waitUntil(expectedValue)
		if evaluate(expectedValue) then
			return
		end
		local runningCoroutine = coroutine.running()
		yieldable.resumeThread = function()
			task.spawn(runningCoroutine)
			yieldable.resumeThread = nil
		end

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