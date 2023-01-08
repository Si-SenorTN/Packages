local None = {}

setmetatable(None, {
	__tostring = "Symbol<None>",
})

return table.freeze(None)
