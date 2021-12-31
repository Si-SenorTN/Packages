local function errorOnBadIndex(_, index)
	error(string.format("Bad index %q, this table is strict", index), 2)
end

local function strict(object)
	setmetatable(object, {
		__index = errorOnBadIndex,
		__newindex = errorOnBadIndex
	})
	return object
end

return strict