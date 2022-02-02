local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local curve = r / rows * 3.14
local v = math.sin(curve) * v * 1.8
local x = math.cos(theta) * math.sin(curve) * v
local y = math.sin(theta) * math.sin(curve) * v
local z = -math.cos(curve) * v
-- YOUR CODE HERE

return x, y, z
