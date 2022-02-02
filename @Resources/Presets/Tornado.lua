local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local row = 1 - r / rows
local theta = b / bands * 6.28 + r * 0.02454 + (1 - row) * v^2 * 4
local x = math.cos(theta) * (row^2 * (v + 1) + v * 0.1)
local y = math.sin(theta) * (row^2 * (v + 1) + v * 0.1)
local z = row * v * 3 - 1.4
-- YOUR CODE HERE

return x, y, z
