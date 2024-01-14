local function truthy(x)
	return x ~= nil
end

local function untruthy(x)
	return not x
end

local function isTrue(x)
	return x == true
end

local function isFalse(x)
	return x == false
end

local function equals(x)
	return function(y)
		return y == x
	end
end

local function greaterThan(x)
	return function(y)
		return x > y
	end
end

local function lessThan(x)
	return function(y)
		return x < y
	end
end

local function createYieldable(value: any)
	local yieldable = {
		Value = value,
	}

	local yieldingTheads = {}

	local function getValue(_)
		return yieldable.Value
	end

	local function setValue(_, newValue: any)
		local oldValue = yieldable.Value
		yieldable.Value = newValue

		for index, yielding in yieldingTheads do
			if yielding.predicate(newValue, oldValue) then
				task.spawn(yielding.thread)
				table.remove(yieldingTheads, index)
			end
		end
	end

	local function waitUntil(_, predicate)
		if predicate(yieldable.Value, nil) then
			return
		end

		local runningCoroutine = coroutine.running()

		table.insert(yieldingTheads, {
			predicate = predicate,
			thread = runningCoroutine,
		})

		return coroutine.yield()
	end

	return {
		waitUntil = waitUntil,
		getValue = getValue,
		setValue = setValue,
	}
end

return {
	create = createYieldable,

	truthy = truthy,
	untruthy = untruthy,

	isTrue = isTrue,
	isFalse = isFalse,

	equals = equals,
	greaterThan = greaterThan,
	lessThan = lessThan,
}
