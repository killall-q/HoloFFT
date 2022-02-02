local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local curve = math.sin(r / rows * 1.57) * v * 2.1
local x = math.cos(theta) * math.sin(curve) * 1.6
local y = math.sin(theta) * math.sin(curve) * 1.6
local z = -math.cos(curve) * 1.6
-- YOUR CODE HERE

return x, y, z
