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
	until value == expectedValue
end

waitUntil(false)
```

The same can be achieved via `while value ~= expectedValue` loop. Both of these methods, while they do work, can be boiled down to the same bad practice: using `wait` when there are faster more efficient methods.

### Enter `coroutines` and `task` library.

Since the addition of the task library we are able to `spawn` functions/coroutines immediately through the engine scheduler.

Utilizing `coroutine.yield` and `task.spawn` we can come up with a much faster method

```lua
local yieldable = require(somewhere.yieldable)

local value = yieldable.create(false)

local function somethingImportant()
	-- some important init

	-- poll until our value equates to `true`
	value:waitUntil(yieldable.isTrue)
	-- and after 5 seconds this should print true
	print(value:getValue())

	-- some other important finishing code
end

-- in actual production this would probably some kind of event connection, but for examples sake:
task.spawn(somethingImportant)

-- set the value, and the yieldable will re evaluate
task.delay(5, function()
	value:setValue(true)
end))
```

`yieldable.waitUntil` accepts a predicate function. If that function returns a truthy value then the thread will resume. The yieldable library comes with a few predicate functions to make simple evaluations.

### `isTrue`
will check for the value, x, being `x == true`
```lua
local x = yieldable.create(false)
task.spawn(function()
	x:waitUntil(yieldable.isTrue)
	print("hello")
end)
x:setValue(true)
```

### `isFalse`
does the exact same as isTrue except it will explicitly check for `x == false`
```lua
local x = yieldable.create(true)
task.spawn(function()
	x:waitUntil(yieldable.isFalse)
	print("hello")
end)
x:setValue(false)
```

### `truthy`
will check for any value that is not nil: `x ~= nil`
```lua
local x = yieldable.create(nil)
task.spawn(function()
	x:waitUntil(yieldable.truthy)
	print("hello")
end)
x:setValue(true) -- this can be any value except nil essentially
```

### `untruthy`
will check for any value that is not nil: `x == nil`
```lua
local x = yieldable.create(6)
task.spawn(function()
	x:waitUntil(yieldable.untruthy)
	print("hello")
end)
x:setValue(nil)
```

### `equals`
checks for equity `x == y` great for numeric comparison or table equity
```lua
----------------------------
-- numeric equity

local y = 7
local x = yieldable.create(6)
task.spawn(function()
	x:waitUntil(yieldable.equals(y))
	print("hello")
end)
x:setValue(7)

----------------------------
-- table Equity

local y = { hello = "world" }
local x = yieldable.create({
	goodbye = "world"
})
task.spawn(function()
	x:waitUntil(yieldable.equals(y))
	print("hello")
end)
x:setValue(y)
```

Remember that this is not a shallow comparison of two tables, this is simply checking if the signatures are the same. If you want to shallow compare tables, you can implement one yourself in the [custom predicate function](#you-can-also-create-your-own-predicate-function-allowing-for-full-customization)

### `greaterThan` and `lessThan`
performs `x > y` and `x < y` respectively.
```lua
local y = 7
local x = yieldable.create(6)
task.spawn(function()
	x:waitUntil(yieldable.greaterThan(y))
	print("hello")
end)
x:setValue(8)
```

### You can also create your own predicate function allowing for full customization.

The first argument will give you access to the value you immediately set it to via `yieldable.create` or `x:setValue()` function and the second argument will provide the previous value if there is one.
```lua
local x = yieldable.create(1)
x:waitUntil(function(newValue, oldValue)
	-- new value will immediately be `1` and old value will be nil
end)

x:setValue(x:getValue() + 1) -- newValue will now be `2` and oldValue will be `1`
x:setValue(10) -- new: 10, old: 2
```

A side note on yielding from within the predicate function, this is technically safe although it will block neighboring threads from evaluating on time. This defeats the purpose of the design pattern so it is not reccomended that you do so.