type Table = { any }

local RANDOM = Random.new()

local function isEmpty(t: Table)
	return next(t) == nil
end

local function getn(t: Table)
	local count = 0
	for _ in pairs(t) do
		count += 1
	end
	return count
end

local function random(t: Table, rng: Random?)
	rng = RANDOM or rng
	return t[rng:NextInteger(1, #t)]
end

local function cyclical(t: Table, cache: Table?)
	local new = table.create(#t)
	cache = cache or {}
	cache[t] = true
	for k, v in pairs(t) do
		if typeof(v) == "table" then
			if not cache[v] then
				new[k] = cyclical(v, cache)
			else
				new[k] = "Cyclic Table: " .. tostring(v)
			end
		end
	end
	cache[t] = nil
	return new
end

local function copy(t: Table)
	local copiedTable = table.create(#t)
	for key, value in pairs(t) do
		copiedTable[key] = value
	end
	return copiedTable
end

local function deepCopy(t: Table)
	local function deep(tbl: Table, _cache: Table)
		_cache = _cache or {}
		if _cache[tbl] then
			return _cache[tbl]
		end

		if type(tbl) == "table" then
			local new = table.create(#tbl)
			_cache[tbl] = new
			for index, value in pairs(tbl) do
				new[deep(index, _cache)] = deep(value, _cache)
			end
			return setmetatable(new, deep(getmetatable(tbl), _cache))
		else
			return tbl
		end
	end

	return deep(t)
end

local function replace(t: Table, extension: Table)
	for key, value in pairs(extension) do
		t[key] = value
	end
	return t
end

local function extendArray(t: Table, extension: Table)
	for index, value in pairs(extension) do
		table.insert(t, index, value)
	end
	return t
end

local function merge(t0: Table, t1: Table)
	local tbl = copy(t0)
	for key, value in pairs(t1) do
		local currentIndex = tbl[key]
		if not currentIndex then
			if type(value) == "table" then
				tbl[key] = deepCopy(value)
			else
				tbl[key] = value
			end
		elseif type(currentIndex) == "table" then
			if type(value) == "table" then
				tbl[key] = merge(currentIndex, value)
			else
				tbl[key] = deepCopy(currentIndex)
			end
		end
	end
	return tbl
end

local function deepFreeze(t: Table)
	local function freeze(tbl: Table)
		if table.isfrozen(tbl) then
			return tbl
		end
		for _, v in pairs(tbl) do
			if type(v) == "table" then
				return freeze(v)
			end
		end
		return table.freeze(tbl)
	end
	return freeze(t)
end

local function filter(t: Table, predicate: (k: any, v: any) -> boolean)
	local tbl = table.create(#t)
	for key, value in pairs(t) do
		local result = predicate(key, value)
		if result then
			tbl[key] = value
		end
	end
	return tbl
end

local function map(t: Table, mapfunc: (k: any, v: any) -> any)
	local tbl = table.create(#t)
	for key, value in pairs(t) do
		tbl[key] = mapfunc(key, value)
	end
	return tbl
end

local function foreach(t: Table, callback: (key: any, value: any) -> nil)
	for i, v in ipairs(t) do
		callback(i, v)
	end
end

local function foreachi(t: Table, callback: (key: any) -> nil)
	for i in ipairs(t) do
		callback(i)
	end
end

local function foreachv(t: Table, callback: (value: any) -> nil)
	for _, v in ipairs(t) do
		callback(v)
	end
end

local function packSparse(...: any)
	return {
		n = select("#", ...),
		...,
	}
end

local tbl = {}
tbl.empty = isEmpty
tbl.count = getn
tbl.random = random
tbl.cyclical = cyclical
tbl.filter = filter
tbl.map = map
tbl.foreach = foreach
tbl.foreachi = foreachi
tbl.foreachv = foreachv

tbl.shallow = copy
tbl.deep = deepCopy
tbl.replace = replace
tbl.extend = extendArray
tbl.merge = merge

tbl.deepfreeze = deepFreeze
tbl.packsparse = packSparse

return tbl
