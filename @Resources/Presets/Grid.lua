local bands, b, rows, r, v = ...

-- YOUR CODE HERE
local br = math.floor(bands^0.5)
local x = math.floor(b / bands * br) / br * 2 + v % 0.1 - 1
local y = (b % br) / br * 2 + v % 0.08 - 1
local z = math.sin(r / rows * 3.14) * v * 2 - 1
-- YOUR CODE HERE

return x, y, z
