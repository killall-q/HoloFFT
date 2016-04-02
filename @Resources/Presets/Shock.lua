local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local curve = math.sin(r / rows * 1.57)
local v = 0.4 + v * 1.6
local x = math.cos(theta) * (1 - curve)^0.5 * v
local y = math.sin(theta) * (1 - curve)^0.5 * v
local z = curve * 1.6 - 0.8
-- YOUR CODE HERE

return x, y, z
