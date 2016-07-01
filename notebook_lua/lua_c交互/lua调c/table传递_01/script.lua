x = 0
for i = 1, #foo do
	print(i, foo[i])
	x = x + foo[i]
end
return x
