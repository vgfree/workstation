a = {}
k = 'x'
a[k] = 10
a[20] = 'great'

print(a['x'])

k = 20

print(a[k])

a['x'] = a['x'] + 1
print(a['x'])

print('------------------------------')
b = a
print(b['x'])
b['x'] = 100
print(a['x'])

a = nil
b = nil		-- 解除对table的引用, 内存被回收

print('------------------------------')
a = {}
x = 'y'
a[x] = 10
print(a[x])
print(a.x)	-- 此处为nil
print(a.y)

print('-----------------------------\n')
a = {2, 4, 6, 8, 10}
for i = 1, #a do
	print(a[i])
end

print('-----------------------------\n')
a = {}
a[10000] = 1
print(#a)		-- 未初始化元素索引结果为nil，nil为数组结尾标志，当数组中含有nil时，长度操作符会认为此为数组结尾，所以输出为 0
print(table.maxn(a))	-- 返回一个table的最大正索引数

print('-----------------------------\n')
i = 10
j = '10'

a[i] = 'one value'
a[j] = 'another value'

print(a[i])
print(a[j])
print(a[tonumber(j)])
