local Symbol = require(script.Parent.Symbol)

local ERR_NON_MEMBER = "%q is not a valid member of %s"
local ERR_CANNOT_WRITE = "Cannot write to %s"

local function makeEnum(name: string, values: { string })
	local enum = {
		Name = name,
	}

	local enumItems = {}
	for _, itemName in pairs(values) do
		enumItems[itemName] = Symbol.named(itemName)
	end

	local strict = {
		__index = function(_, index)
			if enumItems[index] then
				return enumItems[index]
			end

			error(string.format(ERR_NON_MEMBER, name), 2)
		end,
		__newindex = function()
			error(string.format(ERR_CANNOT_WRITE, name), 2)
		end,
		__tostring = function()
			return ("Enum(%s)"):format(name)
		end,
	}

	function enum:GetValues()
		return enumItems
	end

	return setmetatable(enum, strict)
end

return makeEnum
