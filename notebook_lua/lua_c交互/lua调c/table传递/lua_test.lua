function domain(i)
	-- c函数返回table
	local tab = gettab()

	for k, v in pairs(tab) do
		print("key: " .. k)
		print("val: " .. v)
		print()
	end
end
