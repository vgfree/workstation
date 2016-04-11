-- 迭代器函数,返回每个元素的值
print('---------------迭代器函数(while循环)------------------')
do
	function values (t)		-- values 是一个工厂,每次调用时都会创建一个新的closure,closure将它的状态保存在其外部变量t和i中
		local i = 0
		return function () 
			i = i + 1
			return t[i]
		end
	end

	t = {20, 30, 40}
	iter = values(t)		-- 创建迭代器
	while true do
		local element = iter()	-- 调用迭代器
		if element == nil then break end
		print(element)
	end
end

print('-------------------泛型for----------------------')
do
	t = {20, 30, 40}
	function values (t)
		local i = 0
		return function () 
			i = i + 1
			return t[i]
		end
	end

	for element in values(t) do	-- 泛型for内部保存了迭代器函数,每次迭代时调用迭代器
		print(element)
	end
end

print('-------------------allwords迭代器----------------------')
do
	function allwords(i)						
		local line = io.read()					-- 读入当前行
		local pos = 1						-- 当前行中位置
		return function ()					-- 迭代器函数
			while line do					-- 读入有效行则内容就进入循环
				local s, e = string.find(line, '%w+', pos)	-- 从当前行的开始部分开始匹配单词(一个或多个文字/数字字符)
				if s then				-- 是否找到一个单词(开头)
					pos = e + 1			-- 当前位置指向该单词的下一个位置
					return string.sub(line, s, e)	-- 返回该单词
				else
					line = io.read()		-- 没有找到单词,读入下一行(?连续两个空格后面的算现已行吗?此处不明白)
					pos = 1
				end
			end
			return nil
		end
	end

	for word in allwords() do
		print(word)
	end
end

