
local tab = {}

tab.one = "1"
tab.two = "2"
tab.three = "3"
tab.four = "4"

for k, v in pairs(tab) do 
	print(v)
end


-------------------------------------
local a = 10

local b = tonumber(a) or 1

print(b)
