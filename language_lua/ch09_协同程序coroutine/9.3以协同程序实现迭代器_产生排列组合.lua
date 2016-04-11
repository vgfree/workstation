function permgen(a, n)
	n = n or #a
	if n <= 1 then
		printResult(a)
	else
		for i = 1, n do
			a[n], a[i] = a[i], a[n] -- 将第i个元素放到末尾
			print(a[i], a[n])
			permgen(a, n - 1)
			a[n], a[i] = a[i], a[n] -- 恢复第i个元素位置
		end
	end
end

function printResult (a)
	for i = 1, #a do
		io.write(a[i], " ")
	end
	io.write("\n")
end

permgen({1, 2}, 2)	-- 4 缺省时就会计算#a
