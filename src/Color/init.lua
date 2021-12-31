--!strict
local Math = require(script.Parent.Math)

local MAX_COLOR_WHEEL_POSITION = 255

local Color = {}

function Color.toRGB(color3: Color3)
	return Color3.fromRGB(color3.R * 255, color3.G * 255, color3.B * 255)
end

function Color.toColor3(rgb: Color3)
	return Color3.new(rgb.R / 255, rgb.G / 255, rgb.B / 255)
end

function Color.fromHex(decimal)
	local red = bit32.band(bit32.rshift(decimal, 16), 2^8 - 1)
	local green = bit32.band(bit32.rshift(decimal, 8), 2^8 - 1)
	local blue = bit32.band(decimal, 2^8 - 1)

	return Color3.fromRGB(red, green, blue)
end

function Color.equals(c0: Color3, c1: Color3, epsilon: number)
	epsilon = epsilon or 1E-3

	if math.abs(c0.R - c1.R) > epsilon then
		return false
	end

	if math.abs(c0.G - c1.G) > epsilon then
		return false
	end

	if math.abs(c0.B - c1.B) > epsilon then
		return false
	end

	return true
end

function Color.complementary(c: Color3)
	local h, s, v = c:ToHSV()
	local h1 = Math.Util.inverse(h, 0, MAX_COLOR_WHEEL_POSITION)

	return Color3.fromHSV(h1, s, v)
end

function Color.monochromatic(c: Color3, amount: number, factor: number)
	factor = factor or 2
	amount = amount or 1

	local h, s, v = c:ToHSV()
	local function getV(val: number)
		return math.max(0, val - (.05 * factor))
	end

	if amount > 1 then
		local colors: { Color3 } = {}
		for _ = 1, amount do
			v = getV(v)
			local newColor = Color3.fromHSV(h, s, v)

			table.insert(colors, newColor)
		end

		return colors
	else
		v = getV(v)
		return Color3.fromHSV(h, s, v)
	end
end

function Color.analogous(c: Color3)
	local colors = {}
	local h, s, v = c:ToHSV()

	for _ = 1, 3 do
		h = math.min(MAX_COLOR_WHEEL_POSITION, (h + 30))
		table.insert(colors, Color3.fromHSV(h, s, v))
	end

	return colors
end

return Color