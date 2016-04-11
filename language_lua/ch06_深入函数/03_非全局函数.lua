--------递归函数------------
print('----------------递归求阶乘--------------------')
--求阶乘的函数
do
local fact
fact = function (n)
	if n == 0 then return 1
	else return n * fact(n - 1)
	end
end

print(fact(3))

end

print('---------------另一种写法------------------')
do
local function foo (n)
	if n == 0 then return 1
	else return n * foo(n - 1)
	end
end

print(foo(3))
end

print('---------------间接递归------------------')
local f, g	-- 必须使用一个明确的前向声明

function g () 
--	<body>
	f ()	-- 有local 会创建一个全新的局部变量f,将原来声明中的f置于未定义状态
--	<body>
end

function f ()
	g ()
end

