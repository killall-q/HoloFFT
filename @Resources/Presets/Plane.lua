local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local x = b / bands * 2 - 1
local y = 1 - r / rows * 2
local z = v - 0.5
-- YOUR CODE HERE

return x, y, z
