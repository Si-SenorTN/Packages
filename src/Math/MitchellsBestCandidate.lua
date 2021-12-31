local function MBC(numPoints: number, numCandidates: number, getRandomSample: () -> Vector3, onBestRecieve: (bestPosition: Vector3) -> nil)
	local values = { Vector3.new() }
	for i = 1, numPoints do
		local best = nil
		local bestDistance = -1
		for _ = 1, numCandidates do
			local val = getRandomSample()
			local distanceToClosestSqr = math.huge
			for k = 1, i - 1 do
				local pos = values[k]
				local distance = (val - pos).Magnitude
				if distance < distanceToClosestSqr then
					distanceToClosestSqr = distance
				end
			end
			if distanceToClosestSqr > bestDistance then
				bestDistance = distanceToClosestSqr
				best = val
			end
		end
		if onBestRecieve then
			onBestRecieve(best)
		end
		values[i] = best
	end
	return values
end

return MBC