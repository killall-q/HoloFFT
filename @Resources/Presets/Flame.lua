local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local row = 1 - r / rows
local curve = row^0.5 - math.sin(row) * 1.18
local x = math.cos(theta) * curve * v * 4
local y = math.sin(theta) * curve * v * 4
local z = math.asin(row) * v * 4 - 1.7
-- YOUR CODE HERE

return x, y, z
