local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local curve = 1 - math.sin(r / rows * 1.57)
local v = v * 1.5
local x = math.cos(theta) * curve^0.5 * v
local y = math.sin(theta) * curve^0.5 * v
local z = curve * v^3 * 2 - 1.4
-- YOUR CODE HERE

return x, y, z
