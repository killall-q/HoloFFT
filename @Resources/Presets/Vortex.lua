local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local row = r / rows
local theta = b / bands * 6.28 + r * 0.02454 - (1 - row)^2 * v * 4
local curve = math.sin(row * 1.57)
local x = math.cos(theta) * curve^2 * v * 2
local y = math.sin(theta) * curve^2 * v * 2
local z = curve * v^0.3 * 2 - 1.4
-- YOUR CODE HERE

return x, y, z
