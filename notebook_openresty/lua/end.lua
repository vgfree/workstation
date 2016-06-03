local function foo()
	print('before')
	-- 将end放在句中进行调试
	do return end

	print('after')
end

foo()
