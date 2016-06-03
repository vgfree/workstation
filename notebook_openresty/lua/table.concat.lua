local my_list = {
	[1] = 'louis',
	'miku',
	'shana'}

local pieces = {}

for index, elem in ipairs(my_list) do
	pieces[index] = elem
	print(pieces[index])
end

local res = table.concat(pieces)

print(res)
