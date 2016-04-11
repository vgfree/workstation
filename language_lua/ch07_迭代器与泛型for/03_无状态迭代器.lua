-- 自身不保存任何状态的迭代器,因此可以在多个循环中使用同一个无状态的迭代器


print('-------------ipairs----------------')
a = {'one', 'two', 'three'}
for i, v in ipairs(a) do 		-- 恒定状态 table a , 当前索引值 控制变量
	print(i, v)
end


print('-------------pairs----------------')
a = {'one', 'two', 'three'}
for i, v in pairs(a) do
	print(i, v)
end


