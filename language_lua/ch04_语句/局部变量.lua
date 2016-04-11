i = 10
local j = 20

if j > 10 then
	local k = 100
	print(k)
	print(j)
	local i = 1	--局部变量
	local j = 2	-- 局部变量
end

print(k)
print(i)
print(j)

