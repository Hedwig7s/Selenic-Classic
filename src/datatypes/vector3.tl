--local require = require("customrequire")

local record Vector3
    __index: Vector3
    __add: function(self:Vector3, other:Vector3): Vector3
    __mul: function(self:Vector3, other:Vector3|number): Vector3
    __sub: function(self:Vector3, other:Vector3): Vector3
    __div: function(self:Vector3, other:Vector3|number): Vector3
    __idiv: function(self:Vector3, other:Vector3|number): Vector3
    __mod: function(self:Vector3, other:Vector3): Vector3
    __pow: function(self:Vector3, other:Vector3): Vector3
    __tostring: function(self:Vector3): string
    __eq: function(self:Vector3, other:Vector3): boolean
    X: number
    Y: number
    Z: number
    zero: Vector3
    one: Vector3
    xAxis: Vector3
    yAxis: Vector3
    zAxis: Vector3
    Magnitude: number
    Unit: Vector3
    new: function(x:number, y:number, z:number, skipUnit:boolean): Vector3
end
Vector3.__index = Vector3
Vector3.__add = function(self:Vector3, other:Vector3): Vector3
    return Vector3.new(self.X + other.X, self.Y + other.Y, self.Z + other.Z)
end
Vector3.__mul = function(self:Vector3, other:Vector3|number): Vector3
    if other is Vector3 then
        return Vector3.new(self.X * other.X, self.Y * other.Y, self.Z * other.Z)
    else
        return Vector3.new(self.X * other, self.Y * other, self.Z * other)
    end
end
Vector3.__sub = function(self:Vector3, other:Vector3): Vector3
    return Vector3.new(self.X - other.X, self.Y - other.Y, self.Z - other.Z)
end
Vector3.__div = function(self:Vector3, other:Vector3|number): Vector3
    if other is Vector3 then
        return Vector3.new(self.X / other.X, self.Y / other.Y, self.Z / other.Z)
    else
        return Vector3.new(self.X / other, self.Y / other, self.Z / other)
    end
end
Vector3.__idiv = function(self:Vector3, other:Vector3|number): Vector3
    if other is Vector3 then
        return Vector3.new(self.X // other.X, self.Y // other.Y, self.Z // other.Z)
    else
        return Vector3.new(self.X // other, self.Y // other, self.Z // other)
    end
end
Vector3.__mod = function(self:Vector3, other:Vector3): Vector3
    return Vector3.new(self.X % other.X, self.Y % other.Y, self.Z % other.Z)
end
Vector3.__pow = function(self:Vector3, other:Vector3): Vector3
    return Vector3.new(self.X ^ other.X, self.Y ^ other.Y, self.Z ^ other.Z)
end
Vector3.__tostring = function(self:Vector3): string
    return string.format("%d, %d, %d", self.X, self.Y, self.Z)
end
Vector3.__eq = function(self:Vector3, other:Vector3): boolean
    return self.X == other.X and self.Y == other.Y and self.Z == other.Z
end

function Vector3:Abs(): Vector3
    return Vector3.new(math.abs(self.X), math.abs(self.Y), math.abs(self.Z))
end

function Vector3:Cross(other:Vector3): Vector3
    return Vector3.new(self.Y*other.Z - self.Z*other.Y, self.Z*other.X - self.X*other.Z, self.X*other.Y - self.Y*other.X)
end

function Vector3:Dot(other:Vector3): number
    return self.X*other.X + self.Y*other.Y + self.Z*other.Z
end

function Vector3:FuzzyEq(other:Vector3, epsilon:number): boolean
    return math.abs(self.X - other.X) < epsilon and math.abs(self.Y - other.Y) < epsilon and math.abs(self.Z - other.Z) < epsilon
end

function Vector3:Lerp(other:Vector3, alpha:number): Vector3
    return Vector3.new(self.X + (other.X - self.X) * alpha, self.Y + (other.Y - self.Y) * alpha, self.Z + (other.Z - self.Z) * alpha)
end

function Vector3:Max(other:Vector3): Vector3
    return Vector3.new(math.max(self.X, other.X), math.max(self.Y, other.Y), math.max(self.Z, other.Z))
end

function Vector3:Min(other:Vector3): Vector3
    return Vector3.new(math.min(self.X, other.X), math.min(self.Y, other.Y), math.min(self.Z, other.Z))
end

function Vector3.new(x:number, y:number, z:number, skipUnit: boolean): Vector3
    local self:Vector3 = {}
    self.X = x
    self.Y = y
    self.Z = z
    self.Magnitude = math.sqrt(x*x + y*y + z*z)
    if not skipUnit then
        self.Unit = Vector3.new(x/self.Magnitude, y/self.Magnitude, z/self.Magnitude, true)
    end
    setmetatable(self, Vector3)
    return self
end


return Vector3