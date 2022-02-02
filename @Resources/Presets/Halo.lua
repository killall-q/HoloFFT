local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local curve = (1 - r / rows) / v * 6
local x = math.cos(theta) * (math.sin(curve) * v^2 * 0.1 + 1.6)
local y = math.sin(theta) * (math.sin(curve) * v^2 * 0.1 + 1.6)
local z = math.cos(curve) * v^2 * 0.4
-- YOUR CODE HERE

return x, y, z
