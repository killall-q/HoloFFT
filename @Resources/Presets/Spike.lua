local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local row = r / rows
local x = math.cos(theta) * (1.01 - row) * 1.7
local y = math.sin(theta) * (1.01 - row) * 1.7
local z = row^2 * 1.7 * v
-- YOUR CODE HERE

return x, y, z
