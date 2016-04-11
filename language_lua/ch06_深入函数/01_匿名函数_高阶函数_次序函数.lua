-- 函数名即为持有某函数的变量

a = {p = print}
a.p("hello world")

print('---------------------------')
function foo(x)	return 2 * x end
-- 等价于 foo = function(x) return 2 * x end
-- foo 匿名函数

print('---------------------------')
local score = {
	{name = 'miku', math = 80},
	{name = 'shana', math = 98},
	{name = 'asuka', math = 100}
}

-- 正常的sort怎么用没写成功
--[[
table.sort(score)
for k,v in pairs(score) do
	print(v.name)
end
--]]

-- sort 即为高阶函数
table.sort(score, function(a, b) return(a.math > b.math) end)

for k,v in pairs(score) do
	print(v.name, v.math)
end

print('---------------------------')
-- 导数函数
function derivative (f, delta)
	delta = delta or 1e-4
	return function (x)
		return ((f(x + delta) - f(x)) / delta)
	end
end
-- 此处，cos为sin的导数，那么利用以下函数计算出来的值大小应该很接近
c = derivative(math.sin)
print(math.cos(10), c(10))
