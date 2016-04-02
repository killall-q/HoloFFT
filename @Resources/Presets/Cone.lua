local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local theta = b / bands * 6.28 + r * 0.02454
local curve = math.sin(r / rows * 1.57) * v * 2
local x = math.cos(theta) * curve
local y = math.sin(theta) * curve
local z = curve - 1
-- YOUR CODE HERE

return x, y, z
