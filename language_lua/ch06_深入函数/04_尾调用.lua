print('----------------走迷宫状态机-------------------')

function room1 ()
	print('room1')
	local move = io.read()
	if move == 'south' then return room3()
	elseif move == 'east' then return room2()
	else
		print('invalid move')
		return room1()
	end
end

function room2 ()
	print('room2')
	local move = io.read()
	if move == 'south' then return room4()
	elseif move == 'west' then return room1()
	else
		print('invalid move')
		return room2()
	end
end

function room3 ()
	print('room3')
	local move = io.read()
	if move == 'north' then return room1()
	elseif move == 'east' then return room4()
	else
		print('invalid move')
		return room3()
	end
end

function room4 ()
	print('room4')
	local move = io.read()
	if move == 'north' then return room2()
	elseif move == 'west' then return room3()
	else
		print('invalid move')
		return room4()
	end
end

room1()
