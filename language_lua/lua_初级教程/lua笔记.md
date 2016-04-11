## 语法
*注释*     
```
--  单行注释  
--[[
    块注释
--]]
```

*变量*
```
lua 数字只有double型, 64bits

字符串
\a 响铃
\b 退格
\f 表单
\n 换行
\r 回车
\t 横向制表
\v 纵向制表
\\ 反斜杠
\" 双引号
\' 单引号
```
只有nil 和 flase 为假
"
全局变量与局部变量
theGlobalVar = 50   
local theLocalVar = "local variable"    // 关键字local
```

*控制语句*    
>while 循环
```javascript
sum = 0
num = 1
while num < 100 do
    sum = sum + num
    num = num + 1
end
print("sum =", sum)
```    

>if...else 分支   
```javascript
if age == 40 and sex == "Male" then
    print("男人四十一枝花")
elseif age > 60 and sex ~= "Female" then  // ~= 不等于
    print("old man whitout country")
elseif age < 20 then
    io.write("too young, too naive!\n")
else
    local age = io.read() // io.read   io.write
    print("You age is"..age) // .. 字符串拼接操作符
```
>for 循环
```javascript
// 从 1 加到 100
sum = 0
for i = 1, 100 do
    sum = sum + 1
end       
// 从 1 到 100 的奇数和
sum = 0
for i = 1, 100, 2 do
    sum = sum + i
end
// 从 1 到 100 的偶数和
sum = 0
for i = 100, 1, -2 do
    sum = sum + i
end
```
>until 循环
```javascript
sum = 2
repeat
    sum = sum^2  // 幂操作
    print(sum)
until sum > 1000
```
>递归
```javascript
function fib(n)
    if n < 2 then return 1 end
    return fib(n - 2) + fib(n - 1)
end
```
>闭包
```javascript
//exp 01
function newCounter()
    local i = 0
    return function()
        i = i + 1
        return i
    end
end
c1 = newCounter()
print(c1())   // --> 1
print(c1())   // --> 2         
//exp 02
function myPower(x)
    return function(y)
        return y^x
    end
end
power2 = myPower(2)
power3 = myPower(3)
print(power2(4))  // 4^2
print(power3(5))  // 5^3
```
>函数返回值
```javascript
//exp 01 一条语句赋多个值
name, age, bGay = "Louis", 25, false, "louis.tin@outlook.com" // 第四个值丢弃
//exp 02 多个返回值
function getUserInfo(id)
    print(id) // nil
    return "Louis", 25, false, "louis.tin@outlook.com"
end
name, age, bGay, email, website = getUserInfo() // website == nil
```
>局部函数
```javascript
function foo(x)
    return x^2
end
foo = function(x)
    return x^2
end
```
>Table
```javascript
//exp 01 定义table
louis = {name = "louis tin", age = 25, handsome = True}
//exp 02 CRUD操作
louis.email = "louis.tin@ourtlook.com"
local age = louis.age
louis.handsome = false
louis.name = nil
//exp 03 定义table  访问格式t[20]
t = {[20] = 100, ['name'] = "louis", [3.14] = "PI"}  
```
>数组
```javascript
//exp 01    
arr = {10, 20, 30, 40}    
//exp 02   等价于 exp 01    
arr = {[1] = 10, [2] = 20, [3] = 30, [4] = 40}     
//exp 03   调用格式 调用arr[1]    
arr = {"string", 100, "louis", function() print("louis") end}     
//exp 04   #arr arr的长度       
for i = 1, #arr do          
    print(arr[i])        
end     
//exp 05   全局变量放在名为"_G"的Table中     
_G.globalVar   // 访问全局变量 globalVar   
_G["globalVar"]   
//exp 06 遍历一个table   
for k, v in paris(t) do   
    print(k, v)   
end   
```
>MetaTable 元表(类似于C++重载)  MetaMethod 元方法    
```javascript  
fraction_a = {numerator = 2, denominator = 3}   
fraction_b = {numerator = 4, denominator = 7}   
fraction_op = {}   
function fraction_op.__add(f1, f2)   
    ret = {}   
    ret.numerator = f1.numerator * f2.denominator + f2.numerator * f1.denominator     
    ret.denominator = f1.denominator * f2.denominator    
    return ret    
end     
setmetatable(fraction_a, fraction_op) // 库函数
setmetatable(fraction_b, fraction_op)
fraction_s = fraction_a + fraction_b
```
>Lua MetaTable
```javascript
__add(a, b)                     对应表达式 a + b
__sub(a, b)                     对应表达式 a - b
__mul(a, b)                     对应表达式 a * b
__div(a, b)                     对应表达式 a / b
__mod(a, b)                     对应表达式 a % b
__pow(a, b)                     对应表达式 a ^ b
__unm(a)                        对应表达式 -a
__concat(a, b)                  对应表达式 a .. b
__len(a)                        对应表达式 #a
__eq(a, b)                      对应表达式 a == b
__lt(a, b)                      对应表达式 a < b
__le(a, b)                      对应表达式 a <= b
__index(a, b)                   对应表达式 a.b
__newindex(a, b, c)             对应表达式 a.b = c
__call(a, ...)                  对应表达式 a(...)
```
>面向对象     
```javascript
// __index 重载, 重载 find key 操作
//exp 01 将对象b 作为对象a 的prototype
setmetatable(a, {__index = b})
//exp 02
Window_Prototype = {x = 0, y = 0, width = 100, height = 100}
MyWin = {title = "Hello"}
setmetatable(MyWin, {__index = Window_Prototype})
print(MyWin.height)  // -->100
print(MyWin.title)   // -->Hello
//exp 03
Person = {}
function Person:new(p) // == Person.new(self, p), self 就是Person
    local obj = p
    if (obj == nil) then
        obj = {name = "louis", age = 25, handsome = true}
    end
    self.__index = self // 防止self被扩展后改写
    return setmetatable(obj, self) // 返回第一个参数的值
end
function Person:toString()
    return self.name..":"..self.age..":"..(self.handsome and "handsome" or "ugly")
end
me = Person:new()
print(me:toString()) // -->louis:25:handsome
kf = Person:new{name = "King's fucking", age = 70, handsome = false}
print(kf:toString()) // -->King s fucking:70:ugly
/**********************************我是分割线***************************************/
// 继承
Student = Person:new()
function Student:new()
    newObj = {year = 2013}
    self.__index = self
    return setmetatable(newObj, self)
end
function Student:toString()
    return "Student:"..self.year..":"..self.name
end
```
>模块  require("model_name")   model_name.lua
```javascript
// require() 只有第一次时执行
// dofile()  每次都执行
// loadfile() 载入后不执行, 需要时执行
local hello = loadfile("hello_lua")  // hello_lua.lua
...
hello() // 此时执行
// 标准玩法
// mymod.lua
local LouisModel = {}
local function getname()
    return "Louis Tin"
end
function LouisModel.Greeting()
    print("Hello, my name is"..getname())
end
return LouisModel
// 终端运行
local louis_model = require("mymod")
louis_model.Greeting()
```

1.1 程序块 chunk
run mode:
	$ lua -i prog.lua      运行后进入交互模式

	$ dofile("prog.lua")   方便调试

1.2 词法规范
string:
	combain : a~z, 0~9, _     
	warning: like 0xxx and _ABC are not available
annotation:
	--      行注释
	--[[
		块注释
	--]]

1.3 全局变量 global variables
未初始化全局变量值为 nil

1.4

Unit 2 类型与值
2.1
8 base type :
	nil   boolean   number   string   userdata   function   thread    table
2.3
boolean : flase true

2.4 string
string  : lua采用8位编码
	字符串为不可变值
	```
	a = "one thing"
	b = string.gsub(a, "one", "another")  
	print(a)   --> one thing
	print(b)   --> another thing
	```
转义序列
	```
	\a 响铃
	\b 退格
	\f 表单
	\n 换行
	\r 回车
	\t 横向制表
	\v 纵向制表
	\\ 反斜杠
	\" 双引号
	\' 单引号
	```"
	exp : alo\n123\  ==  \97lo\10\04923       \049 == 1 加0是防止读作\492
tonumber & tostring
	print("10" + 1)  --> 11
	print("10 + 1")  --> 10 + 1
	print(10 .. 20)  --> 1020        .. 两端有空格
	print(tostring(10) == "10")   --> true
	print(10 .. "" == "10")       --> true
	print(tonumber("10") == 10)   --> true
	print(tonumber("louis"))      --> nil  
# 长度操作符 获取字符串长度
	a = "hello"
	print(#a)           --> 5
	print(#"good\0bye") --> 8

2.5 table
table 是 Lua中唯一的数据结构 key-value
匿名的 anonymous 持有table的变量与table自身之间没有固定关系
	a = {}			-- 创建一个table, 并将它存储到a
	a["x"] = 10
	b = a			-- b 与 a 引用同一个 table
	print(b.y)    --> 10
	b.x = 20
	print(a.y)    --> 20    -- 语法糖 syntactic sugar  == a["y"]  ~=a[y]
	print(a.z)    --> nil

	warning: a.x == a["x"]    a[x] 中的 x 为变量
	a = {}
	x = "y"
	a[x] = 10
	print(a[x])    --> 10
	print(a.x)     --> nil  字段"x"未定义
	print(a.y)     --> 10

	Lua的索引起始值为 1

	table的大小
	a = {}
	a[100000] = 1
	print(table.maxn(a))   --> 100000

	i = 10, j = "10", k = "+10"
	a[i] ~= a[j] ~= a[k]
	a[i] == a[tonumber(j)] == a[tonumber(k)]

Unit 3 表达式
3.1 算数操作符
	+ - * / ^ %
	x = math.pi
	print(x - x%0.01)	--> 3.14     % 取模操作

3.2 关系操作符
	> < >= <= == ~=
	== ~= 任意值间比较
	对于table userdata 和 function 作引用比较，只有当引用同一个对象时， 才会认为相等.
	a = {}; a.x = 1; a.y = 0
	b = {}; b.x = 1; b.y = 0
	c = a
	--> a == c, a ~= b

3.3 逻辑操作符
and or not
and: 第一个操作数为假，返回第一个操作数，否则返回第二个操作数
or : 第一个操作数为真，返回第一个操作数，否则返回第二个操作数
not: 只返回 true false
	print(4 and 5)		--> 5
	print(nil and 13)	--> nil
	print(4 or 5)		--> 4
	print(false or 5)	--> 5
	print(not nil)		--> true
	print(not 0)		--> false
	print(not not nil)	--> false
	x = x or v <--> if not x then x = v end
	max = (x > y) and x or y      -- y 不为假

3.4 字符串链接
	print("hello " .. "world")	--> hello world
	print(1 .. 2)			--> 12           -- 数字也做为字符串来处理
	a = "hello"
	print(a .. "world")
	print(a)			--> hello        -- 连接不会对原操作数进行修改

3.5 优先级

3.6 table 构造式  table constructor
初始化数组:
	days = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}
	print(days[4])		--> Wed

	a = {x = 10, y = 20}	<--> a = {}; a.x = 10, a.y = 20

	w = {x = 0, y = 0, label = "console"}		-- 列表风格
	x = {math.sin(0), math.sin(1), math.sin(2)}	-- 记录风格
	w[1] = "another field"
	x.f = w
	print(w["x"])	--> 0			-- w["x"] <--> w.x
	print(w[1])	--> another field
	print(x.f[1])	--> another field
	w.x = nil				-- 删除字段"x"
	print(x[2])	--> 0.8414709848079	-- math.sin(1)

	polyline = {color = "blue", thickness = 2, npoints = 4;
		   {x = 0, y = 0},
		   {x = 10, y = 0},
		   {x = -10, y = 1},
		   {x = 0, y = 2}
		   }	-- 不允许负数索引，不能用运算符作为记录的字段名
	print(polyline[2].x)	--> -10
	print(polyline[4].y)	--> 2
	print(polyline[1])	--> table: 0x995a80
	print(polyline["color"]) --> blue
	print(polyline[color])  --> nil

	-- 通用语法， 以上两种均是此种的语法特例
	opnames = {["+"] = "add", ["-"] = "sub", ["*"] = "mul", ["/"] = "div",}
	i = 20; s = "-"
	a = {[i+0] = s, [i+1] = s .. s, [i+2] = s .. s .. s,} --最后的逗号，表明无需将最后一个元素作特殊处理
	print(opnames[s])	--> sub
	print(a[22])		--> ---

Unit 4 语句
4.1 赋值
	a, b, c = 10, 2*x		-- 多重赋值，且右边计算完毕后再赋值 c == nil
	a, b = 0, 1, 2			-- 2 被丢弃

4.2 局部变量与块 block
局部变量   local   作用域仅限于声明的块
全局变量
	local a, b = 1, 10
	if a < b then
		print(a)	--> 1
		local a		-- 隐式 = nil
		print(a)	--> nil
	end
	print(a, b)		--> 1 10

	local foo = foo		创建局部变量foo, 并将用全局变量foo的值初始化之

4.3 控制结构
if then else:
	if op == "+" then
		r = a + b
	elseif op == "-" then
		r = a - b
	else
		error("invalid operation")
	end
while:
	local i = 1
	while a[i] do
		print(a[i])
		i = i + 1
	end
repeat:
	local sqr = x/2
	repeat
		sqr = (sqr + x/sqr) / 2
		local error = math.abs(sqr^2 - x)
	until error < x / 10000	-- 此处仍可访问error
for:
	循环变量是循环体的局部变量
	绝不应该对循环变量进行任何赋值
  numeric for
	local found = nil
	for i = 1, #a, 1 do		-- math.huge 不设循环上限，步长默认为1
		if a[i] < 0 then
			found = i	-- 包含i的值
			break
		end
	end
	print(found)
	print(i)			--> nil  -- 控制变量自动声明为for的局部变量
  generic for
	泛型for循环通过一个迭代器(iterator)函数来遍历所有值
	io.lines		-- 迭代文件中的每行
	pairs			-- 迭代table元素
	ipairs			-- 迭代数组元素
	string.gmatch		-- 迭代字符中单词

	days = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}
	revDays = {"Sun" = 1, "Mon" = 2,
		   "Tue" = 3, "Wed" = 4,
		   "Thu" = 5, "Fri" = 6,
		   "Sat" = 7}

	revDays = {}
	for k, v in pairs(days) do	-- 每次循环中k会被赋序列号，v被赋value
		revDays[v] = k
	end
break return
	跳出当前的块
	break 跳出所包含的内部循环，跳出后循环继续执行
	return 从一个函数中返回结果，或简单的结束一个函数的执行
	break return 为一个块的最后一句，或end else until之前的一条语句

	function foo ()
		return		-- error
		do return end	-- OK 调试时，可以不执行以下的函数内容
		...
	end

Unit 5 函数
	函数只有一个实参，且此参数是一个字面字符串或table构造式，可以不加括号
		dofile "a.lua"  <--> dofile("a.lua")
	实参多于形参，舍弃多余实参；实参少于形参，多余形参初始化为nil
5.1 多重返回值
	-- 查找数组中的最大元素
	function maximum (a)
	local mi = 1			-- 最大值索引
	mocal m = a[mi]			-- 最大值
	for i, val in ipairs(a) do
		if val > m then
			mi = i; m = val
		end
	end
	return m, mi
	end
	print(maximum({8, 10, 23, 12, 5}))	--> 23 3
将函数调用作为一条单独语句时，会丢弃函数的所有返回值；将函数作为表达式的一部分来调用时，只保留第一个返回值；
	作为一系列表达式（多重赋值，函数传入的实参列表，table构造式，return语句）中最后一个元素（或唯一元素）时，
	获得所有返回值
	function foo0 () end			-- 无返回值
	function foo1 () return "a" end		-- 返回值为"a"
	function foo2 () return "a", "b" end	-- 返回值为"a" "b"
	x, y = foo2 ()				-- x = "a", y = "b"
	x = foo2 ()				-- x = "a", "b"丢弃
	x, y, z = 10, foo2 ()			-- x = 10, y = "a", z = "b"
	x, y = foo2 (), 20			-- x = "a", y = 20
        x, y = foo0 (), 20, 30			-- x = nil, y = 20, 30 丢弃
	print(foo2 ())				--> a b
	print(foo2 (), 1)			--> a, 1
	print(foo2 () .. "x")			--> ax
	t = {foo2 ()}				-- t = {"a", "b"}
	t = {foo0 (), foo2 (), 4}		-- t[1] = nil, t[2] = "a", t[3] = 4
	return foo2 ()				-- a, b
	return (foo2 ())			-- a

	f = string.find
	a = {"hello", "ll"}
	f(unpack(a))		-- 3, 4   unpack: 从下标1开始返回该数组所有元素

5.2 变长参数 variable number of arguments
	function add (...)
	local s = 0
		for i, v in ipairs(...) do	-- 表达式{...}表示一个由所有变长参数构成的数组
			s = s + v
		end
	return s
	end
	print(add(3, 4, 10, 25, 12))		--> 54

	function fwrite (fmt, ...)		 -- 固定参数fmt, 变长参数 ...
	return io.write(string.format(fmt, ...)) -- string.format 格式化文本，io.write 输出文本
	end

	fwrite()			-- fmt = nil, 无变长参数
	fwrite("a")			-- fmt = "a", 无变长参数
	fwrite("%d%d", 4, 5)		-- fmt = "%d%d", 变长参数4, 5

	变长参数中包含nil时
	for i = 1, select('#', ...) do  -- 返回变长参数的总数， 包括nil
	local arg = select (i, ...)	-- 得到第i个参数
		循环体
	end

5.3 具名实参 named arguments	--此处存疑
	Lua中参数的传递具有"位置性"

Unit 6 深入函数
匿名函数：function (x) <body> end 函数构造式的结果
	network = {
		{name = "louis", age = 25},
		{name = "miku", age = 16},
		{name = "shana", age = 13},
		{name = "yika", age = 9},
		}
	table.sort(network, function (a, b) return (a.name > b.name) end)   --> 以name字段反向字母顺序对table排序
	-- table.sort(table, 函数构造式) 具体排序准则由构造式定义

	function derivative (f, delta)		-- 计算导数
		delta = delta or 1e-4
		return function (x)
			return (f(x + delta) - f(x)) / delta
			end
		end
	c = derivative(math.sin)
	print(math.cos(10), c(10))		--> -0.83907152907645  -0.839011213124456  --两个结果相等

6.1 闭合函数 closure
	-- 根据学生年级来对他们的姓名进行排序
	names = {"miku", "louis", "shana"}
	grades = {louis = 10, miku = 9, shana = 7}
	function sortbygrade (names, grades)		-- grades 为函数 sortbygrade 的局部变量
		table.sort(names, function(n1, n2))	-- 匿名函数
			return grades[n1] > grades[n2]	-- grades 非局部变量 non-local variable
		end
	end
closure: 一个函数 + 所需访问的所有"非局部变量"
	function newCounter ()
	local i = 0
	return function ()
		i = i + 1
		return i
		end
	end
	c1 = newCounter ()	-- 创建一个closure
	print(c1())		--> 1
	print(c1())		--> 2
	c2 = newCounter ()	-- 每次调用都会创建一个新的closure
	print(c2())		--> 1
	print(c1())		--> 3

	-- 沙盒 sandbox 函数
	do
	local oldOpen = io.open
	local access_OK = function (filename, mode)
		<检查访问权限>
		end
	io.open = function (filename, mode)
		if access_OK (filename, mode) then
			return oldOpen (filename, mode)
		else
			return nil, "access denied"
		end
		end
	end

6.2 非全局函数 non-local function (在程序块中声明的函数，只在该程序块中可见)
将函数存储在table中
	Lib = {}
	Lib.foo = function (x, y) return x + y end

	Lib = {
		foo = function (x, y) return x + y end
	}

	Lib = {}
	function Lib.foo (x, y) return x + y end
局部函数 local function 将一个函数存储到局部变量中
def1:	local f = function(参数)
		函数体
	end
	local g = function(参数)
		...
	f ()			-- 在一个chunk中声明的函数，在该chunk中可见
		...
	end
def2:	local function f (参数) 函数体 end
def3:	local fact		-- 先定义好局部变量fact，防止下文递归调用时局部fact未定义完毕
	fact = function (n)
		if n == 0 then return 1
		else return n*fact(n - 1)	-- 没有先定义的话，调用的就会是全局的fact
	end
	end

6.3 正确的尾调用 proper tail call 当一个函数调用是另一个函数的最后一个动作时
形式：return <func>(<args>)		-- 在调用前对<func>及其参数求值
不耗费栈空间，类似于goto语句
	-- 迷宫游戏 一个函数表示一个状态(房间)
	function room1 ()
		local move = io.read ()
		if move == "south" then return room3 ()
		elseif move == "east" then return room2 ()
		else
		print ("invalid move")
		return room1 ()
		end
	end
	function room2 ()
		local move = io.read ()
		if move == "south" then return room4 ()
		elseif move == "east" then return room1 ()
		else
		print ("invalid move")
		return room2 ()
		end
	end
	function room3 ()
		local move = io.read ()
		if move == "north" then return room1 ()
		elseif move == "east" then return room4 ()
		else
		print ("invalid move")
		return room3 ()
		end
	end
	function room4 ()
		print ("congratulations!")
	end
	room1 ()

Unit 7 迭代器Iterator与泛型for
7.1 Iterator与closure
一个closure结构涉及两个函数:closure本身和factory函数(创建closure)
	function values (t)		-- 迭代器 返回元素的值
		local i = 0
		return function ()
			i = i + 1
			return t[i]
		end
	end
	t={10, 20, 30}
	for element in values (t)	-- 调用迭代器，泛型for为一次迭代循环作了所有薄记工作
	do
		print (element)
	end

7.2 泛型for的语义
泛型for在循环过程内部保存了迭代器函数
泛型for语法
	for <var-list> in <exp-list> do		-- var-list 变量列表 exp-list 表达式列表(一个或多个)
		<body>
	end

	for k, v in paris(t) do print (k, v) end

	for line in io.line () do
		io.write (line, "\n")
	end
变量列表第一元素称为-控制变量，为nil时循环结束
exp-list返回三个值供for保存：迭代器函数f、恒定状态s、控制变量的初值a0
	for var_1, ..., var_n in <explist> do <block> end
	等价于
	do
		local _f, _s, _var = <explist>
		while true do
			local var_1,, ..., var_n = _f(_s, _var)
			_var = _var1
			if _var == nil then break end
			<block>
		end
	end

7.3 无状态的迭代器
指的是自身不保存任何状态的迭代器，在每次迭代中，for循环都会用恒定状态和控制变量来调用迭代其函数，一个无状态的
迭代器可以根据这两个值为下一次迭代生产下一个元素
	a = {"one", "two", "three"}
	b = {[2] = "four", [3] = "five", [4] = "six"}
	for i, v in ipairs (a) do
		print(i,v)
	end
	for i, v in ipairs (b) do
		print(i,v)
	end
	--> 1  one
	--> 2  two
	--> 3  three
	-- b 没有打印，因为key = 1时，value为nil，直接跳出循环

7.4 具有复杂状态的迭代器


Unit 8 编译、执行与错误
8.1 编译

8.2 C 代码
package.;oadlib
	local path = "/usr/local/lib/lua/5.1/socket.so"
	local f = package.loadlib(path, "luaopen_socket")

Unit 9 协同程序 coroutine
协同程序，是一条执行序列，拥有自己的独立的栈、局部变量和指令指针，同时又与其他协同程序共享全局变量和其他大部分东西。
一个具有多个协同程序的的程序在任一时刻只能运行一个协同程序，并且正在运行的协同程序只会在其显式的要求挂起(suspend)时,
他的执行才会暂停。
9.1 协同程序基础 coroutine
	-- coroutine.create(匿名函数)
	co = coroutine.create(function () print ("hi") end)
	print(co)	--> thread: 0x8071d98 表示新的协同程序
协同程序四种状态：挂起 suspended (创建时为此状态)(coroutine.yield)
		  运行 running (coroutine.resume)
		  死亡 dead
		  正常 normal (协同程序A 唤醒协同程序B 后A 的状态)
coroutine.create() -- 创建coroutine
coroutine.resume() -- 给协同程序传参数，并将挂起状态程序恢复为运行态
coroutine.yield()  -- 挂起coroutine
coroutine.status() -- 查看状态
coroutine.wrap()   -- 创建coroutine,并返回一个函数，一旦调用这个函数，就进入coroutine,和create功能重复
coroutine.running()-- 返回正在运行的coroutine，当使用running时,就返回一个corouting线程号

检查协同状态函数：print(coroutine.status(co))	--> suspended
corotinue.resume(): 给协同程序传参数，并将挂起状态程序恢复为运行态    
	coroutine.resume(co)		--> hi  运行后处于死亡状态
	      print(coroutine.status(co))	--> dead
挂起函数 corotinue.yield:
	co = coroutine.create(function ()
		for i = 1, 10 do
			print("co", i)
			coroutine.yield()
		end
	end)
	coroutine.resume(co)		--> co 1
	print(coroutine.status(co))	--> suspended
	coroutine.resume(co)            --> co 2
	...
	coroutine.resume(co)            --> co 10
	print(coroutine.resume(co))     --> false cannot resume dead coroutine








### Unit 24 C API 概述
Lua和C的通信是通过虚拟栈.
