local foo = {}

local function getname ()
	return 'Lucy'
end

function foo.Greeting ()
	print('hello ' .. getname())
end

return foo
