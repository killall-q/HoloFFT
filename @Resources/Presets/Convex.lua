local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local x = b / bands * 2 - 1
local y = 1 - r / rows * 2 + (1 - r / rows - 0.5) * v * 0.4
local z = math.cos((r / rows - 0.5) * 1.57) + v * 0.4 - 1
-- YOUR CODE HERE

return x, y, z
