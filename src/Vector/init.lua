local strict = require(script.Parent.strict)

return {
	["2D"] = strict({
		Zero = Vector3.new(),
		Up = Vector2.new(0, 1),
		Down = Vector2.new(0, -1),
		Left = Vector2.new(-1, 0),
		Right = Vector2.new(1, 0),
	}),
	["3D"] = strict({
		Zero = Vector3.new(),
		Up = Vector3.new(0, 1, 0),
		Down = Vector3.new(0, -1, 0),
		Left = Vector3.new(-1, 0, 0),
		Right = Vector3.new(1, 0, 0),
		Front = Vector3.new(0, 0, 1),
		Back = Vector3.new(0, 0, -1),
	}),

	Util = require(script.VectorUtil)
}