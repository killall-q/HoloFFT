local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local x = b / bands * 2 - 1 - (b / bands - 0.5) * v * 0.4
local y = 1 - r / rows * 2
local z = 1 - math.cos((b / bands - 0.5) * 1.57) + v * 0.4
-- YOUR CODE HERE

return x, y, z
