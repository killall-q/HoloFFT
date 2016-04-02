local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local x = math.cos(theta) * 1.4
local y = math.sin(theta) * 1.4
local z = (1 - math.cos(r / rows * 3.14)) * v - 1
-- YOUR CODE HERE

return x, y, z
