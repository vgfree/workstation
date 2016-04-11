function newCounter()
	local i = 0
	return function()
		i = i + 1
		return i
	end
end

c1 = newCounter()
print(c1())
print(c1())
print(c1())

c2 = newCounter()
print(c2())
print(c2())
print(c2())

-- 词法域：位于内部的函数可以访问外部函数中的局部变量
-- i 非局部变量
-- closure 一个函数加上该函数所需访问的所有非局部变量

print('--------------使用弧度替代角度--------------')
oldSin = math.sin
math.sin = function(x)
	return oldSin(x * math.pi / 180)
end

print(math.sin(30))

print('------------更彻底的做法--------------')
do
	local oldSin = math.sin
	local k = math.sin * 180
	math.sin = function(x)
		return oldSin(x * k)
	end
end

