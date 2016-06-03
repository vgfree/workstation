local a = {x = 1, y = 0}
local b = {x = 1, y = 0}

if a == b then
	print('a == b')
else
	print('a ~= b')
end

-- lua中的比较为引用比较,严格意义上来说,由于字符串总时被'内化',相同的字符串只
-- 保存一份,所以字符串的比较实际上是地址的比较,也因此,复杂度为O(1)
