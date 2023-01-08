# The ultimate State Management for StreamingEnabled

I hope.

# What is StreamingEnabled

In a direct quote from the [creator documentation](https://create.roblox.com/docs/optimization/content-streaming):

> In-experience content streaming allows the Roblox engine to dynamically load and unload 3D content and related instances in regions of the world. This can improve the overall player experience in several ways, for example:
> * Faster join times, as players can start playing in one part of the world while more of the world loads in the background.
> * Experiences can be played on devices with less memory since content is dynamically streamed in and out.
> * Distant terrain landmarks are visible through lower-detail meshes even before they are fully streamed in.

## The issue StreamingEnabled introduces

As we just learned, instances, specifically BasePart's, will be dynamically streaming in and out of the Workspace. This means we need to use things like `:WaitForChild` or `.ChildAdded` and `.DescendantAdded` alike. This is all fine until we have to manage visual state for these objects.

Now I am unsure if this is intended behavior, but if you attempt to change a visual property, **from the client,** such as `Transparency`, let the part stream out and back in again and the properties will be reset.

Now the solution to this is simple, just change it from the server. But this solution is not ideal in many cases, especially if it does not matter for something to change visually on the server, you would prefer just handling the visuals client sided.

**And even if this is not intended behavior,** it is still quite difficult to manage the state of an object that we know will exist, but might not at the moment due to it streaming out. We can cache a property table, but those have no convention and you'd still have to manually set the properties everytime it streams back in.

## The Proposed Solution

The streamable library will not only allow you to track a streaming parts existance, it will allow you to use state in a declarative way, much like how [Roact](https://github.com/Roblox/roact) handles Gui. Infact I've also created Bindings much similar to Roact that will allow for easy animation, or fast changing properties.

Lets take a look at a simple example. Here we are waiting on a model in the workspace that will have a child called "Part":

```lua
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Streamable = require(ReplicatedStorage.Packages.Streamable)

local model = Streamable.new(Workspace:WaitForChild("Model"))

local part = Model:Watch("Part")
```

The `Watch` method will look for children on that model by name, in the future I might add compatibility for things like class lookups, handling multiple of the same named children, but for now it'll track one instance.

The `Watch` method also takes a second argument, that being its initial state.
`State` is a table that represents **only** valid properties and their values respectively. This is where it starts to get more like Roact.

```lua
local model = Streamable.new(Workspace:WaitForChild("Model"))

local part = Model:Watch("Part", {
	Anchored = false,
	Position = Vector3.one,
})
```

If you're anticipating the pattern here the next method I'd like to highlight is `SetState`. `SetState` will accept one argument, that being either a partial state updater table, or a state updater function. Partial state table will reconcile with the current state and then update your instances properties to match that of the state tables. The functional version of `SetState` will give you the current state as a read only parameter, and will accept a partial state table as a return value, or nil if youd like to omit the update. The behavior to Roact is nearly identical.

```lua
part:SetState({
	Anchored = true
})

part:SetState(function(currentState)
	if currentState.Anchored then
		return {
			Anchored = false
		}
	else
		-- omit the update
		return nil
	end
end)
```

Bindings can also be used on the state table. We can create a binding like so

```lua
local binding = Streamable.createBinding(Vector3.zero)
```

Their values can be set, retrieved, subscribed to, and mapped.

```lua
binding:SetValue(Vector3.zero)

print(binding:GetValue()) --> 0, 0, 0

binding:Subscribe(function(value)
	print(value)
end)

local newBinding = binding:Map(function(value)
	return value * 2
end)
```

Mapping is most useful when used in a state update, lets take a look of an example of using a binding for setting state.

```lua
local model = Streamable.new(Workspace:WaitForChild("Model"))
local pos = Streamable.createBinding(0)

local part = Model:Watch("Part", {
	Anchored = true,
	Position = pos:Map(function(alpha)
		return (Vector3.zero):Lerp(Vector3.one, alpha)
	end),
})

pos:SetValue(0.5)
```

As soon as "Part" is streamed in, its position will be lerped halfway between origin and one stud on every axis, aka Vector3<0.5, 0.5, 0.5>.

Following in suit (once again) with Roact, state can accept a special `None` key to remove something from a state update. This can be used to wipe a primitive type from state or clear a binding. Do note that bindings operate on their own, in this way its a bit different from Roact. Setting its key to `None` in a state table does **not** mark the binding as unseable, it simply disconnects its subscription. Lets see how we can use the `None` key.

```lua
local pos = Streamable.createBinding(Vector3.zero)
part:SetState({
	Anchored = true,
	Position = pos
})

part:SetState({
	Position = Streamable.None
})
pos:SetValue(Vector3.one)
```

If part is not currently streamed in, this will cancel the state from setting it to `Vector3.one`, otherwise it will simply set to origin, but clear it from state afterwards so it does not update and persist on stream in/out. In the future I may dedcide to batch state changes and reconcile them all onto one state update at the end of each frame, but for now set state is immediate.

Streamable instances also come with a few utility methods, such as `GetState` and `Observe`.

```lua
local pos = Streamable.createBinding(Vector3.zero)

part:SetState({
	Anchored = true,
	Position = pos
})
print(part:GetState()) --> { Anchored = true, Position = 0, 0, 0 }

local connection = part:Observe(function(instance, trove)
	print(instance, "streamed in")
	trove:Add(function()
		print("streamed out")
	end)
end)
```

`GetState` provides a read-only, shallow copied snapshot of the parts current state. Bindings will represent the current value that they hold, and will not update until you call `GetState` again.

`Observe` provides the streamed in instance and a [trove](https://github.com/Sleitnick/RbxUtil/tree/main/modules/trove) by sleitnick. The trove auto cleans up when the instance streams out.

Last but not least, two ordinary keys `Instance` and `IsStreamed` which holds reference to the streaming instance and a boolean if it is currently streamed in or not.

## This library can be used for more than StreamingEnabled

This can be used for any instance of any name or type that youd need to wait on, or just want to use declarative state for.