-- 传入一个描述循环体的函数

function allwords(f)
	for line in io.lines() do
		for word in string.gmatch(line, '%w+') do
			f(word)
		end
	end
end

allwords(print)

print('------------计算输入中hello的出现次数---------------')
local count = 0
allwords(function(w)
	if w == 'hello' then count = count + 1 end	
	print(count)					-- 运行时需要注释上面的第11行
end)

--print(count)
