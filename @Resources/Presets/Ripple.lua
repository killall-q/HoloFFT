local bands, b, rows, r, v, p = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local row = 1 - r / rows
local x = math.cos(theta) * row * 1.7
local y = math.sin(theta) * row * 1.7
local z = (1 - row)^2 * ((1 - row) * p + row * v^2) * 2
-- YOUR CODE HERE

return x, y, z
