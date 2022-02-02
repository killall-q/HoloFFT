local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local row = r / rows
local x = math.cos(theta) * (1.01 - row) * v^0.5 * 1.8
local y = math.sin(theta) * (1.01 - row) * v^0.5 * 1.8
local z = math.sin(row * 3.14) * v^2 * 2 - 1
-- YOUR CODE HERE

return x, y, z
