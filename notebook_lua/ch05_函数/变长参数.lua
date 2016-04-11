function foo(a, b, ... )
	n = select('#', ... )
	print(n)
	--print( select(3, ... ) )	-- 此处很奇怪返回的是从第3个可变参数开始的参数
	local arg = select(1, ... )	-- 返回第一个可变参数
	print(arg)
end

foo(1, 2, 3, 4, nil, 5)
