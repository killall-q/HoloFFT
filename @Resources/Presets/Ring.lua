local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local curve = (1 - math.cos(r / rows * 1.57)) * 0.5 * v + 1.2
local x = math.cos(theta) * curve
local y = math.sin(theta) * curve
local z = 0
-- YOUR CODE HERE

return x, y, z
