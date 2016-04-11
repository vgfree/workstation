list = nil
for line in io.lines() do
	list = {next = list, value = line}
	while line == '1' do
		local l = list
		while l do
			print(l.value)
			l = l.next
		end
	end
	
end

-- 打印的时候会循环打印，不知道该怎么解决这个问题
