do
co = coroutine.create(function () print('hi') end)	-- 创建协同程序

print(co)
print(coroutine.status(co))	-- 创建后并不会立即执行,而是处于挂起状态
coroutine.resume(co)		-- 启动协同程序的执行
print(coroutine.status(co))	-- 协同程序运行后处于dead状态
end

print('-------------------函数yield的使用-----------------------------------------------')
do
co = coroutine.create(function()
	for i = 1, 10 do
		print('co', i)
		coroutine.yield()
	end
end)

coroutine.resume(co)
print(coroutine.status(co))
coroutine.resume(co)
end

print('-------------------通过一对resume-yield交换数据--------------------------')
-- 此段内容不明白,有待回头再看,再写代码
co = coroutine.create(function (a, b, c)
	print('co', a, b, c)	
end)

coroutine.resume(co, 1, 2, 3)


