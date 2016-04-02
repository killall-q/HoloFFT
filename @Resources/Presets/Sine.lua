local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local row = r / rows
local x = b / bands * 2 - 1
local y = (1 - row) * 2 - 1
local z = math.cos(row * 6.28 / v) * v * row^2
-- YOUR CODE HERE

return x, y, z
