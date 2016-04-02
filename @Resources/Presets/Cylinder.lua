local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local v = 0.2 + v * 0.8
local x = math.cos(theta) * v * 1.7
local y = math.sin(theta) * v * 1.7
local z = r / rows - 0.5
-- YOUR CODE HERE

return x, y, z
