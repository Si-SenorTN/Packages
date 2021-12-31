local function shallowGetDictionary(directory: Instance)
	local list = {}
	for _, module: ModuleScript in pairs(directory:GetChildren()) do
		if not module:IsA("ModuleScript") then
			continue
		end
		list[module.Name] = require(module)
	end
	return list
end

local function deepGetDictionary(directory: Instance)
	local list = {}
	for _, module: ModuleScript in pairs(directory:GetDescendants()) do
		if not module:IsA("ModuleScript") then
			continue
		end
		list[module.Name] = require(module)
	end
	return list
end

return {
	shallow = shallowGetDictionary,
	deep = deepGetDictionary
}