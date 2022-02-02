local bands, b, rows, r, v, p = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local row = 1 - r / rows
local curve = row * 3.12 + 0.01
local v = 0.2 + ((1 - math.sin(row * 3.14)) * p^0.3 + math.sin(row * 3.14) * v) * 1.6
local x = math.cos(theta) * math.sin(curve) * v
local y = math.sin(theta) * math.sin(curve) * v
local z = math.cos(curve) * v
-- YOUR CODE HERE

return x, y, z
