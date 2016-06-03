local function func( ... )
	local temp = { ... }
	local ans = table.concat(temp, ' ')
	print(ans)
end

func(1, 2)
func(1, 2, 3, 4)

