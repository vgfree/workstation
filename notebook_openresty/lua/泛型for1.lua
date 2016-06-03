-- iparis 遍历数组的迭代器函数
local a = {first = 'a', 'b', 'c', 'd'}
for i, v in ipairs(a) do
	print('index: ', i, ' value: ', v)
end

print('*************')
-- 遍历table中所有的key
for k, v in pairs(a) do
	print(k)
	print(v)
end
