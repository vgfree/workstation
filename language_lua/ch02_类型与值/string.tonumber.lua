line = io.read()
num = tonumber(line)

if num ~= nil then
	print(num * 2)
else
	error(line .. ' is not a valid number')
end
