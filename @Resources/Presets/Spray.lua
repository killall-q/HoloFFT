local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local row = r / rows
local x = b / bands * 2 + v % 0.04 - 1
local y = (1 - row) * v * 2 - 1
local z = math.sin(row * 3.14) * v * 2 - 1
-- YOUR CODE HERE

return x, y, z
