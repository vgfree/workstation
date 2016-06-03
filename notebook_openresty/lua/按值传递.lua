local function swap(a, b)
	local temp = a
	a = b
	b = temp
	print(a, b)
end

local x = 'hello'
local y = 20

print(x, y)
swap(x, y)
print(x, y)
