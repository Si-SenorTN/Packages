# Config

## Usage
```lua
local Config = require(somewhere.Config)

local keybinds = Config.new({
	Reload = Enum.KeyCode.R
})

keybinds:Observe("Reload", function(newValue, trove)
	trove:BindAction("ReloadAction", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			print("Pressing Reload")
		end
	end, newValue)
end)

keybinds:SetKey("Reload", Enum.KeyCode.R) -- nothing happens

keybinds:SetKey("Reload", Enum.KeyCode.T) -- observed state reiterates, trove cleans and code runs back over

keybinds:SetKey("Reload", Config.DeleteToken) -- deletes the key, cleans the trove, does not reiterate observed state
```