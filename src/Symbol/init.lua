local Symbol = {}

function Symbol.named(name): NamedSymbol
	local self = newproxy(true)

	getmetatable(self).__tostring = function()
		return ("Symbol(%s)"):format(name)
	end

	return self
end

function Symbol.unnamed(): UnnamedSymbol
	return Symbol.named("Unnamed")
end

export type NamedSymbol = typeof(Symbol.named("__test__"))
export type UnnamedSymbol = typeof(Symbol.unnamed())

return setmetatable(Symbol, {
	__call = function(_, name)
		if name then
			return Symbol.named(name)
		else
			return Symbol.unnamed()
		end
	end,
})
