local type = type

local Vector3 = {}

local Vector3MT
Vector3MT = {
	__index = Vector3,
	__add = function(self, other)
		return Vector3.new(self.X + other.X, self.Y + other.Y, self.Z + other.Z)
	end,
	__mul = function(self, other)
		if type(other) == "table" then
			return Vector3.new(self.X * other.X, self.Y * other.Y, self.Z * other.Z)
		else
			return Vector3.new(self.X * other, self.Y * other, self.Z * other)
		end
	end,
	__sub = function(self, other)
		return Vector3.new(self.X - other.X, self.Y - other.Y, self.Z - other.Z)
	end,
	__div = function(self, other)
		if type(other) == "table" then
			return Vector3.new(self.X / other.X, self.Y / other.Y, self.Z / other.Z)
		else
			return Vector3.new(self.X / other, self.Y / other, self.Z / other)
		end
	end,
	__idiv = function(self, other)
		if type(other) == "table" then
			return Vector3.new(math.floor(self.X / other.X), math.floor(self.Y / other.Y), math.floor(self.Z / other.Z))
		else
			return Vector3.new(math.floor(self.X / other), math.floor(self.Y / other), math.floor(self.Z / other))
		end
	end,
	__mod = function(self, other)
		return Vector3.new(self.X % other.X, self.Y % other.Y, self.Z % other.Z)
	end,
	__pow = function(self, other)
		return Vector3.new(self.X ^ other.X, self.Y ^ other.Y, self.Z ^ other.Z)
	end,
	__tostring = function(self)
		return string.format("Vector3(%f, %f, %f)", self.X, self.Y, self.Z)
	end,
	__eq = function(self, other)
		return self.X == other.X and self.Y == other.Y and self.Z == other.Z
	end,
}

function Vector3:Abs()
	return Vector3.new(math.abs(self.X), math.abs(self.Y), math.abs(self.Z))
end

function Vector3:Cross(other)
	return Vector3.new(
		self.Y * other.Z - self.Z * other.Y,
		self.Z * other.X - self.X * other.Z,
		self.X * other.Y - self.Y * other.X
	)
end

function Vector3:Dot(other)
	return self.X * other.X + self.Y * other.Y + self.Z * other.Z
end

function Vector3:FuzzyEq(other, epsilon)
	return math.abs(self.X - other.X) < epsilon
		and math.abs(self.Y - other.Y) < epsilon
		and math.abs(self.Z - other.Z) < epsilon
end

function Vector3:Lerp(other, alpha)
	return Vector3.new(
		self.X + (other.X - self.X) * alpha,
		self.Y + (other.Y - self.Y) * alpha,
		self.Z + (other.Z - self.Z) * alpha
	)
end

function Vector3:Max(other)
	return Vector3.new(math.max(self.X, other.X), math.max(self.Y, other.Y), math.max(self.Z, other.Z))
end

function Vector3:Min(other)
	return Vector3.new(math.min(self.X, other.X), math.min(self.Y, other.Y), math.min(self.Z, other.Z))
end

function Vector3:Magnitude()
	return math.sqrt(self.X * self.X + self.Y * self.Y + self.Z * self.Z)
end

function Vector3:Normalize()
	local magnitude = self:Magnitude()
	return Vector3.new(self.X / magnitude, self.Y / magnitude, self.Z / magnitude)
end

function Vector3.new(x, y, z)
	local self = setmetatable({}, Vector3MT)
	self.X = x
	self.Y = y
	self.Z = z
	setmetatable(self, Vector3MT)
	return self
end

return Vector3
