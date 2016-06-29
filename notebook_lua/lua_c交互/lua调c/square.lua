
local power = require("power")

print(power.square)
print(power.square(1.414))
power.square = 1
print(power.square)
print(power.cube(5))
