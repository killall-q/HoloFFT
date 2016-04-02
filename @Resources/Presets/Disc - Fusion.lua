local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local curve = 1 - math.cos(r / rows * 1.57)
local x = math.cos(theta) * curve * 1.5
local y = math.sin(theta) * curve * 1.5
local z = curve^2 * v * 1.2 - 0.6
-- YOUR CODE HERE

return x, y, z
