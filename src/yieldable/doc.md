# yieldable

## Usage

A `yieldable` is a class meant to eradicate the need for inefficient polling.

Polling is the act of pausing a thread until a certain criteria is met.
Polling at its lowest level can be represented as such

```lua
local value = true

local function waitUntil(expectedValue)
	repeat
		task.wait()
	until value == value
end

waitUntil(false)
```

The same can be achieved via `while value ~= expectedValue` loop. Both of these methods, while they do work, can be boiled down to the same bad practice: using `wait` when there are faster more efficient methods.

### Enter `coroutines` and `task` library.

Since the addition of the task library we are able to `spawn` functions/coroutines immediately through the engine scheduler.

Utilizing `coroutine.yield` and `task.spawn` we can come up with a much faster method

```lua
local yieldable = require(somewhere.yieldable)

local value, setValue = yieldable.create(false)

local function somethingImportant()
	-- some important init

	-- poll until our value equates to `true`
	value:waitUntil(true)
	-- and after 5 seconds this should print true
	print(value:getValue())

	-- some other important finishing code
end

-- in actual production this would probably some kind of event connection, but for examples sake:
task.spawn(somethingImportant)

-- set the value, causing our yieldable to evaluate equivalence
task.delay(5, setValue, true)
```