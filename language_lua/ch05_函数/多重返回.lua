function foo0() end
function foo1() return 'a' end
function foo2() return 'a', 'b' end

x, y = foo2()
print(x, y)
x = foo2()
print(x)
x, y, z = 10, foo2()	-- 返回所有返回值
print(x, y, z)

print('---------------------------------------')
x, y = foo1()
print(x, y)
x, y, z = foo2()	-- 最后一个/唯一一个元素时，返回所有返回值
print(x, y, z)

print('---------------------------------------')
x, y = foo2(), 20	-- 注意此处foo2()只产生一个返回值
print(x, y)
x, y = foo0(), 20, 30	-- 此处产生一个返回值nil
print(x, y)		

print('--------------table----------------------')
t = {foo2()}
for k, v in ipairs(t) do
	print(t[k])
end

t = {3, foo1(), foo2(), 4}	-- 此处若加入foo0(), 则返回nil， 但是打印不出来，且会中断
for k, v in ipairs(t) do
	print(t[k])
end

print('--------------print----------------------')
print((foo2()))			-- 此处只返回一个参数
print(foo2())


print('--------------unpack----------------------')
print(unpack{10, 20, 30, 40})
