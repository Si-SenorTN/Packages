local Symbol = {}

function Symbol.named(name): Symbol
	local self = newproxy(true)

	getmetatable(self).__tostring = function()
		return ("Symbol(%s)"):format(name)
	end

	return self
end

export type Symbol = typeof(Symbol.named("__test__"))

return Symbol