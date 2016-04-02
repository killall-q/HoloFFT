local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local row = r / rows
local x = b / bands * 2 - 1
local y = 1 - row * 2
local z = row^1.5 * v - 0.5
-- YOUR CODE HERE

return x, y, z
